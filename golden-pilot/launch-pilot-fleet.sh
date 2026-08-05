#!/usr/bin/env bash
# launch-pilot-fleet.sh
#
# Levanta la red libvirt del laboratorio (si no existe) y las 4 VMs
# del piloto, usando make-node.sh para cada una.

set -o errexit
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# IMPORTANTE: si ya existe una red libvirt en 192.168.122.0/24 (por
# ejemplo "mgmt-net", creada antes por vagrant-libvirt), hay que
# REUSARLA en vez de crear una nueva -- dos redes libvirt no pueden
# compartir el mismo rango de subred. Correr `sudo virsh net-list --all`
# y ajustar esta variable con el nombre real antes de correr el script.
NETWORK_NAME="mgmt-net"

echo "==> Verificando red libvirt '${NETWORK_NAME}'..."
if ! sudo virsh net-list --all | grep -q "$NETWORK_NAME"; then
  echo "ERROR: la red '${NETWORK_NAME}' no existe."
  echo "Corre 'sudo virsh net-list --all' para ver que redes tenes,"
  echo "y ajusta la variable NETWORK_NAME en este script con el nombre real."
  exit 1
fi

echo "==> Red '${NETWORK_NAME}' encontrada. Asegurando que este activa..."
sudo virsh net-start "$NETWORK_NAME" 2>/dev/null || echo "    (ya estaba activa)"

echo "==> Levantando node01 (fleet)..."
bash "$SCRIPT_DIR/make-node.sh" node01 192.168.122.11

echo "==> Levantando node02 (fleet)..."
bash "$SCRIPT_DIR/make-node.sh" node02 192.168.122.12

echo "==> Levantando node03 (fleet)..."
bash "$SCRIPT_DIR/make-node.sh" node03 192.168.122.13

echo "==> Levantando node04 (storage)..."
bash "$SCRIPT_DIR/make-node.sh" node04 192.168.122.14 nfs-utils

echo ""
echo "==> Las 4 VMs estan arrancando. Cloud-init tarda ~30-60 segundos"
echo "    en aplicar la configuracion la PRIMERA vez que bootea cada una."
echo ""
echo "Probar con:"
echo "  ssh jensyg@192.168.122.11"
echo "  ssh jensyg@192.168.122.12"
echo "  ssh jensyg@192.168.122.13"
echo "  ssh jensyg@192.168.122.14"
