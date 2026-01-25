#!/bin/bash#===============================================================================
# create-vlan-restore.sh - LAB VLAN AUTOMÁTICO (FIX TOTAL v4.0)
#===============================================================================
# ╔════════════════════════════════════════════════════════════════════════════╗
# ║                              TOPOLOGÍA CREADA                              ║
# ║  ┌─────────────┐    TRUNK Tagged    ┌──────────────┐  Access Ports      ║
# ║  │  PC-1       │◄───VLAN10───┼──────┤              │◄───PC-ADMIN-1      ║
# ║  │192.168.10.11│               │    │   BRIDGE      │◄───PC-ADMIN-2      ║
# ║  └─────────────┘               │    │ VLAN-AWARE   │◄───PC-ADMIN-3      ║
# ║  ┌─────────────┘               │    │  (SW-01)     │                    ║
# ║  │  PC-2       │◄───VLAN20───┼────┤              │◄───VLAN20 Untagged ║
# ║  │192.168.20.11│                    └──────────────┘◄───VLAN30 Untagged ║
# ║  └─────────────┘                              ▲                         ║
# ║  ┌─────────────┐                              │ TRUNK Tagged           ║
# ║  │  PC-3       │◄───VLAN30─────┼────────────────┘                         ║
# ║  │192.168.30.11│                                        ┌─────────────┐   ║
# ║  └─────────────┘                                        │ CORE-01     │   ║
# ║                                                         │ Router L3   │   ║
# ║  eth0  ──┬─── v.10 (192.168.10.1/24)                    │ eth0        │   ║
# ║          ├── v.20 (192.168.20.1/24)                     └─────────────┘   ║
# ║          └── v.30 (192.168.30.1/24)                                        ║
# ╚════════════════════════════════════════════════════════════════════════════╝
#
# 🎯 OBJETIVO PRINCIPAL:
# |─────────────────────────────────────────────────────────────────────────────|
# | Crear en UN SOLO COMANDO una topología completa para:                      |
# |   ✅ Práctica RHCSA/RHCE (networking, VLANs, routing)                      |
# |   ✅ Labs CCNA (inter-VLAN routing, trunking)                              |
# |   ✅ Simulación NOC (troubleshooting VLANs)                                |
# |   ✅ Prototipo segmentación red (admin/ventas/etc)                         |
# |   ✅ Demos Ansible/Terraform (infra como código)                           |
# |─────────────────────────────────────────────────────────────────────────────|
#
# 🔧 TECNOLOGÍA UTILIZADA:
# |──────────────────────┼────────────────────────────────────────────────────|
# | Namespaces Linux     │ PCs + Router aislados (ligeros vs VMs)              |
# | Bridge VLAN-aware    │ Switch L2 real (no dummy)                         |
# | VETH pairs           │ Enlaces virtuales punto-punto                     |
# | 802.1Q VLAN tagging  │ Trunking estándar (tagged trunks)                 |
# | IP Forwarding        │ Router L3 funcional                               |
# |─────────────────────────────────────────────────────────────────────────────|
#
# 📊 ESCALABILIDAD:
# | PCs  │ VLANs │ Memoria │ Uso típico                    |
# |------|-------|---------|-------------------------------|
# | 1-5  | 10-50 | ~50MB   | Práctica certificación        |
# | 6-15 | 60-150| ~200MB  | Simulación mediana            |
# | >15  | >150  | >500MB  | Limitado por kernel VLAN ID   |
# |─────────────────────────────────────────────────────────────────────────────|
#
# 🎓 CONCEPTOS QUE APRENDE:
# 1. Namespaces = máquinas virtuales LIGERAS (sin KVM)
# 2. Bridge vlan_filtering 1 = switch L2 REAL
# 3. bridge vlan add dev X vid Y tagged = trunk port
# 4. bridge vlan add dev X vid Y pvid untagged = access port  
# 5. ip link add link eth0 name v.10 type vlan = subinterfaz
# 6. sysctl net.ipv4.ip_forward = router funcional
# |─────────────────────────────────────────────────────────────────────────────|
#
# 🚀 WORKFLOW TÍPICO DE USO:
# 1. sudo ./create-vlan-lab.sh        # ← CREAR (30s)
# 2. ip netns exec PC-ADMIN-1 ping .. # ← TESTEAR
# 3. ./destroy-vlan-lab.sh           # ← DESTRUIR (5s)
# 4. Repetir con nombres diferentes  # ← ITERAR
# |─────────────────────────────────────────────────────────────────────────────|
#
# ⚠️  PRERREQUISITOS (Rocky Linux 9 / RHEL9):
# ✓ kernel-modules-extra (VLAN support)
# ✓ bridge-utils 
# ✓ iproute2 (incluido)
# ✓ Sudo root (obvio)
# |─────────────────────────────────────────────────────────────────────────────|
#
# 🧪 COMANDOS DE VERIFICACIÓN POST-CREACIÓN:
# |─────────────────────────────────────────────────────────────────────────────|
# | bridge vlan show          # Tabla VLANs del switch                        |
# | ip netns exec CORE-01 ip a| Interfaces router (v.10,v.20,v.30 UP)          |
# | ip link show master SW-01 | Puertos del switch                            |
# | ip netns exec PC-ADMIN-1 ip route | Tabla de rutas PC                   |
# | watch -n1 "bridge -d vlan show"   | Monitor VLANs en tiempo real         |
# |─────────────────────────────────────────────────────────────────────────────|
#
#
# 🎁 BONUS: Exportable a Ansible/Terraform
# - Variables: R_NAME, SW_NAME, PC_BASE, PC_COUNT
# - Idempotente: limpieza automática
# - Predecible: IPs VLAN.11, VLAN.1
# - Documentado: cada paso comentado
#===============================================================================


set -e  # Exit on error

if [ "$EUID" -ne 0 ]; then 
    echo "❌ Ejecuta como root: sudo $0"
    exit 1
fi

echo "--- 🛠️ CREANDO LAB VLAN AUTOMÁTICO v4.0 ---"
read -p "Router (CORE-01): " R_NAME
read -p "Switch (SW-01): " SW_NAME
read -p "PCs base (PC-ADMIN): " PC_BASE
read -p "PCs (1-15): " PC_COUNT

[[ "$PC_COUNT" =~ ^[1-9][0-9]?$ ]] && [[ "$PC_COUNT" -le 15 ]] || { 
    echo "❌ 1-15 PCs máximo"; exit 1; 
}

# 🧹 LIMPIEZA TOTAL
echo "🧹 Limpiando..."
ip link del "$SW_NAME" 2>/dev/null || true
ip netns del "$R_NAME" 2>/dev/null || true
ip netns list 2>/dev/null | grep -E "^${PC_BASE}-[0-9]+$" | xargs -r ip netns del

# 🏗️ INFRAESTRUCTURA BASE
echo "🏗️ Creando switch L2..."
ip link add "$SW_NAME" type bridge
ip link set "$SW_NAME" type bridge vlan_filtering 1
ip link set "$SW_NAME" up

echo "🔗 Router namespace..."
ip netns add "$R_NAME"

# 🔧 TRUNK - ORDEN CRÍTICO
R_VETH="r-${R_NAME:0:8}"
S_VETH="s-${R_NAME:0:8}"
echo "🔗 Trunk $S_VETH ↔ router..."
ip link add "$R_VETH" type veth peer name "$S_VETH"
ip link set "$S_VETH" master "$SW_NAME"
ip link set "$S_VETH" up
ip link set "$R_VETH" netns "$R_NAME"
ip netns exec "$R_NAME" ip link set "$R_VETH" name eth0
ip netns exec "$R_NAME" ip link set eth0 up
ip link set "$S_VETH" up  # HOST side UP

# 🌐 PCs + VLANs
echo "🌐 $PC_COUNT PCs en VLANs..."
declare -a PC_IPS=()
for i in $(seq 1 "$PC_COUNT"); do
    VLAN=$((10 * i))
    PC_NAME="${PC_BASE}-$i"
    PC_IP="192.168.${VLAN}.11"
    GW_IP="192.168.${VLAN}.1"
    PC_IPS+=("$PC_NAME $PC_IP VLAN$VLAN")
    
    echo "  → $PC_NAME (VLAN$VLAN)..."
    
    # PC namespace + veth
    ip netns add "$PC_NAME"
    PC_VETH="pc${i}"
    BR_VETH="b${i}"
    ip link add "$PC_VETH" type veth peer name "$BR_VETH"
    ip link set "$PC_VETH" netns "$PC_NAME"
    ip link set "$BR_VETH" master "$SW_NAME"
    ip link set "$BR_VETH" up
    ip netns exec "$PC_NAME" ip link set "$PC_VETH" up
    
    # VLAN PC (untagged access)
    bridge vlan add dev "$BR_VETH" vid "$VLAN" pvid untagged
    bridge vlan del dev "$BR_VETH" vid 1 2>/dev/null || true
    
    # IP PC
    ip netns exec "$PC_NAME" ip addr add "$PC_IP/24" dev "$PC_VETH"
    ip netns exec "$PC_NAME" ip route add default via "$GW_IP"
    
    # VLAN ROUTER (trunk tagged)
    bridge vlan add dev "$S_VETH" vid "$VLAN" tagged
    bridge vlan del dev "$S_VETH" vid 1 2>/dev/null || true
    ip netns exec "$R_NAME" ip link add link eth0 name "v.$VLAN" type vlan id "$VLAN"
    ip netns exec "$R_NAME" ip addr add "$GW_IP/24" dev "v.$VLAN"
    ip netns exec "$R_NAME" ip link set "v.$VLAN" up
done

# 🚀 ROUTER FORWARDING
ip netns exec "$R_NAME" sysctl -w net.ipv4.ip_forward=1 >/dev/null

# 📊 REPORTE PRO
echo -e "\n${GREEN}✅ LAB CREADO EXITOSO${NC}\n"
echo "========================================================"
printf "%-18s | %-15s | %s\n" "PC" "IP" "VLAN"
echo "--------------------------------------------------------"
printf "%s\n" "${PC_IPS[@]}"
echo "========================================================"

# 🧪 TESTS AUTOMÁTICOS
echo -e "\n🧪 Tests de conectividad:"
if ip netns exec "${PC_BASE}-1" ping -c1 "192.168.10.1" >/dev/null 2>&1; then
    echo "✅ PC1 → GW OK"
else
    echo "❌ PC1 → GW FAIL"
fi

[[ "$PC_COUNT" -gt 1 ]] && {
    if ip netns exec "${PC_BASE}-1" ping -c1 "192.168.20.11" >/dev/null 2>&1; then
        echo "✅ PC1 → PC2 (inter-VLAN) OK"
    else
        echo "❌ PC1 → PC2 FAIL"
    fi
}

echo -e "\n🚀 Comandos útiles:"
echo "  ip netns exec ${PC_BASE}-1 ping 192.168.20.11"
echo "  ip netns exec CORE-01 ip a"
echo "  bridge vlan show"
