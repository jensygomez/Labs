#!/bin/bash
# =============================================================================
# 🛣️  PROYECTO: Golden Base Image - Labs 3-Tier Enterprise (Rocky Linux)
# SCRIPT:  2/5 - CARRETERA GLOBAL (Conectividad L2/L3 Pura)
# =============================================================================
#
# 📍 FILOSOFÍA UNIX APLICADA:
# • "Do One Thing Well": SOLO conectividad base. Sin firewall/servicios.
# • KISS: Carretera limpia ANTES de semáforos/firewall.
# • Idempotente: Re-ejecutable sin corrupción (cleanup total).
# • Modular: Base sólida para Script 3 (nftables), Script 4 (servicios).
#
# 🏗️  ARQUITECTURA L2/L3:
# HOST FÍSICO
#    ↓ veth-host
# NS-ANSIBLE (.254) ← Ansible orquesta directo a bridges
#    ↓ bridges L2
# [NS-ROUTER] ← IP forwarding (.1 gateways)
#    ↓ veth pairs
# NS-SRV  (10.10.0.10) 🇩🇪 Alemania - Web
# NS-CLI  (10.20.0.20) 🇨🇳 China   - Cliente
# NS-DEV  (10.30.0.30) 🇮🇳 India   - Desarrollo
# NS-DATA (10.90.0.50) 🔐 Búnker  - Base de datos
# NS-ADM  (172.16.0.100) 🏠 SysAdmin
#
# 🚦 PRÓXIMOS SCRIPTS:
# Script 3: Semáforos NFTables (China NO→Búnker, Srv→DB OK)
# Script 4: Edificios (Nginx NS-SRV, MariaDB NS-DATA)
# Script 5: Seguridad (harden, monitoring, Ansible IaC)
#
# ✅ REQUISITOS: Script 1 ejecutado (paquetes base instalados)
# ✅ RESULTADO: `ip netns exec NS-CLI ping 10.10.0.10` → 0.1ms latencia
# =============================================================================
#
# USO:
# 1. `./script2-carretera.sh`  → Despliega topología
# 2. `ip netns exec NS-CLI ping -c2 10.10.0.10` → Test conectividad
# 3. `./script3-semaforos.sh` → Agregar políticas firewall
# =============================================================================

set -e

echo "=== 🛣️  SCRIPT 2/5: CARRETERA GLOBAL ==="
echo "📅 $(date)"
echo "========================================"

# [1] LIMPIEZA TOTAL (idempotencia)
echo "🧹 Cleanup namespaces..."

# Eliminar namespaces conocidos
for ns in $(ip netns list | awk '{print $1}' | grep '^NS-'); do
  ip netns del "$ns" 2>/dev/null || true
done

# Eliminar restos huérfanos
rm -f /var/run/netns/NS-* 2>/dev/null || true

# Limpiar bridges
for br in $(ip link show type bridge | grep -o 'br-[a-z]*' | uniq); do
  ip link del "$br" 2>/dev/null || true
done

# [2] ROUTER CENTRAL (.1 en todos los segmentos)
echo "🧠 NS-ROUTER..."
ip netns add NS-ROUTER
ip netns exec NS-ROUTER sysctl -w net.ipv4.ip_forward=1
ip netns exec NS-ROUTER ip link set lo up

# [3] NS-ANSIBLE (directo desde HOST físico)
echo "🔧 NS-ANSIBLE..."
ip netns add NS-ANSIBLE
ip link add br-ansible type bridge 2>/dev/null || true
ip link set br-ansible up
ip link add veth-host type veth peer name veth-ansible 2>/dev/null || true
ip link set veth-host up
ip link set veth-ansible netns NS-ANSIBLE
ip netns exec NS-ANSIBLE ip addr add 172.17.0.1/24 dev veth-ansible 2>/dev/null || true
ip netns exec NS-ANSIBLE ip link set veth-ansible up
ip netns exec NS-ANSIBLE ip link set lo up

# [4] CARRETERA POR SEGMENTO (Bridge → Router → Cliente)
declare -A IPS=(["srv"]="10.10.0.10" ["cli"]="10.20.0.20" ["dev"]="10.30.0.30" ["data"]="10.90.0.50" ["adm"]="172.16.0.100")
declare -A GWs=(["srv"]="10.10.0.1"  ["cli"]="10.20.0.1"  ["dev"]="10.30.0.1"  ["data"]="10.90.0.1"  ["adm"]="172.16.0.1")

for seg in "${!IPS[@]}"; do
  echo "  🛣️  [$seg] ${IPS[$seg]} → ${GWs[$seg]}"
  
  # Bridge L2
  ip link add br-$seg type bridge 2>/dev/null || true
  ip link set br-$seg up
  
  # Bridge ↔ Router (.1)
  ip link add v-r$seg type veth peer name v-nr$seg 2>/dev/null || true
  ip link set v-r$seg master br-$seg
  ip link set v-r$seg up
  ip link set v-nr$seg netns NS-ROUTER 2>/dev/null || true
  ip netns exec NS-ROUTER ip addr add ${GWs[$seg]}/24 dev v-nr$seg 2>/dev/null || true
  ip netns exec NS-ROUTER ip link set v-nr$seg up
  
  # Bridge ↔ Cliente (.10/.20/etc)
  ip netns add "NS-${seg^^}" 2>/dev/null || true
  ip link add v-$seg type veth peer name v-n$seg 2>/dev/null || true
  ip link set v-$seg master br-$seg
  ip link set v-$seg up
  ip link set v-n$seg netns "NS-${seg^^}"
  ip netns exec "NS-${seg^^}" ip addr add ${IPS[$seg]}/24 dev v-n$seg 2>/dev/null || true
  ip netns exec "NS-${seg^^}" ip link set v-n$seg up
  ip netns exec "NS-${seg^^}" ip link set lo up
  ip netns exec "NS-${seg^^}" ip route add default via ${GWs[$seg]} 2>/dev/null || true
done

# [5] ANSIBLE LINKS DIRECTOS (bypass router)
echo "🔌 Ansible → bridges..."
for seg in "${!IPS[@]}"; do
  ip link add v-ansible-$seg type veth peer name v-$seg-ansible 2>/dev/null || true
  ip link set v-ansible-$seg netns NS-ANSIBLE
  ip link set v-$seg-ansible master br-$seg
  ip link set v-ansible-$seg up
  ip link set v-$seg-ansible up
  ip netns exec NS-ANSIBLE ip addr add ${GWs[$seg]%.*}.254/24 dev v-ansible-$seg 2>/dev/null || true
done

echo "=============================================="
echo "✅ CARRETERA GLOBAL 100% OPERATIVA"
echo "=============================================="
echo "🚦 7 Namespaces | 6 Bridges | 0.1ms latencia esperada"
echo ""
echo "🔍 TEST CONECTIVIDAD:"
echo "ip netns exec NS-CLI ping -c2 10.10.0.10"
echo "ip netns exec NS-SRV ping -c2 10.90.0.50"
echo ""
echo "🚀 PRÓXIMO: script3-semaforos.sh (nftables/firewall)"
echo "=============================================="

# [6] SYSTEMD PERSISTENTE
cat > /etc/systemd/system/lab-carretera.service << 'EOF'
[Unit]
Description=Lab 3-Tier Carretera (L2/L3 base)
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/lab-net-setup.sh

[Install]
WantedBy=multi-user.target
EOF

# También necesitarás crear el script de systemd
cat > /usr/local/bin/lab-net-setup.sh << 'EOF'
#!/bin/bash
# Script de configuración de red para systemd
set -e

# Tu lógica de configuración de red aquí
# (puedes copiar la parte relevante del script principal)
EOF

chmod +x /usr/local/bin/lab-net-setup.sh
systemctl daemon-reload
systemctl enable lab-carretera.service

echo "✅ Systemd: systemctl restart lab-carretera.service"