#!/usr/bin/env bash
set -euo pipefail

########################################
# Configuración
########################################
APP_VMS=(server01 server02 server03)
STORAGE_VMS=(storage01 storage02)
ALL_VMS=("${APP_VMS[@]}" "${STORAGE_VMS[@]}")

INVENTORY_DIR="${INVENTORY_DIR:-$HOME/Labs/Sysadmin_Linux_Incidentes/ansible/inventory}"
INVENTORY_FILE="${INVENTORY_DIR}/hosts.ini"

echo "=================================================="
echo "   DESTRUCCIÓN Y LIMPIEZA DE ENTORNO DE LAB"
echo "=================================================="

########################################
# Eliminación de VMs KVM
########################################
for VM in "${ALL_VMS[@]}"; do
  if sudo virsh dominfo "$VM" >/dev/null 2>&1; then
    echo "==> Apagando y eliminando VM: $VM"
    sudo virsh destroy "$VM" 2>/dev/null || true
    sudo virsh undefine "$VM" --nvram 2>/dev/null || sudo virsh undefine "$VM" 2>/dev/null || true
  else
    echo "==> La VM '$VM' no existe en libvirt."
  fi

  echo "==> Eliminando discos y archivos temporales de $VM"
  sudo rm -f "/var/lib/libvirt/images/${VM}"-*.qcow2
  sudo rm -f "/var/lib/libvirt/images/${VM}"-*.iso
  rm -rf "/tmp/${VM}-cloudinit"
done

########################################
# Limpieza de inventario Ansible
########################################
if [[ -f "$INVENTORY_FILE" ]]; then
  echo "==> Eliminando inventario Ansible: $INVENTORY_FILE"
  rm -f "$INVENTORY_FILE"
fi

########################################
# Limpieza de leases de red libvirt
########################################
echo "==> Limpiando leases de la red default de libvirt..."
sudo virsh net-dhcp-leases default --purge 2>/dev/null || true

echo "=================================================="
echo "   ENTORNO COMPLETAMENTE LIMPIADO"
echo "=================================================="
