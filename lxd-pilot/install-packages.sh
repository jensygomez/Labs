#!/bin/bash
# install-packages.sh - Instala paquetes básicos

echo "=========================================="
echo "📦 Instalando paquetes base en la flota"
echo "=========================================="

for i in $(seq 1 10); do
  NODE=$(printf "server%02d" $i)
  
  echo ""
  echo "=== Instalando paquetes en $NODE ==="
  
  # Instalar paquetes básicos
  lxc exec $NODE -- dnf install -y epel-release 2>/dev/null || true
  lxc exec $NODE -- dnf install -y \
    openssh-server python3 e2fsprogs \
    vim wget curl bash-completion htop tmux \
    net-tools bind-utils firewalld audit chrony \
    python3-pip python3-libselinux tcpdump strace \
    lsof rsync unzip 2>/dev/null || true

  # Configurar SSH
  lxc exec $NODE -- systemctl enable --now sshd
  lxc exec $NODE -- sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
  lxc exec $NODE -- sed -i 's/PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config
  lxc exec $NODE -- systemctl restart sshd

  # Configurar servicios
  lxc exec $NODE -- setenforce 0 2>/dev/null || true
  lxc exec $NODE -- sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config 2>/dev/null || true
  lxc exec $NODE -- systemctl enable --now firewalld 2>/dev/null || true
  lxc exec $NODE -- systemctl enable --now chronyd 2>/dev/null || true
  lxc exec $NODE -- systemctl enable --now auditd 2>/dev/null || true

  # Instalar clave pública (si existe)
  if [ -f ~/.ssh/id_lxd_fleet.pub ]; then
    SSH_KEY=$(cat ~/.ssh/id_lxd_fleet.pub)
    lxc exec $NODE -- bash -c "mkdir -p /root/.ssh"
    lxc exec $NODE -- bash -c "echo '$SSH_KEY' > /root/.ssh/authorized_keys"
    lxc exec $NODE -- bash -c "chmod 700 /root/.ssh"
    lxc exec $NODE -- bash -c "chmod 600 /root/.ssh/authorized_keys"
  fi

  echo "   ✅ $NODE listo"
done

echo ""
echo "✅ Paquetes instalados correctamente"

