#!/bin/bash
# ============================================================================
# PROYECTO: Automatización de Golden Base Image (Rocky Linux)
# SCRIPT:   2 de 5 - Infraestructura de Red Global Segmentada (Layer 3)
# ============================================================================
#
# RESUMEN SCRIPT 1 (CIMENTACIÓN):
#   ✅ Sistema base preparado y herramientas de red instaladas.
#
# OBJETIVO SCRIPT 2 (ARQUITECTURA ENTERPRISE):
#   Evolucionar de una red plana a una topología de "Core Router" dedicada.
#   Se crean islas tecnológicas (Namespaces) que representan sedes globales,
#   interconectadas por un Router virtualizado que gestiona el tráfico.
#
# MECANISMOS DE INGENIERÍA IMPLEMENTADOS:
# 1. SEGMENTACIÓN POR VLAN (Bridges): Cada región (Alemania, China, India, 
#    Búnker) posee su propio switch virtual (br-srv, br-cli, br-dev, br-data).
# 2. CORE ROUTER (NS-ROUTER): Se despliega un Namespace dedicado que actúa 
#    como Gateway central. Es el único punto con IP Forwarding habilitado.
# 3. AISLAMIENTO DEL HOST: El Host OS actúa únicamente como chasis (Capa 2).
#    No posee IPs en las redes del laboratorio, reforzando la seguridad.
# 4. SIMULACIÓN DE LATENCIA Y TRÁFICO: Esta base permite implementar reglas
#    de QoS o Firewall (iptables) dentro del Router en fases posteriores.
#
# PRÓXIMO PASO (SCRIPT 3):
#   Configurar los servicios internos (Nginx/DNS) en NS-SERVICES para que
#   respondan a peticiones ruteadas desde cualquier parte del mundo.
# ============================================================================

set -e

echo "=== 🌐 SCRIPT 2: DESPLEGANDO CORE-ROUTER Y SEGMENTACIÓN GLOBAL ==="
echo "📅 Fecha: $(date)"

# [1/5] Creación del Script de Configuración (El "Arquitecto")
cat > /usr/local/bin/lab-net-setup.sh << 'EOF'
#!/bin/bash
set -e

# --- CONFIGURACIÓN DE SEGMENTOS ---
# Mapeo de redes para simular ubicaciones geográficas
declare -A SEGMENTOS=( 
  ["srv"]="10.10.0"   # 🇪🇺 ALEMANIA (Servicios)
  ["cli"]="10.20.0"   # 🌏 CHINA (Cliente)
  ["dev"]="10.30.0"   # 🇮🇳 INDIA (Desarrollo)
  ["data"]="10.90.0"  # 🔐 BÚNKER (Almacenamiento)
  ["adm"]="172.16.0"  # 🏠 HOME OFFICE (Gestión)
)

# --- LIMPIEZA TOTAL (Idempotencia) ---
echo "🧹 Limpiando escenarios previos..."
for seg in "${!SEGMENTOS[@]}"; do ip link delete br-$seg 2>/dev/null || true; done
ip link delete br-lab 2>/dev/null || true
for ns in NS-ROUTER NS-SERVICES NS-CLIENT NS-DEV NS-STORAGE NS-SYSADMIN; do
    ip netns delete $ns 2>/dev/null || true
done

# --- 1. CREAR EL CORAZÓN: NS-ROUTER ---
echo "🧠 Creando NS-ROUTER (El Cerebro del Lab)..."
ip netns add NS-ROUTER
ip netns exec NS-ROUTER sysctl -w net.ipv4.ip_forward=1 > /dev/null

# --- 2. CREACIÓN DE BRIDGES Y CONEXIÓN AL ROUTER ---
for seg in "${!SEGMENTOS[@]}"; do
    BR="br-$seg"
    RED="${SEGMENTOS[$seg]}"
    echo "🌉 Configurando Switch $BR y conectando al Router..."

    # Crear Bridge (Switch de Capa 2, sin IP en el host)
    ip link add name $BR type bridge
    ip link set $BR up

    # Crear cable Veth (Patch cord virtual)
    ip link add v-r-$seg type veth peer name v-nic-r-$seg
    ip link set v-r-$seg master $BR
    ip link set v-r-$seg up
    
    # Conectar al Router y asignar IP del Gateway (.1)
    ip link set v-nic-r-$seg netns NS-ROUTER
    ip netns exec NS-ROUTER ip addr add $RED.1/24 dev v-nic-r-$seg
    ip netns exec NS-ROUTER ip link set v-nic-r-$seg up
done

# --- 3. CREACIÓN DE LOS NODOS FINALES (ENDPOINTS) ---
conectar_nodo() {
    local ns=$1; local seg=$2; local ip_final=$3
    local BR="br-$seg"
    local GW="${SEGMENTOS[$seg]}.1"
    
    echo "🏗️  Desplegando $ns en segmento $seg..."
    ip netns add $ns
    ip link add v-$ns type veth peer name v-nic-$ns
    ip link set v-$ns master $BR
    ip link set v-$ns up
    
    ip link set v-nic-$ns netns $ns
    ip netns exec $ns ip addr add $ip_final dev v-nic-$ns
    ip netns exec $ns ip link set v-nic-$ns up
    ip netns exec $ns ip link set lo up
    # Apuntar al Router para salir de su propia red
    ip netns exec $ns ip route add default via $GW
}

# Ejecutar despliegue de nodos geográficos
conectar_nodo "NS-SERVICES" "srv"  "10.10.0.10/24"
conectar_nodo "NS-CLIENT"   "cli"  "10.20.0.20/24"
conectar_nodo "NS-DEV"      "dev"  "10.30.0.30/24"
conectar_nodo "NS-STORAGE"  "data" "10.90.0.50/24"
conectar_nodo "NS-SYSADMIN" "adm"  "172.16.0.100/24"

echo "✅ Red Global con Router Dedicado configurada."
EOF

chmod +x /usr/local/bin/lab-net-setup.sh

# [2/5] Persistencia Systemd (Asegura el cableado al reiniciar)
cat > /etc/systemd/system/lab-network.service << 'EOF'
[Unit]
Description=Enterprise Router Network Persistence
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/lab-net-setup.sh

[Install]
WantedBy=multi-user.target
EOF

# [3/5] Herramienta de Diagnóstico "Visual Router"
cat > /usr/local/bin/lab-network-status << 'EOF'
#!/bin/bash
echo "=== 🛰️  TOPOLOGÍA GLOBAL (VIA NS-ROUTER) ==="
echo "RUTA: [ORIGEN] -> [GATEWAY ROUTER] -> [DESTINO]"
echo "--------------------------------------------------------"
ip netns exec NS-CLIENT ping -c 1 -W 1 10.10.0.10 >/dev/null && echo "✅ CHINA -> NS-ROUTER -> ALEMANIA: OK" || echo "❌ CONEXIÓN ROTA"
ip netns exec NS-DEV ping -c 1 -W 1 10.90.0.50 >/dev/null && echo "✅ INDIA -> NS-ROUTER -> BÚNKER: OK" || echo "❌ CONEXIÓN ROTA"
echo "--------------------------------------------------------"
echo "Tabla de ruteo interna del NS-ROUTER:"
ip netns exec NS-ROUTER ip -4 route | grep -v "lo"
EOF
chmod +x /usr/local/bin/lab-network-status

# [4/5] Activación de la Infraestructura
systemctl daemon-reload
systemctl enable --now lab-network.service

echo "===================================================="
echo "🏆 CORE-ROUTER INSTALADO Y OPERATIVO"
echo "===================================================="