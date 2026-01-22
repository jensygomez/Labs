#!/bin/bash
# ============================================================================
# PROYECTO: Automatización de Golden Base Image (Rocky Linux)
# SCRIPT:   2 de 5 - Infraestructura de Red Centralizada (Modo Bridge)
# ============================================================================
#
# RESUMEN SCRIPT 1 (CIMENTACIÓN):
#   ✅ Sistema actualizado y herramientas de diagnóstico instaladas.
#   ✅ Usuario 'student' configurado y servicios base descargados.
#
# OBJETIVO SCRIPT 2 (EVOLUCIONADO):
#   Establecer un Switch Virtual (Bridge) como columna vertebral del Lab.
#   Esta arquitectura de "Estrella" permite que el Host, los Servicios y 
#   el Cliente coexistan en un mismo dominio de colisión controlado.
#
# MECANISMOS DE INGENIERÍA IMPLEMENTADOS:
# 1. TOPOLOGÍA HUB-AND-SPOKE: Uso de 'br-lab' como centro de conmutación,
#    eliminando la latencia de saltos intermedios y namespaces de paso.
# 2. INTEROPERABILIDAD CON EL HOST: El Bridge actúa como Gateway (10.10.100.1),
#    permitiendo que los servicios aislados consuman la base de datos MariaDB
#    que reside en el Host (VM raíz) de forma nativa.
# 3. PERSISTENCIA POR SYSTEMD: Implementación de servicio 'oneshot' que 
#    reconstruye el cableado virtual en cada arranque, garantizando que
#    los Scripts 3 y 4 encuentren siempre sus interfaces listas.
#
# PRÓXIMO PASO (SCRIPT 3):
#   Desplegar la configuración de Nginx y Dnsmasq para que escuchen en 
#   los puntos de red (Veth) anclados a este nuevo Bridge.
# ============================================================================


set -e

echo "=== 🌐 SCRIPT 2: RED CENTRALIZADA (BRIDGE MODE) ==="
echo "📅 Fecha: $(date)"

# [1/5] Creación del Script de Configuración Real
cat > /usr/local/bin/lab-net-setup.sh << 'EOF'
#!/bin/bash
set -e

# --- CONFIGURACIÓN ---
BR_NAME="br-lab"
BR_IP="10.10.100.1/24"

# --- LIMPIEZA IDEMPOTENTE ---
echo "🧹 Limpiando configuración previa..."
ip link delete $BR_NAME 2>/dev/null || true
for ns in NS-CLIENT NS-SERVICES; do
    ip netns delete $ns 2>/dev/null || true
done

# --- 1. CREAR EL BRIDGE (EL SWITCH VIRTUAL) ---
echo "🌉 Creando Bridge $BR_NAME ($BR_IP)..."
ip link add name $BR_NAME type bridge
ip addr add $BR_IP dev $BR_NAME
ip link set $BR_NAME up

# --- 2. CONFIGURAR NS-SERVICES (Servidor) ---
echo "🏗️  Configurando NS-SERVICES..."
ip netns add NS-SERVICES
ip link add veth-srv type veth peer name veth-srv-br
ip link set veth-srv netns NS-SERVICES
ip link set veth-srv-br master $BR_NAME  # Enchufar al Bridge
ip link set veth-srv-br up
ip netns exec NS-SERVICES ip addr add 10.10.100.10/24 dev veth-srv
ip netns exec NS-SERVICES ip link set veth-srv up
ip netns exec NS-SERVICES ip link set lo up
ip netns exec NS-SERVICES ip route add default via 10.10.100.1

# --- 3. CONFIGURAR NS-CLIENT (Cliente) ---
echo "🏗️  Configurando NS-CLIENT..."
ip netns add NS-CLIENT
ip link add veth-cli type veth peer name veth-cli-br
ip link set veth-cli netns NS-CLIENT
ip link set veth-cli-br master $BR_NAME  # Enchufar al Bridge
ip link set veth-cli-br up
ip netns exec NS-CLIENT ip addr add 10.10.100.20/24 dev veth-cli
ip netns exec NS-CLIENT ip link set veth-cli up
ip netns exec NS-CLIENT ip link set lo up
ip netns exec NS-CLIENT ip route add default via 10.10.100.1

echo "✅ Red en modo Bridge configurada correctamente."
EOF

chmod +x /usr/local/bin/lab-net-setup.sh

# [2/5] Creación del Servicio Systemd (Persistencia)
cat > /etc/systemd/system/lab-network.service << 'EOF'
[Unit]
Description=Lab Bridge Network Persistence
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/lab-net-setup.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# [3/5] Herramientas de diagnóstico (Actualizadas para Bridge)
cat > /usr/local/bin/lab-network-status << 'EOF'
#!/bin/bash
echo "=== 🌐 ESTADO DE RED (MODO BRIDGE) ==="
ip addr show br-lab | grep "inet "
echo "--- Namespaces ---"
ip netns list
echo "--- Conectividad ---"
ip netns exec NS-CLIENT ping -c 1 -W 1 10.10.100.10 >/dev/null && echo "✅ CLIENT -> SRV: OK" || echo "❌ CLIENT -> SRV: FAIL"
ip netns exec NS-SERVICES ping -c 1 -W 1 10.10.100.1 >/dev/null && echo "✅ SRV -> HOST (DB): OK" || echo "❌ SRV -> HOST (DB): FAIL"
EOF
chmod +x /usr/local/bin/lab-network-status

# [4/5] Activación
systemctl daemon-reload
systemctl enable --now lab-network.service

echo "===================================================="
echo "🏆 RED REESTRUCTURADA: AHORA USAS UN BRIDGE"
echo "===================================================="