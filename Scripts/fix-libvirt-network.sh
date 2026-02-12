#!/usr/bin/env bash
set -Eeuo pipefail

echo "==> Fix libvirt + KVM (CachyOS / Arch)"

# -------------------------------------------------
# 1. Comprobación básica de KVM
# -------------------------------------------------
echo "==> Verificando KVM..."
if ! lsmod | grep -q '^kvm'; then
  echo "❌ KVM no está cargado (revisa BIOS / módulos)"
  exit 1
fi
echo "✔ KVM activo"

# -------------------------------------------------
# 2. Activar sockets libvirt (compute, network, storage)
# -------------------------------------------------
echo "==> Activando sockets libvirt..."
systemctl enable --now \
  virtqemud.socket \
  virtnetworkd.socket \
  virtstoraged.socket

sleep 1

# Verificar sockets críticos
for sock in virtqemud-sock virtnetworkd-sock virtstoraged-sock; do
  if [[ ! -S /run/libvirt/$sock ]]; then
    echo "❌ Socket /run/libvirt/$sock no disponible"
    exit 1
  fi
done

echo "✔ Sockets libvirt activos (compute, network, storage)"

# -------------------------------------------------
# 3. Normalizar red libvirt
# -------------------------------------------------
echo "==> Verificando redes libvirt..."

# Eliminar red mal llamada "network" (bug común)
if virsh -c qemu:///system net-list --all | awk '{print $1}' | grep -qx network; then
  echo "⚠ Eliminando red incorrecta 'network'"
  virsh -c qemu:///system net-destroy network || true
  virsh -c qemu:///system net-undefine network || true
fi

# Definir red default si no existe
if ! virsh -c qemu:///system net-list --all | awk '{print $1}' | grep -qx default; then
  echo "==> Definiendo red 'default'"
  virsh -c qemu:///system net-define /usr/share/libvirt/networks/default.xml
fi

# Arrancar y persistir default
echo "==> Activando red 'default'"
virsh -c qemu:///system net-start default || true
virsh -c qemu:///system net-autostart default

# -------------------------------------------------
# 4. Estado final
# -------------------------------------------------
echo
echo "==> Redes libvirt:"
virsh -c qemu:///system net-list --all

echo
echo "==> Bridge virbr0:"
ip addr show virbr0 || echo "⚠ virbr0 se activará al arrancar una VM"

echo
echo "✔ Host completamente listo para virt-manager"
