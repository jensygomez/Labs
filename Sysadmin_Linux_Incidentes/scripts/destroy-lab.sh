#!/bin/bash
set -e

CLOUDINIT_DIR="$HOME/Labs/Sysadmin_Linux_Incidentes/libvirt-cloudinit"
INV="$HOME/Labs/Sysadmin_Linux_Incidentes/ansible/inventory/hosts.ini"

VMS=("app-vm-1" "app-vm-2" "app-vm-3" "storage-vm" "aws-local-vm")
LXC_CONTAINER="cliente-lxc"

echo "=================================================="
echo "   DESTRUCCIÓN Y LIMPIEZA DE ENTORNO DE LAB"
echo "=================================================="

# 1. Destrucción de VMs en libvirt/KVM
echo "==> Destruyendo VMs KVM y eliminando almacenamiento..."
for VM in "${VMS[@]}"; do
  if sudo virsh dominfo "$VM" &>/dev/null; then
    echo "  --> Apagando y destruyendo VM: $VM"
    sudo virsh destroy "$VM" &>/dev/null || true
    sudo virsh undefine "$VM" --nvram &>/dev/null || true
  else
    echo "  --> VM '$VM' no encontrada en libvirt."
  fi

  # Limpieza de imágenes de disco asociadas
  echo "  --> Eliminando discos de $VM..."
  sudo rm -f /var/lib/libvirt/images/${VM}-*.qcow2

  # Limpieza de temporales cloud-init
  rm -rf "/tmp/${VM}-cloudinit"
done

# 2. Destrucción del contenedor LXC
echo "==> Destruyendo contenedor LXC..."
if lxc info "$LXC_CONTAINER" &>/dev/null; then
  echo "  --> Eliminando LXC: $LXC_CONTAINER"
  lxc delete "$LXC_CONTAINER" --force
else
  echo "  --> Contenedor '$LXC_CONTAINER' no encontrado."
fi

# 3. Limpieza de inventario Ansible
echo "==> Limpiando archivos de inventario..."
if [ -f "$INV" ]; then
  rm -f "$INV"
  echo "  --> Archivo $INV eliminado."
fi

# 4. Limpieza de reglas arp/ssh cache local si es necesario
echo "==> Limpiando lease/red de libvirt..."
sudo virsh net-dhcp-leases default --purge &>/dev/null || true

echo "=================================================="
echo "   ENTORNO COMPLETAMENTE LIMPIADO"
echo "=================================================="
