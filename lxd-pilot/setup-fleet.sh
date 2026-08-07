#!/bin/bash
# fix-all.sh - Crea usuario, inyecta clave SSH, y limpia known_hosts

SSH_KEY=$(cat ~/.ssh/id_lab_pilot.pub)

echo "🧹 Limpiando known_hosts de la laptop..."
for i in {1..8}; do
    IP="10.77.77.$((i + 10))"
    ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$IP" 2>/dev/null
done

echo ""
echo "🚀 Configurando usuario y SSH en toda la flota..."
echo "======================================"

for i in {1..8}; do
    NAME=$(printf "server%02d" $i)
    echo ""
    echo "📦 [$NAME] Configurando..."
    
    # 1. Crear usuario labadmin si no existe
    echo "   → Creando usuario labadmin..."
    lxc exec $NAME -- bash -c "id -u labadmin &>/dev/null || useradd -m -s /bin/bash labadmin"
    lxc exec $NAME -- bash -c "echo 'labadmin ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/labadmin"
    
    # 2. Inyectar clave SSH
    echo "   → Inyectando clave SSH..."
    lxc exec $NAME -- bash -c "mkdir -p /home/labadmin/.ssh"
    lxc exec $NAME -- bash -c "echo '$SSH_KEY' > /home/labadmin/.ssh/authorized_keys"
    lxc exec $NAME -- bash -c "chmod 700 /home/labadmin/.ssh"
    lxc exec $NAME -- bash -c "chmod 600 /home/labadmin/.ssh/authorized_keys"
    lxc exec $NAME -- bash -c "chown -R labadmin:labadmin /home/labadmin/.ssh"
    
    echo "   ✅ $NAME listo"
done

echo ""
echo "======================================"
echo "✅ Configuración completa. Probando SSH..."
echo ""

# Prueba de SSH
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 labadmin@10.77.77.11 "echo '🎉 SSH FUNCIONA! Hostname: \$(hostname)'"
