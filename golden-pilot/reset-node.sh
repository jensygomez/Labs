#!/usr/bin/env bash
# reset-fleet.sh
#
# Resetea TODAS las VMs del laboratorio a su estado original (clean slate).
# Destruye dominios, borra overlays y seed ISOs, y recrea todo desde la
# imagen dorada usando make-node.sh.
#
# Uso: bash reset-fleet.sh
#
# Nota: No requiere argumentos. Las IPs y nombres están hardcodeados
# para coincidir con launch-pilot-fleet.sh.

set -o errexit
set -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> 🔄 Reseteando toda la flota a estado original (Clean Slate)..."
echo ""

# Definición de la flota (debe coincidir con launch-pilot-fleet.sh)
declare -A FLEET_IPS=(
    ["node01"]="192.168.122.11"
    ["node02"]="192.168.122.12"
    ["node03"]="192.168.122.13"
    ["node04"]="192.168.122.14"
)

declare -A FLEET_EXTRA=(
    ["node01"]=""
    ["node02"]=""
    ["node03"]=""
    ["node04"]="nfs-utils"
)

# Resetear cada nodo
for node in node01 node02 node03 node04; do
    ip="${FLEET_IPS[$node]}"
    extra="${FLEET_EXTRA[$node]}"
    
    echo "==> 🧹 Limpiando $node ($ip)..."
    
    # 1. Apagar y borrar el dominio de libvirt
    sudo virsh destroy "$node" 2>/dev/null || true
    sudo virsh undefine "$node" 2>/dev/null || true
    
    # 2. Borrar TODO el directorio del nodo (overlay + seed.iso + user-data)
    rm -rf "$HOME/vm-images/$node"
    echo "    [✓] Archivos locales y dominio eliminados."
    
    # 3. Recrear usando make-node.sh
    bash "$SCRIPT_DIR/make-node.sh" "$node" "$ip" "$extra"
    echo ""
done

echo "==> ✅ Toda la flota está 100% limpia y arrancando."
echo ""
echo "Cloud-init tarda ~60-90 segundos en aplicar la configuración."
echo "Probar con:"
echo "  ssh jensyg@192.168.122.11"
echo "  ssh jensyg@192.168.122.12"
echo "  ssh jensyg@192.168.122.13"
echo "  ssh jensyg@192.168.122.14"
