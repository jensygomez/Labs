#!/bin/bash
# ============================================================================
# SCRIPT 2: NETWORK NAMESPACES CON PERSISTENCIA
# ============================================================================
set -e

echo "=== 🌐 SCRIPT 2: RED CON PERSISTENCIA ==="
echo "📅 Fecha: $(date)"
echo "=========================================="

if [[ $EUID -ne 0 ]]; then 
    echo "❌ Ejecutar como root: sudo $0"
    exit 1
fi

if ! id "student" &>/dev/null; then
    echo "❌ Ejecuta primero script1-base.sh"
    exit 1
fi

# ---------------------------------------------------------------------------
# 1. MEJORAR SCRIPT DE RED PARA SER IDEMPOTENTE
# ---------------------------------------------------------------------------
echo "[1/5] 🔧 Creando script de red IDEMPOTENTE..."

cat > /usr/local/bin/lab-net-setup.sh << 'EOF'
#!/bin/bash
# Lab 3-Tier Network Setup - IDEMPOTENTE

set -e

echo "🔧 Configurando network namespaces (IDEMPOTENTE)..."

# Variables
IP_CLIENT="10.10.50.10"
IP_SERVICES="10.10.100.10"
IP_EDGE_LAN="10.10.50.1"
IP_EDGE_WAN="10.10.100.1"

# Función para verificar y crear namespace
create_ns_if_not_exists() {
    local ns=$1
    if ! ip netns list | grep -q "$ns"; then
        echo "   📦 Creando namespace $ns..."
        ip netns add "$ns"
    else
        echo "   ℹ️  Namespace $ns ya existe"
    fi
}

# Función para configurar interfaz
setup_interface() {
    local ns=$1
    local iface=$2
    local ip=$3
    
    # Verificar si la interfaz ya tiene la IP
    if ip netns exec "$ns" ip addr show "$iface" 2>/dev/null | grep -q "$ip"; then
        echo "   ℹ️  Interfaz $iface en $ns ya tiene IP $ip"
        return 0
    fi
    
    # Configurar IP
    echo "   ⚙️  Configurando $iface con $ip en $ns..."
    ip netns exec "$ns" ip addr add "$ip/24" dev "$iface" 2>/dev/null || true
    ip netns exec "$ns" ip link set "$iface" up
    ip netns exec "$ns" ip link set lo up
}

# Limpiar solo interfaces veth residuales (NO namespaces)
echo "   🧹 Limpiando interfaces residuales..."
ip link delete veth-client 2>/dev/null || true
ip link delete veth-srv 2>/dev/null || true
sleep 1

# 1. CREAR NAMESPACES (si no existen)
create_ns_if_not_exists "NS-CLIENT"
create_ns_if_not_exists "NS-EDGE"
create_ns_if_not_exists "NS-SERVICES"

# 2. CREAR INTERFACES VETH (si no existen)
echo "   🔗 Creando/conectando interfaces..."

# CLIENT <-> EDGE
if ! ip link show veth-client 2>/dev/null; then
    echo "   🔗 Conectando CLIENT <-> EDGE..."
    ip link add veth-client type veth peer name veth-edge-cli
    ip link set veth-client netns NS-CLIENT
    ip link set veth-edge-cli netns NS-EDGE
fi

# EDGE <-> SERVICES
if ! ip link show veth-srv 2>/dev/null; then
    echo "   🔗 Conectando EDGE <-> SERVICES..."
    ip link add veth-srv type veth peer name veth-edge-srv
    ip link set veth-srv netns NS-SERVICES
    ip link set veth-edge-srv netns NS-EDGE
fi

# 3. CONFIGURAR IPs
setup_interface "NS-CLIENT" "veth-client" "$IP_CLIENT"
setup_interface "NS-EDGE" "veth-edge-cli" "$IP_EDGE_LAN"
setup_interface "NS-EDGE" "veth-edge-srv" "$IP_EDGE_WAN"
setup_interface "NS-SERVICES" "veth-srv" "$IP_SERVICES"

# 4. CONFIGURAR ROUTING (idempotente)
echo "   🛣️  Configurando rutas..."
ip netns exec NS-CLIENT ip route add default via $IP_EDGE_LAN 2>/dev/null || true
ip netns exec NS-SERVICES ip route add default via $IP_EDGE_WAN 2>/dev/null || true

# 5. HABILITAR FORWARDING
echo "   🔄 Habilitando IP forwarding..."
ip netns exec NS-EDGE sysctl -w net.ipv4.ip_forward=1 >/dev/null

# 6. CONFIGURAR FIREWALL (limpia y recrea)
echo "   🛡️  Configurando firewall..."
ip netns exec NS-EDGE iptables -F
ip netns exec NS-EDGE iptables -t nat -F
ip netns exec NS-EDGE iptables -X

ip netns exec NS-EDGE iptables -P FORWARD DROP
ip netns exec NS-EDGE iptables -A FORWARD -i veth-edge-cli -o veth-edge-srv -j ACCEPT
ip netns exec NS-EDGE iptables -A FORWARD -i veth-edge-srv -o veth-edge-cli -m state --state ESTABLISHED,RELATED -j ACCEPT
ip netns exec NS-EDGE iptables -A FORWARD -p icmp -j ACCEPT
ip netns exec NS-EDGE iptables -t nat -A POSTROUTING -o veth-edge-srv -j MASQUERADE

echo ""
echo "✅ RED CONFIGURADA (IDEMPOTENTE)"
echo ""
echo "📊 RESUMEN:"
ip netns list
EOF

chmod +x /usr/local/bin/lab-net-setup.sh
echo "   ✅ Script de red IDEMPOTENTE creado"

# ---------------------------------------------------------------------------
# 2. CREAR SERVICIO SYSTEMD PARA PERSISTENCIA
# ---------------------------------------------------------------------------
echo "[2/5] 🚀 Creando servicio systemd para persistencia..."

cat > /etc/systemd/system/lab-network.service << 'EOF'
[Unit]
Description=Lab 3-Tier Network Namespaces
After=network.target
Wants=network.target
Before=sshd.service

[Service]
Type=oneshot
RemainAfterExit=yes

# Ejecutar nuestro script de red (es idempotente, seguro ejecutar múltiples veces)
ExecStart=/usr/local/bin/lab-net-setup.sh
# Pequeña pausa para estabilización
ExecStartPost=/bin/sleep 2

# No limpiar al detener - queremos que sobrevivan mientras el sistema esté up
# ExecStop=/usr/bin/ip netns delete NS-CLIENT NS-EDGE NS-SERVICES 2>/dev/null || true

# Si falla, reintentar rápidamente
Restart=on-failure
RestartSec=5
TimeoutStartSec=30

[Install]
WantedBy=multi-user.target
EOF

# ---------------------------------------------------------------------------
# 3. CREAR TIMER PARA VERIFICACIÓN PERIÓDICA
# ---------------------------------------------------------------------------
echo "[3/5] ⏰ Creando timer de verificación..."

cat > /etc/systemd/system/lab-network-check.service << 'EOF'
[Unit]
Description=Lab Network Health Check
After=lab-network.service
Requires=lab-network.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'if ! ip netns list | grep -q "NS-CLIENT"; then echo "⚠️  Namespaces perdidos, recreando..." && /usr/local/bin/lab-net-setup.sh; fi'
EOF

cat > /etc/systemd/system/lab-network-check.timer << 'EOF'
[Unit]
Description=Verificar lab network cada 5 minutos
Requires=lab-network.service

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
Persistent=true

[Install]
WantedBy=timers.target
EOF

# ---------------------------------------------------------------------------
# 4. HABILITAR Y ACTIVAR SERVICIOS
# ---------------------------------------------------------------------------
echo "[4/5] ⚙️  Activando servicios..."

systemctl daemon-reload
systemctl enable lab-network.service
systemctl enable lab-network-check.timer

# Iniciar ahora
systemctl start lab-network.service
systemctl start lab-network-check.timer

echo "   ✅ Servicios habilitados y activados"

# ---------------------------------------------------------------------------
# 5. CREAR SCRIPT DE RECUPERACIÓN MANUAL
# ---------------------------------------------------------------------------
echo "[5/5] 🛠️  Creando herramientas de recuperación..."

# Script para recrear manualmente
cat > /usr/local/bin/lab-network-restart << 'EOF'
#!/bin/bash
echo "🔄 Reiniciando red del lab..."
systemctl restart lab-network.service
sleep 3
echo "📊 Estado:"
ip netns list
echo ""
echo "🔗 Conectividad:"
ip netns exec NS-CLIENT ping -c 2 10.10.100.10 2>/dev/null && echo "✅ CLIENT -> SERVICES: OK" || echo "❌ CLIENT -> SERVICES: FALLÓ"
EOF
chmod +x /usr/local/bin/lab-network-restart

# Script para ver estado
cat > /usr/local/bin/lab-network-status << 'EOF'
#!/bin/bash
echo "=== 🌐 ESTADO DE RED DEL LAB ==="
echo "📅 Fecha: $(date)"
echo ""
echo "🏷️  NAMESPACES:"
ip netns list
echo ""
echo "🔗 CONECTIVIDAD:"
if ip netns exec NS-CLIENT ping -c 1 -W 1 10.10.100.10 >/dev/null 2>&1; then
    echo "✅ CLIENT -> SERVICES: CONECTADO"
else
    echo "❌ CLIENT -> SERVICES: SIN CONEXIÓN"
fi
echo ""
echo "⚙️  SERVICIO SYSTEMD:"
systemctl status lab-network.service --no-pager | head -10
EOF
chmod +x /usr/local/bin/lab-network-status

# Aliases mejorados
cat > /etc/profile.d/lab-namespaces.sh << 'EOF'
# Aliases y funciones para Lab 3-Tier
alias ns-client='ip netns exec NS-CLIENT bash'
alias ns-edge='ip netns exec NS-EDGE bash'
alias ns-services='ip netns exec NS-SERVICES bash'
alias lab-net-status='lab-network-status'
alias lab-net-restart='lab-network-restart'
alias lab-net-check='systemctl status lab-network.service'

# Función para entrar en namespace con entorno limpio
lab-ns() {
    case "$1" in
        client)
            ip netns exec NS-CLIENT bash --rcfile <(echo "PS1='[NS-CLIENT] \\u@\\h:\\w\\$ '")
            ;;
        edge)
            ip netns exec NS-EDGE bash --rcfile <(echo "PS1='[NS-EDGE] \\u@\\h:\\w\\$ '")
            ;;
        services)
            ip netns exec NS-SERVICES bash --rcfile <(echo "PS1='[NS-SERVICES] \\u@\\h:\\w\\$ '")
            ;;
        *)
            echo "Uso: lab-ns {client|edge|services}"
            echo ""
            echo "Namespaces disponibles:"
            ip netns list
            ;;
    esac
}
EOF

echo "   ✅ Herramientas creadas"

# ---------------------------------------------------------------------------
# VERIFICACIÓN FINAL
# ---------------------------------------------------------------------------
echo ""
echo "🔍 VERIFICACIÓN FINAL:"
echo "   1. Namespaces:"
ip netns list
echo ""
echo "   2. Servicio systemd:"
systemctl is-active lab-network.service && echo "   ✅ lab-network.service: ACTIVO" || echo "   ❌ lab-network.service: INACTIVO"
echo ""
echo "   3. Timer:"
systemctl is-active lab-network-check.timer && echo "   ✅ lab-network-check.timer: ACTIVO" || echo "   ❌ lab-network-check.timer: INACTIVO"
echo ""
echo "   4. Conectividad:"
if ip netns exec NS-CLIENT ping -c 2 -W 1 10.10.100.10 >/dev/null; then
    echo "   ✅ CLIENT -> SERVICES: CONECTADO"
else
    echo "   ⚠️  CLIENT -> SERVICES: VERIFICAR MANUALMENTE"
fi

# ---------------------------------------------------------------------------
# RESUMEN
# ---------------------------------------------------------------------------
echo ""
echo "=========================================="
echo "✅ SCRIPT 2 CON PERSISTENCIA COMPLETADO"
echo "=========================================="
echo ""
echo "🎯 PERSISTENCIA GARANTIZADA:"
echo "   • Servicio systemd: Se ejecuta AL ARRANQUE"
echo "   • Timer: Verifica cada 5 minutos y repara si es necesario"
echo "   • Script idempotente: Puede ejecutarse múltiples veces sin error"
echo ""
echo "🔧 HERRAMIENTAS:"
echo "   • lab-network-status    - Ver estado completo"
echo "   • lab-network-restart   - Reiniciar red manualmente"
echo "   • lab-ns {client|edge|services} - Entrar a namespaces"
echo "   • ns-client, ns-edge, ns-services (aliases tradicionales)"
echo ""
echo "🚀 PRUEBA DE PERSISTENCIA:"
echo "   1. Reiniciar: systemctl reboot"
echo "   2. Esperar 60 segundos"
echo "   3. Conectar: ssh student@IP_DE_LA_VM"
echo "   4. Verificar: sudo lab-network-status"
echo "   5. Los namespaces DEBEN existir"
echo ""
echo "📊 SERVICIOS CREADOS:"
echo "   • lab-network.service (arranque)"
echo "   • lab-network-check.timer (verificación cada 5min)"
echo "=========================================="