#!/usr/bin/env bash
set -euo pipefail

########################################
# Configuración
########################################
INVENTORY_DIR="${INVENTORY_DIR:-$HOME/Labs/SYSTECH-HA-001—Enterprise_Linux_HA_Infrastructure/inventories/production}"
INVENTORY_FILE="${INVENTORY_DIR}/hosts.yml"

# Pasar --force (o FORCE=1) para saltar la confirmación interactiva
FORCE="${FORCE:-0}"
[[ "${1:-}" == "--force" ]] && FORCE=1

echo "=================================================="
echo "   DESTRUCCIÓN Y LIMPIEZA DINÁMICA DEL LAB"
echo "=================================================="

########################################
# 1. Detectar TODO lo que existe (VMs + LXC)
########################################
echo ""
echo "==> Detectando VMs libvirt..."
mapfile -t ALL_VMS < <(sudo virsh list --all --name | sed '/^$/d')

echo "==> Detectando contenedores LXC..."
mapfile -t ALL_LXC < <(lxc list --format csv -c n 2>/dev/null | sed '/^$/d')

if [[ ${#ALL_VMS[@]} -eq 0 && ${#ALL_LXC[@]} -eq 0 ]]; then
  echo ""
  echo "==> No se encontraron VMs ni contenedores. Nada que limpiar."
  exit 0
fi

########################################
# 2. Mostrar qué se va a eliminar y confirmar
########################################
echo ""
echo "Se van a ELIMINAR los siguientes recursos:"
echo ""
if [[ ${#ALL_VMS[@]} -gt 0 ]]; then
  echo "  VMs (libvirt):"
  printf '    - %s\n' "${ALL_VMS[@]}"
else
  echo "  VMs (libvirt): ninguna"
fi

if [[ ${#ALL_LXC[@]} -gt 0 ]]; then
  echo "  Contenedores (LXC):"
  printf '    - %s\n' "${ALL_LXC[@]}"
else
  echo "  Contenedores (LXC): ninguno"
fi
echo ""

if [[ "$FORCE" -ne 1 ]]; then
  read -r -p "¿Confirmás la eliminación de TODO lo listado arriba? (escribí 'si' para continuar): " CONFIRM
  if [[ "$CONFIRM" != "si" ]]; then
    echo "==> Cancelado. No se eliminó nada."
    exit 1
  fi
fi

########################################
# 3. Eliminar VMs KVM
########################################
if [[ ${#ALL_VMS[@]} -gt 0 ]]; then
  echo ""
  for VM in "${ALL_VMS[@]}"; do
    echo "==> Apagando y eliminando VM: $VM"
    sudo virsh destroy "$VM" 2>/dev/null || true
    sudo virsh undefine "$VM" --nvram 2>/dev/null || sudo virsh undefine "$VM" 2>/dev/null || true

    echo "==> Eliminando discos y archivos temporales de $VM"
    sudo rm -f "/var/lib/libvirt/images/${VM}"-*.qcow2
    sudo rm -f "/var/lib/libvirt/images/${VM}"-*.iso
    rm -rf "/tmp/${VM}-cloudinit"
  done
fi

########################################
# 4. Eliminar contenedores LXC
########################################
if [[ ${#ALL_LXC[@]} -gt 0 ]]; then
  echo ""
  for CT in "${ALL_LXC[@]}"; do
    echo "==> Eliminando contenedor LXC: $CT"
    lxc delete "$CT" --force 2>/dev/null || true
  done
fi

########################################
# 5. Limpieza de inventario Ansible
########################################
if [[ -f "$INVENTORY_FILE" ]]; then
  echo ""
  echo "==> Eliminando inventario Ansible: $INVENTORY_FILE"
  rm -f "$INVENTORY_FILE"
fi

########################################
# 6. Limpieza de leases de red libvirt
########################################
echo ""
echo "==> Limpiando leases de la red default de libvirt..."
sudo virsh net-dhcp-leases default --purge 2>/dev/null || true

echo ""
echo "=================================================="
echo "   ENTORNO COMPLETAMENTE LIMPIADO"
echo "=================================================="
