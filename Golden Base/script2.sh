#!/bin/bash
# ============================================================================
# PROYECTO: Automatización de Golden Base Image (Rocky Linux)
# SCRIPT:   2 de 5 - Infraestructura Global con Seguridad Perimetral
# ============================================================================
#
# OBJETIVO: Crear un ecosistema de red segmentado por zonas geográficas y
# niveles de confianza, protegido por un Firewall de estado en el Core.
#
# ARQUITECTURA:
# 1. SEDES (Namespaces): Alemania (SRV), China (CLI), India (DEV), Búnker (DATA).
# 2. CORE ROUTER: Namespace 'NS-ROUTER' que centraliza el tráfico inter-VLAN.
# 3. POLÍTICAS DE ACCESO (ACLs):
#    - China (CLI) -> Solo puede ver la Web en Alemania (SRV).
#    - China (CLI) -> BLOQUEADO el acceso directo al Búnker (DATA).
#    - Alemania (SRV) -> Acceso a Base de Datos en el Búnker (DATA).
#    - India (DEV) -> Acceso de gestión al Búnker (DATA).
#    - SysAdmin -> Acceso irrestricto a toda la infraestructura.
# ============================================================================

set -e

echo "=== 🌐 SCRIPT 2: DESPLEGANDO RED GLOBAL Y FIREWALL STATEFUL ==="
echo "📅 Fecha: $(date)"

# [1/4] El Constructor de Red y Seguridad
cat > /usr/local/bin/lab-net-setup.sh << 'EOF'
#!/bin/bash
set -e

# --- MAPEO DE SEGMENTOS ---
declare -A SEGMENTOS=( 
  ["srv"]="10.10.0" ["cli"]="10.20.0" ["dev"]="10.30.0" 
  ["data"]="10.90.0" ["adm"]="172.16.0" 
)

# --- LIMPIEZA PROFUNDA ---
echo "🧹 Limpiando configuraciones previas..."
for ns in NS-ROUTER NS-SERVICES NS-CLIENT NS-DEV NS-STORAGE NS-SYSADMIN; do ip netns del $ns 2>/dev/null || true; done
for br in br-srv br-cli br-dev br-data br-adm br-lab; do ip link del $br 2>/dev/null || true; done

# --- 1. CREACIÓN DEL ROUTER CENTRAL ---
echo "🧠 Iniciando NS-ROUTER..."
ip netns add NS-ROUTER
ip netns exec NS-ROUTER sysctl -w net.ipv4.ip_forward=1 > /dev/null

# --- 2. CREACIÓN DE SWITCHES (BRIDGES) Y CONEXIÓN AL ROUTER ---
for s in "${!SEGMENTOS[@]}"; do
    ip link add br-$s type bridge
    ip link set br-$s up
    # Veths cortos para evitar el límite de 15 caracteres del kernel
    ip link add v-r$s type veth peer name v-nr$s
    ip link set v-r$s master br-$s
    ip link set v-r$s up
    ip link set v-nr$s netns NS-ROUTER
    ip netns exec NS-ROUTER ip addr add ${SEGMENTOS[$s]}.1/24 dev v-nr$s
    ip netns exec NS-ROUTER ip link set v-nr$s up
done

# --- 3. DESPLIEGUE DE NODOS GEOGRÁFICOS ---
conectar() {
    local ns=$1; local s=$2; local ip=$3; local gw="${SEGMENTOS[$s]}.1"
    ip netns add $ns
    ip link add v-$s type veth peer name v-n$s
    ip link set v-$s master br-$s
    ip link set v-$s up
    ip link set v-n$s netns $ns
    ip netns exec $ns ip addr add $ip dev v-n$s
    ip netns exec $ns ip link set v-n$s up
    ip netns exec $ns ip link set lo up
    ip netns exec $ns ip route add default via $gw
}

conectar "NS-SERVICES" "srv" "10.10.0.10/24"   # 🇩🇪 Alemania
conectar "NS-CLIENT"   "cli" "10.20.0.20/24"   # 🇨🇳 China
conectar "NS-DEV"      "dev" "10.30.0.30/24"   # 🇮🇳 India
conectar "NS-STORAGE"  "data" "10.90.0.50/24"  # 🔐 Búnker
conectar "NS-SYSADMIN" "adm" "172.16.0.100/24" # 🏠 Home Office

# --- 4. POLÍTICAS DE SEGURIDAD (IPTABLES) ---
echo "🛡️  Configurando Firewall Statefull en el Router..."
ip netns exec NS-ROUTER bash << 'FW'
  iptables -F
  iptables -P FORWARD DROP
  # Permitir tráfico de retorno
  iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
  # Acceso a Web (China a Alemania)
  iptables -A FORWARD -s 10.20.0.0/24 -d 10.10.0.10 -p tcp -m multiport --dports 80,443 -j ACCEPT
  iptables -A FORWARD -s 10.20.0.0/24 -d 10.10.0.10 -p icmp -j ACCEPT
  # Acceso a DB (Alemania e India al Búnker)
  iptables -A FORWARD -s 10.10.0.10 -d 10.90.0.50 -p tcp --dport 3306 -j ACCEPT
  iptables -A FORWARD -s 10.30.0.0/24 -d 10.90.0.50 -j ACCEPT
  # Acceso Total (SysAdmin)
  iptables -A FORWARD -s 172.16.0.0/24 -j ACCEPT
FW
EOF

chmod +x /usr/local/bin/lab-net-setup.sh

# [2/4] Persistencia vía Systemd
cat > /etc/systemd/system/lab-network.service << 'EOF'
[Unit]
Description=Lab Enterprise Network Service
After=network.target
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/lab-net-setup.sh
[Install]
WantedBy=multi-user.target
EOF

# [3/4] Herramienta de Auditoría de Red
cat > /usr/local/bin/lab-network-status << 'EOF'
#!/bin/bash
echo "=== 🛰️  AUDITORÍA DE SEGURIDAD GLOBAL ==="
echo -n "1. CHINA   -> ALEMANIA (Web): "
ip netns exec NS-CLIENT ping -c 1 -W 1 10.10.0.10 >/dev/null && echo "✅ PERMITIDO" || echo "❌ BLOQUEADO"

echo -n "2. CHINA   -> BÚNKER (Datos): "
ip netns exec NS-CLIENT ping -c 1 -W 1 10.90.0.50 >/dev/null && echo "✅ PERMITIDO" || echo "❌ BLOQUEADO (Seguridad OK)"

echo -n "3. GERMANY -> BÚNKER (DB):    "
ip netns exec NS-SERVICES ping -c 1 -W 1 10.90.0.50 >/dev/null && echo "✅ PERMITIDO" || echo "❌ BLOQUEADO"

echo -n "4. SYSADMIN -> TODOS:         "
ip netns exec NS-SYSADMIN ping -c 1 -W 1 10.90.0.50 >/dev/null && echo "✅ PERMITIDO" || echo "❌ BLOQUEADO"
EOF
chmod +x /usr/local/bin/lab-network-status

# [4/4] Activación Final
systemctl daemon-reload
systemctl enable --now lab-network.service

echo "===================================================="
echo "🏆 RED ENTERPRISE SEGURIZADA DESPLEGADA"
echo "===================================================="