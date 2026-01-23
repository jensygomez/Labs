#!/bin/bash
# ============================================================================
# PROYECTO: Automatización de Golden Base Image (Rocky Linux)
# SCRIPT:   2 de 5 - Infraestructura Global con Seguridad Perimetral (NFT)
# ============================================================================
#
# OBJETIVO:
# Crear un ecosistema de red segmentado por zonas geográficas y niveles de
# confianza, protegido por un Firewall STATEFUL moderno (nftables) en el Core.
#
# ARQUITECTURA:
# 1. SEDES (Namespaces):
#    - Alemania  (NS-SERVICES) -> SRV
#    - China     (NS-CLIENT)   -> CLI
#    - India     (NS-DEV)      -> DEV
#    - Búnker    (NS-STORAGE)  -> DATA
#    - SysAdmin  (NS-SYSADMIN) -> ADM
#
# 2. CORE ROUTER:
#    - Namespace: NS-ROUTER
#    - Centraliza el tráfico inter-segmentos
#
# 3. POLÍTICAS DE ACCESO:
#    - China   -> Alemania (solo Web)
#    - China   -> Búnker   (BLOQUEADO)
#    - Alemania-> Búnker   (DB)
#    - India   -> Búnker   (FULL)
#    - SysAdmin-> TODOS    (FULL)
# ============================================================================

set -e

echo "=== 🌐 SCRIPT 2: RED GLOBAL + FIREWALL NFTABLES ==="
echo "📅 Fecha: $(date)"

# ============================================================================
# [1/4] Constructor de Red y Seguridad
# ============================================================================
cat > /usr/local/bin/lab-net-setup.sh << 'EOF'
#!/bin/bash
set -e

# --- MAPEO DE SEGMENTOS ---
declare -A SEGMENTOS=(
  ["srv"]="10.10.0"
  ["cli"]="10.20.0"
  ["dev"]="10.30.0"
  ["data"]="10.90.0"
  ["adm"]="172.16.0"
)

# --- LIMPIEZA PROFUNDA (IDEMPOTENTE) ---
echo "🧹 Limpiando configuraciones previas..."
for ns in NS-ROUTER NS-SERVICES NS-CLIENT NS-DEV NS-STORAGE NS-SYSADMIN; do
  ip netns del "$ns" 2>/dev/null || true
done

for br in br-srv br-cli br-dev br-data br-adm; do
  ip link del "$br" 2>/dev/null || true
done

# --- 1. ROUTER CENTRAL ---
echo "🧠 Creando NS-ROUTER..."
ip netns add NS-ROUTER
ip netns exec NS-ROUTER sysctl -w net.ipv4.ip_forward=1 >/dev/null

# --- 2. SWITCHES (BRIDGES) + ENLACE AL ROUTER ---
for s in "${!SEGMENTOS[@]}"; do
  ip link add br-$s type bridge
  ip link set br-$s up

  # veths cortos (límite kernel)
  ip link add v-r$s type veth peer name v-nr$s
  ip link set v-r$s master br-$s
  ip link set v-r$s up

  ip link set v-nr$s netns NS-ROUTER
  ip netns exec NS-ROUTER ip addr add ${SEGMENTOS[$s]}.1/24 dev v-nr$s
  ip netns exec NS-ROUTER ip link set v-nr$s up
done

# --- 3. FUNCIÓN DE CONEXIÓN DE NODOS ---
conectar() {
  local ns=$1
  local seg=$2
  local ip=$3
  local gw="${SEGMENTOS[$seg]}.1"

  ip netns add "$ns"
  ip link add v-$seg type veth peer name v-n$seg
  ip link set v-$seg master br-$seg
  ip link set v-$seg up

  ip link set v-n$seg netns "$ns"
  ip netns exec "$ns" ip addr add "$ip" dev v-n$seg
  ip netns exec "$ns" ip link set v-n$seg up
  ip netns exec "$ns" ip link set lo up
  ip netns exec "$ns" ip route add default via "$gw"
}

# --- 4. DESPLIEGUE GEOGRÁFICO ---
conectar "NS-SERVICES" "srv"  "10.10.0.10/24"    # 🇩🇪 Alemania
conectar "NS-CLIENT"   "cli"  "10.20.0.20/24"    # 🇨🇳 China
conectar "NS-DEV"      "dev"  "10.30.0.30/24"    # 🇮🇳 India
conectar "NS-STORAGE"  "data" "10.90.0.50/24"    # 🔐 Búnker
conectar "NS-SYSADMIN" "adm"  "172.16.0.100/24"  # 🏠 SysAdmin

# ============================================================================
# [5] FIREWALL STATEFUL – NFTABLES (CORE ROUTER)
# ============================================================================
echo "🛡️  Aplicando políticas nftables en NS-ROUTER..."

ip netns exec NS-ROUTER nft -f - << 'NFT'
flush ruleset

table inet filter {

  chain forward {
    type filter hook forward priority 0;
    policy drop;

    # Tráfico establecido
    ct state established,related accept

    # ------------------------------------------------
    # 1. CHINA -> ALEMANIA (WEB)
    # ------------------------------------------------
    ip saddr 10.20.0.0/24 ip daddr 10.10.0.10 tcp dport { 80, 443 } accept
    ip saddr 10.20.0.0/24 ip daddr 10.10.0.10 icmp type echo-request accept

    # ------------------------------------------------
    # 2. ALEMANIA -> BÚNKER (DB)
    # ------------------------------------------------
    ip saddr 10.10.0.10 ip daddr 10.90.0.50 tcp dport 3306 accept
    ip saddr 10.10.0.10 ip daddr 10.90.0.50 icmp type echo-request accept

    # ------------------------------------------------
    # 3. INDIA -> BÚNKER (FULL)
    # ------------------------------------------------
    ip saddr 10.30.0.0/24 ip daddr 10.90.0.50 accept

    # ------------------------------------------------
    # 4. SYSADMIN -> TODOS
    # ------------------------------------------------
    ip saddr 172.16.0.0/24 accept
  }
}
NFT

EOF

chmod +x /usr/local/bin/lab-net-setup.sh

# ============================================================================
# [2/4] Persistencia systemd
# ============================================================================
cat > /etc/systemd/system/lab-network.service << 'EOF'
[Unit]
Description=Lab Enterprise Network (nftables)
After=network.target
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/lab-net-setup.sh
[Install]
WantedBy=multi-user.target
EOF

# ============================================================================
# [3/4] Auditoría de Seguridad
# ============================================================================
cat > /usr/local/bin/lab-network-status << 'EOF'
#!/bin/bash
echo "=== 🛰️  AUDITORÍA DE SEGURIDAD GLOBAL ==="

check() {
  local src=$1 dst=$2 label=$3
  echo -n "$label: "
  ip netns exec "$src" ping -c 1 -W 1 "$dst" >/dev/null \
    && echo "✅ PERMITIDO" || echo "❌ BLOQUEADO"
}

check NS-CLIENT   10.10.0.10 "1. CHINA   -> ALEMANIA (WEB)"
check NS-CLIENT   10.90.0.50 "2. CHINA   -> BÚNKER   (DATOS)"
check NS-SERVICES 10.90.0.50 "3. ALEMANIA-> BÚNKER   (DB)"
check NS-SYSADMIN 10.90.0.50 "4. SYSADMIN-> TODOS"
EOF

chmod +x /usr/local/bin/lab-network-status

# ============================================================================
# [4/4] Activación Final
# ============================================================================
systemctl daemon-reload
systemctl enable --now lab-network.service

echo "===================================================="
echo "🏆 RED ENTERPRISE GLOBAL (NFTABLES) DESPLEGADA"
echo "===================================================="
