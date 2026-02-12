#!/usr/bin/env bash
set -Eeuo pipefail

echo "==> Fix libvirt + KVM networking (Arch/CachyOS)"

# -------------------------------
# 1. Comprobación básica de KVM
# -------------------------------
if ! lsmod | grep -q kvm; then
  echo "❌ KVM no está cargado"
  exit 1
fi
echo "✔ KVM activo"

# -------------------------------
# 2. Arrancar sockets libvirt
# -------------------------------
echo "==> Activando sockets libvirt..."
systemctl enable --now virtqemud.socket virtnetworkd.socket

# Esperar a que los sockets existan
sleep 1

if [[ ! -S /run/libvirt/virtqemud-sock ]]; then
  echo "❌ virtqemud-sock no existe"
  exit 1
fi

echo "✔ Sockets libvirt activos"

# -------------------------------
# 3. Normalizar red libvirt
# -------------------------------
echo "==> Verificando redes libvirt..."

# Si existe una red llamada "network", eliminarla
if virsh -c qemu:///system net-list --all | awk '{print $1}' | grep -qx network; then
  echo "⚠ Eliminando red antigua 'network'"
  virsh -c qemu:///system net-destroy network || true
  virsh -c qemu:///system net-undefine network || true
fi

# Definir red default si no existe
if ! virsh -c qemu:///system net-list --all | awk '{print $1}' | grep -qx default; then
  echo "==> Definiendo red 'default'"
  virsh -c qemu:///system net-define /usr/share/libvirt/networks/default.xml
fi

# Arrancar y habilitar default
echo "==> Activando red 'default'"
virsh -c qemu:///system net-start default || true
virsh -c qemu:///system net-autostart default

# -------------------------------
# 4. Estado final
# -------------------------------
echo
echo "==> Estado final de libvirt:"
virsh -c qemu:///system net-list --all

echo
echo "==> Bridge virbr0:"
ip addr show virbr0 || echo "⚠ virbr0 aún no activo (se levanta cuando una VM arranca)"

echo
echo "✔ Host listo para virt-manager"
