#!/bin/bash
# =============================================================================
# LAB BLOQUE 5 — NETWORKING (SCRIPT COMPLEMENTARIO)
# Ejecutar como root: sudo bash lab_bloque5_setup_complementario.sh
# =============================================================================

set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

echo ""; echo "====== LAB BLOQUE 5 — SETUP COMPLEMENTARIO ======"

# PASO 0: VERIFICACIONES
[[ $EUID -ne 0 ]] && echo "ERROR: Ejecutar como root." && exit 1
systemctl is-active --quiet NetworkManager || systemctl start NetworkManager
systemctl is-active --quiet firewalld      || systemctl start firewalld
echo -e "${GREEN}[OK] Prerequisitos${NC}"

# PASO 1: INTERFACES DUMMY
echo -e "${YELLOW}[1/8] Creando lab-net0 y lab-net1...${NC}"
nmcli con delete "lab-net0" 2>/dev/null || true
nmcli con delete "lab-net1" 2>/dev/null || true
nmcli con add type dummy con-name "lab-net0" ifname lab-net0
nmcli con add type dummy con-name "lab-net1" ifname lab-net1
nmcli con mod "lab-net1" connection.autoconnect no   # bug TS-7
nmcli con up "lab-net0" 2>/dev/null || true
echo -e "${GREEN}[OK] Interfaces creadas${NC}"

# PASO 2: CONEXION lab-static CON /32 (BUG)
echo -e "${YELLOW}[2/8] Creando lab-static con mascara /32...${NC}"
nmcli con delete "lab-static" 2>/dev/null || true
nmcli con add type dummy \
    con-name "lab-static" ifname lab-net0 \
    ipv4.method manual \
    ipv4.addresses "192.168.100.10/32" \
    ipv4.gateway "192.168.100.1" \
    ipv4.dns "" \
    connection.autoconnect yes
nmcli con up "lab-static" 2>/dev/null || true
echo -e "${GREEN}[OK] lab-static creada con /32 (bug intencional)${NC}"

# PASO 3: BANNER SSH
echo -e "${YELLOW}[3/8] Configurando banner SSH...${NC}"
cat > /etc/ssh/ssh_banner_lab << 'EOF'
*************************************************************
*  SISTEMA DE LABORATORIO -- SOLO ACCESO AUTORIZADO        *
*  Bloque 5 - Networking Lab                               *
*************************************************************
EOF
mkdir -p /etc/ssh/sshd_config.d
echo "Banner /etc/ssh/ssh_banner_lab" > /etc/ssh/sshd_config.d/99-lab-banner.conf
systemctl reload sshd 2>/dev/null || systemctl restart sshd
echo -e "${GREEN}[OK] Banner SSH activo${NC}"

# PASO 4: RUTA FANTASMA
echo -e "${YELLOW}[4/8] Inyectando ruta invalida 10.0.0.0/24...${NC}"
ip route add 10.0.0.0/24 via 127.0.0.1 dev lo 2>/dev/null || true
nmcli con mod "lab-static" ipv4.routes "10.0.0.0/24 127.0.0.1" 2>/dev/null || true
echo -e "${GREEN}[OK] Ruta fantasma anadida${NC}"

# PASO 5: RICH RULE FIREWALL
echo -e "${YELLOW}[5/8] Creando Rich Rule REJECT para 192.168.100.50...${NC}"
firewall-cmd --permanent --zone=public \
    --add-rich-rule='rule family="ipv4" source address="192.168.100.50" log prefix="REJECTED_USER: " level="warning" reject' 2>/dev/null || true
firewall-cmd --reload
echo -e "${GREEN}[OK] Rich Rule creada${NC}"

# PASO 6: SABOTAJE /etc/hosts
echo -e "${YELLOW}[6/8] Saboteando /etc/hosts...${NC}"
cp /etc/hosts /etc/hosts.lab_backup
sed -i 's/^127\.0\.0\.1\s\+localhost.*/127.0.0.2 localhost localhost.localdomain/' /etc/hosts
echo -e "${RED}  AVISO: 'ping localhost' fallara. Backup en /etc/hosts.lab_backup${NC}"
echo -e "${GREEN}[OK] /etc/hosts saboteado${NC}"

# PASO 7: MTU INCORRECTA
echo -e "${YELLOW}[7/8] MTU incorrecta en lab-net0...${NC}"
ip link set lab-net0 mtu 576 2>/dev/null || true
nmcli con mod "lab-net0" ethernet.mtu 576 2>/dev/null || true
echo -e "${GREEN}[OK] MTU = 576 (deberia ser 1500)${NC}"

# PASO 8: DNS ROTO
echo -e "${YELLOW}[8/8] Eliminando DNS de lab-static...${NC}"
nmcli con mod "lab-static" ipv4.dns "" ipv4.dns-search "" 2>/dev/null || true
echo -e "${GREEN}[OK] DNS eliminado de lab-static${NC}"

# RESUMEN
echo ""
echo "======================================================"
echo -e "${GREEN} COMPLETADO — Los 40 ejercicios estan listos${NC}"
echo "======================================================"
echo "  lab-net0       : dummy, MTU=576"
echo "  lab-net1       : dummy, autoconnect=no"
echo "  lab-static     : 192.168.100.10/32 (bug), sin DNS"
echo "  Ruta fantasma  : 10.0.0.0/24 via 127.0.0.1"
echo "  SSH Banner     : /etc/ssh/ssh_banner_lab"
echo "  Rich Rule      : REJECT 192.168.100.50 en public"
echo "  /etc/hosts     : saboteado (backup: /etc/hosts.lab_backup)"
echo "  MTU lab-net0   : 576 (bug)"
echo ""
echo "Restaurar /etc/hosts cuando quieras:"
echo "  sudo cp /etc/hosts.lab_backup /etc/hosts"
echo "======================================================"