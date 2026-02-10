#!/bin/bash
# Instalador de Ansible para Arch Linux / CachyOS

set -e

echo "========================================"
echo "  INSTALADOR ANSIBLE PARA ARCH/CACHYOS  "
echo "========================================"

# Verificar si somos root
if [[ $EUID -ne 0 ]]; then
   echo "Ejecuta con sudo o como root"
   exit 1
fi

# Actualizar sistema
echo "🔄 Actualizando sistema..."
pacman -Syu --noconfirm

# Instalar dependencias
echo "📦 Instalando Ansible y dependencias..."
pacman -Sy --noconfirm \
    ansible \
    sshpass \
    python-pip \
    git \
    base-devel

# Verificar instalación
echo "🔍 Verificando instalación..."
ansible --version
python3 --version
pip3 --version

echo ""
echo "✅ Ansible instalado correctamente en Arch/CachyOS"
echo ""
echo "Para configurar una VM Rocky 9.7:"
echo "   cd ansible-corpnet-v2"
echo "   ./setup-vm.sh -i 192.168.122.100 -p tu_password"