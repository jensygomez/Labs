#!/bin/bash
# ============================================================================
# SCRIPT 5 de 5: AUDITORÍA FINAL Y SELLADO (GOLDEN IMAGE READY)
# ============================================================================
set -e

echo "=== 🏁 SCRIPT 5: CERTIFICACIÓN Y SELLADO FINAL ==="
echo "📅 Fecha: $(date)"

# ---------------------------------------------------------------------------
# 1. AUDITORÍA DE CONECTIVIDAD (QA)
# ---------------------------------------------------------------------------
echo "[1/4] 🧪 Ejecutando pruebas de certificación..."

# Prueba A: Resolución DNS Interna
echo -n "   • Test DNS (web.lab.local): "
if ip netns exec NS-CLIENT nslookup web.lab.local | grep -q "10.10.100.10"; then
    echo "✅ EXITOSO"
else
    echo "❌ FALLIDO"; exit 1
fi

# Prueba B: Acceso HTTP por nombre (Valida DNS + Nginx + Bridge)
echo -n "   • Test HTTP (Nombre de Dominio): "
HTTP_CODE=$(ip netns exec NS-CLIENT curl -s -o /dev/null -w "%{http_code}" http://web.lab.local)
if [ "$HTTP_CODE" == "200" ]; then
    echo "✅ EXITOSO (HTTP 200)"
else
    echo "❌ FALLIDO (HTTP $HTTP_CODE)"; exit 1
fi

# Prueba C: Conectividad MariaDB (NS -> Host)
echo -n "   • Test DB (SERVICES -> HOST 10.10.100.1): "
if ip netns exec NS-SERVICES mysql -u labuser -predhat -h 10.10.100.1 -e "SELECT 1" labdb >/dev/null 2>&1; then
    echo "✅ EXITOSO"
else
    echo "❌ FALLIDO"; exit 1
fi

# ---------------------------------------------------------------------------
# 2. EXPERIENCIA DE USUARIO (MOTD)
# ---------------------------------------------------------------------------
echo "[2/4] 📝 Configurando banner de bienvenida..."

cat > /etc/motd << 'EOF'
###############################################################################
#             🛡️  BIENVENIDO AL LABORATORIO ROCKY GOLDEN BASE  🛡️             #
###############################################################################
#                                                                             #
#  ARQUITECTURA: Hub & Spoke (Bridge br-lab)                                  #
#  TOPOLOGÍA:                                                                 #
#    - HOST (DB/Gateway) : 10.10.100.1                                        #
#    - NS-SERVICES       : 10.10.100.10 (Nginx + DNS)                         #
#    - NS-CLIENT         : 10.10.100.20 (Resolv vía /etc/netns)               #
#                                                                             #
#  COMANDOS DE EMERGENCIA:                                                    #
#  • systemctl status lab-network   : Verifica el Bridge                      #
#  • systemctl status lab-nginx     : Verifica el Web Server                  #
#                                                                             #
###############################################################################
EOF

# ---------------------------------------------------------------------------
# 3. LIMPIEZA PROFUNDA (SANITIZACIÓN)
# ---------------------------------------------------------------------------
echo "[3/4] 🧹 Limpiando rastros y optimizando espacio..."

dnf clean all
rm -rf /var/cache/dnf
find /var/log -type f -exec truncate -s 0 {} \;
rm -rf /tmp/* /var/tmp/*

# ---------------------------------------------------------------------------
# 4. SELLADO PARA CLONACIÓN
# ---------------------------------------------------------------------------
echo "[4/4] 🔒 Sellando Machine-ID e Historial..."

# Resetear Machine-ID (Vital para que cada clon sea único en red)
truncate -s 0 /etc/machine-id
[ -f /var/lib/dbus/machine-id ] && rm -f /var/lib/dbus/machine-id

# Limpiar historial de comandos
history -c
cat /dev/null > ~/.bash_history

echo ""
echo "===================================================="
echo "🎊 GOLDEN IMAGE FINALIZADA CON ÉXITO"
echo "===================================================="
echo "VM se apagará en 60 segundos. ¡Lista para clonar!"
echo "===================================================="

sleep 60
poweroff