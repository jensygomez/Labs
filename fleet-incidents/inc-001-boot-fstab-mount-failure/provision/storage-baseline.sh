#!/usr/bin/env bash
# storage-baseline.sh — node04
# Rol REAL: exporta /srv/nfs/appdata via NFS para que la flota monte /data
# desde aca. Detecta familia de OS porque node04 puede tocarle AlmaLinux
# o Ubuntu segun el sorteo random del Vagrantfile.

set -o errexit
set -o pipefail

echo "==> node04: configurando storage NFS real..."

if [ -f /etc/redhat-release ]; then
  OS_FAMILY="rhel"
else
  OS_FAMILY="debian"
fi

echo "==> Familia de OS detectada: ${OS_FAMILY}"

if [ "$OS_FAMILY" = "rhel" ]; then
  dnf install -y nfs-utils
  SERVICE_NAME="nfs-server"
else
  apt-get update -y
  apt-get install -y nfs-kernel-server
  SERVICE_NAME="nfs-kernel-server"
fi

# --- Crear el directorio compartido y los datos "reales" de la app ---
mkdir -p /srv/nfs/appdata
cat > /srv/nfs/appdata/status << STATUS_EOF
APP_VERSION=2.4.1
LAST_SUCCESSFUL_DEPLOY=2024-01-15T14:30:00Z
DB_CONNECTION_POOL=active
CACHE_SIZE=512MB
STATUS_EOF
chown -R nobody:nogroup /srv/nfs/appdata 2>/dev/null || chown -R nobody:nobody /srv/nfs/appdata
chmod -R 777 /srv/nfs/appdata

# --- Export NFS: toda la flota (mgmt-net 192.168.122.0/24) puede montar ---
echo "/srv/nfs/appdata 192.168.122.0/24(rw,sync,no_subtree_check,no_root_squash)" > /etc/exports

if [ "$OS_FAMILY" = "rhel" ]; then
  systemctl enable --now rpcbind
fi

exportfs -ra
systemctl enable --now "$SERVICE_NAME"

# --- Firewall: abrir NFS solo si firewalld/ufw esta activo ---
if command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active --quiet firewalld; then
  firewall-cmd --permanent --add-service=nfs
  firewall-cmd --permanent --add-service=rpc-bind
  firewall-cmd --permanent --add-service=mountd
  firewall-cmd --reload
fi
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
  ufw allow from 192.168.122.0/24 to any port nfs
fi

echo "==> node04: NFS export listo en /srv/nfs/appdata"
exportfs -v
