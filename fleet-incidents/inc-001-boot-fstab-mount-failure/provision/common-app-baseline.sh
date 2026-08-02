#!/usr/bin/env bash
# common-app-baseline.sh
# Corre IGUAL en node01, node02 y node03. Ahora monta /data via NFS real
# desde node04, con un patron de espera/reintento — nunca asumimos que
# el storage ya esta listo, lo confirmamos activamente antes de montar.
# Esto es lo mismo que un depends_on + healthcheck de Docker Compose,
# o un readinessProbe de Kubernetes, aplicado a VMs con Bash puro.

set -o errexit
set -o pipefail

STORAGE_IP="192.168.122.14"
STORAGE_EXPORT="/srv/nfs/appdata"

if [ -f /etc/redhat-release ]; then
  OS_FAMILY="rhel"
else
  OS_FAMILY="debian"
fi

echo "==> Instalando cliente NFS (familia: ${OS_FAMILY})..."
if [ "$OS_FAMILY" = "rhel" ]; then
  dnf install -y nfs-utils
else
  apt-get update -y
  apt-get install -y nfs-common
fi

echo "==> Esperando a que node04 (${STORAGE_IP}) exporte NFS..."
MAX_RETRIES=30
RETRY=0
until showmount -e "$STORAGE_IP" 2>/dev/null | grep -q "$STORAGE_EXPORT"; do
  RETRY=$((RETRY + 1))
  if [ "$RETRY" -ge "$MAX_RETRIES" ]; then
    echo "FATAL: node04 no respondio NFS despues de ${MAX_RETRIES} intentos" >&2
    exit 1
  fi
  echo "    ...node04 todavia no responde, reintento ${RETRY}/${MAX_RETRIES}"
  sleep 5
done
echo "==> node04 confirmado, export disponible."

# --- Punto de montaje + fstab (esta es la version CORRECTA, sana) ---
mkdir -p /data
if ! grep -q "/data" /etc/fstab; then
  echo "${STORAGE_IP}:${STORAGE_EXPORT} /data nfs defaults,_netdev,x-systemd.automount,x-systemd.mount-timeout=15 0 0" >> /etc/fstab
fi

mount -a

echo "==> Baseline: creando app-backend.service..."

cat > /etc/systemd/system/app-backend.service << 'UNIT_EOF'
[Unit]
Description=Critical App Backend
RequiresMountsFor=/data
After=remote-fs.target network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/bin/bash -c 'if [ -f "/data/status" ]; then echo "[$(date)] App started successfully" >> /data/status; sleep infinity; else echo "FATAL: /data/status not found" >&2; exit 1; fi'
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT_EOF

echo "==> Baseline: creando legacy-daemon.service (false negative preexistente)..."

mkdir -p /opt/legacy
cat > /opt/legacy/start.sh << 'LEGACY_EOF'
#!/bin/bash
echo "legacy-daemon: simulando fallo conocido..."
exit 1
LEGACY_EOF
chmod +x /opt/legacy/start.sh

cat > /etc/systemd/system/legacy-daemon.service << 'UNIT_EOF'
[Unit]
Description=Legacy Monitoring Daemon (known issue OPS-891)

[Service]
Type=simple
ExecStart=/opt/legacy/start.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
UNIT_EOF

systemctl daemon-reload
systemctl enable --now legacy-daemon.service || true
systemctl enable --now app-backend.service || true

echo "==> Baseline completo en $(hostname)."
