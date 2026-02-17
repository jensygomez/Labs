#!/bin/bash
# ===================================================================================
# LAB 03: DEPARTAMENTO SYS (ADMIN BASTIÓN)
# Prerequisito: Lab 02 ejecutado y funcionando
# ===================================================================================

echo "==[ 8. CREACIÓN NAMESPACE NS-SYS ]=="
ip netns add NS-SYS 2>/dev/null || true
ip netns exec NS-SYS ip link set lo up

echo "==[ 9. BRIDGE INTERNO BR-SYS ]=="
ip netns exec NS-SYS ip link add br-sys type bridge 2>/dev/null || true
ip netns exec NS-SYS ip link set br-sys up

echo "==[ 10. ENLACE CORE-GW ↔ NS-SYS ]=="
ip link add v-gw-sys type veth peer name v-sys-gw 2>/dev/null || true
ip link set v-gw-sys netns CORE-GW
ip link set v-sys-gw netns NS-SYS
ip netns exec CORE-GW ip link set v-gw-sys master br0
ip netns exec CORE-GW ip link set v-gw-sys up
ip netns exec NS-SYS ip link set v-sys-gw master br-sys
ip netns exec NS-SYS ip link set v-sys-gw up

echo "==[ 11. DESPLIEGUE PC_1-SYS (BASTIÓN) ]=="
ip netns add PC_1-SYS 2>/dev/null || true
ip link add v-pc1-sys type veth peer name v-sys-pc1 2>/dev/null || true
ip link set v-pc1-sys netns PC_1-SYS
ip link set v-sys-pc1 netns NS-SYS
ip netns exec NS-SYS ip link set v-sys-pc1 master br-sys
ip netns exec NS-SYS ip link set v-sys-pc1 up
ip netns exec PC_1-SYS ip link set lo up
ip netns exec PC_1-SYS ip link set v-pc1-sys up
ip netns exec PC_1-SYS ip addr add 10.0.0.31/24 dev v-pc1-sys
ip netns exec PC_1-SYS ip route add default via 10.0.0.1
echo "   ✔ PC_1-SYS configurada (10.0.0.31)"

echo "==[ 12. VERIFICACIÓN FINAL LAB 03 ]=="
echo -n "→ PC_1-SYS → Gateway (10.0.0.1): "
if ip netns exec PC_1-SYS ping -c1 -W1 10.0.0.1 >/dev/null; then echo "OK"; else echo "FAIL"; fi

echo -n "→ PC_1-SYS → PC_1-RH (10.0.0.21): "
if ip netns exec PC_1-SYS ping -c1 -W1 10.0.0.21 >/dev/null; then echo "OK"; else echo "FAIL"; fi

echo -n "→ PC_1-SYS → Internet (8.8.8.8): "
if ip netns exec PC_1-SYS ping -c1 -W1 8.8.8.8 >/dev/null; then echo "OK"; else echo "FAIL"; fi