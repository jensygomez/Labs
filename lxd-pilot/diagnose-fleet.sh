#!/bin/bash
# diagnose-fleet.sh - Diagnóstico completo sin ocultar errores

NAME="server01"
IP="10.77.77.11"

echo "🔍 DIAGNÓSTICO COMPLETO DE $NAME"
echo "======================================"

echo ""
echo "1️⃣  Verificando si SSH está instalado..."
lxc exec $NAME -- rpm -q openssh-server

echo ""
echo "2️⃣  Verificando estado del servicio SSH..."
lxc exec $NAME -- systemctl status sshd

echo ""
echo "3️⃣  Verificando configuración de red..."
lxc exec $NAME -- ip addr show eth0

echo ""
echo "4️⃣  Verificando conexiones NetworkManager..."
lxc exec $NAME -- nmcli con show

echo ""
echo "5️⃣  Verificando firewall..."
lxc exec $NAME -- firewall-cmd --list-all

echo ""
echo "6️⃣  Verificando si el puerto 22 está escuchando..."
lxc exec $NAME -- ss -tlnp | grep :22

echo ""
echo "7️⃣  Probando ping desde la laptop..."
ping -c 2 $IP

echo ""
echo "8️⃣  Intentando SSH manualmente..."
ssh -v -o StrictHostKeyChecking=no -o ConnectTimeout=5 labadmin@$IP "echo test" 2>&1 | head -20
