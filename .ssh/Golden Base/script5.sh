#!/bin/bash
# ============================================================================
# PROYECTO: Automatización de Golden Base Image (Rocky Linux)
# SCRIPT:   5 de 5 - Auditoría y Sellado Final (Final Hardening & Cleanup)
# ============================================================================
#
# ⏪ RETROSPECTIVA TÉCNICA (SCRIPT 4 - ORCHESTRATION):
#   - Servicios Nginx y Dnsmasq operando en 'NS-SERVICES'.
#   - Orquestación mediante Systemd (lab-nginx y lab-dnsmasq) validada.
#
# 🎯 OBJETIVO DE ESTA FASE (SCRIPT 5):
#   Control de calidad final (QA) y sanitización. Transforma la VM en una 
#   "Golden Image" profesional lista para ser clonada o distribuida.
# ============================================================================
set -e

echo "=== 🏁 SCRIPT 5: AUDIT LAYER & GOLDEN IMAGE SEALING (BRIDGE MODE) ==="
echo "📅 Fecha: $(date)"

# ---------------------------------------------------------------------------
# 1. AUDITORÍA DE CONECTIVIDAD (PRUEBAS DE INTEGRACIÓN)
# ---------------------------------------------------------------------------
echo "[1/4] 🧪 Ejecutando pruebas de certificación de red..."

# Prueba A: Resolución DNS (Capa 7 -> Capa 3)
echo -n "   • Test DNS (web.lab.local): "
if ip netns exec NS-CLIENT nslookup web.lab.local 10.10.100.10 >/dev/null 2>&1; then
    echo "✅ EXITOSO"
else
    echo "❌ FALLIDO"
fi

# Prueba B: Acceso Web desde el Cliente al Servidor a través del Bridge
echo -n "   • Test HTTP (CLIENT -> BRIDGE -> SERVICES): "
HTTP_CODE=$(ip netns exec NS-CLIENT curl -s -o /dev/null -w "%{http_code}" http://10.10.100.10)
if [ "$HTTP_CODE" == "200" ]; then
    echo "✅ EXITOSO (HTTP 200)"
else
    echo "❌ FALLIDO (HTTP $HTTP_CODE)"
fi

# Prueba C: Conexión DB desde el Namespace de Servicios al Host
echo -n "   • Test DB (SERVICES -> HOST 10.10.100.1): "
if ip netns exec NS-SERVICES mysql -u labuser -predhat -h 10.10.100.1 -e "SELECT 1" labdb >/dev/null 2>&1; then
    echo "✅ EXITOSO"
else
    echo "❌ FALLIDO"
fi

# ---------------------------------------------------------------------------
# 2. EXPERIENCIA DE USUARIO (MOTD ACTUALIZADO)
# ---------------------------------------------------------------------------
echo "[2/4] 📝 Configurando interfaz de bienvenida..."

cat > /etc/motd << 'EOF'

###############################################################################
#             🛡️  BIENVENIDO AL LABORATORIO ROCKY GOLDEN BASE  🛡️             #
###############################################################################
#                                                                             #
#  ARQUITECTURA: Hub & Spoke (Bridge Centralizado br-lab)                     #
#  TOPOLOGÍA:                                                                 #
#    - HOST (DB/Gateway) : 10.10.100.1                                        #
#    - NS-SERVICES       : 10.10.100.10 (Nginx + DNS)                         #
#    - NS-CLIENT         : 10.10.100.20                                       #
#                                                                             #
#  COMANDOS ÚTILES:                                                           #
#  • lab-net-status    : Verifica el Bridge y los Namespaces.                 #
#  • ns-client         : Entra al Shell del Cliente.                          #
#  • ns-services       : Entra al Shell de Servicios.                         #
#                                                                             #
###############################################################################
EOF

# ---------------------------------------------------------------------------
# 3. LIMPIEZA PROFUNDA (SANITIZACIÓN)
# ---------------------------------------------------------------------------
echo "[3/4] 🧹 Limpiando rastros de aprovisionamiento..."

# Limpieza de paquetes y caché
dnf clean all
rm -rf /var/cache/dnf

# Vaciado de Logs (sin borrar archivos para preservar permisos)
find /var/log -type f -exec truncate -s 0 {} \;
echo "   ✅ Logs vaciados."

# Eliminación de temporales
rm -rf /tmp/* /var/tmp/*

# ---------------------------------------------------------------------------
# 4. SELLADO PARA CLONACIÓN (SEALING)
# ---------------------------------------------------------------------------
echo "[4/4] 🔒 Sellando imagen para distribución..."

# Resetear Machine-ID para evitar conflictos de IP/DHCP en clones
truncate -s 0 /etc/machine-id
[ -f /var/lib/dbus/machine-id ] && rm -f /var/lib/dbus/machine-id

# Limpieza total de historiales
history -c
cat /dev/null > ~/.bash_history
cat /dev/null > /home/student/.bash_history 2>/dev/null || true

echo ""
echo "===================================================="
echo "🎊 GOLDEN IMAGE FINALIZADA EXITOSAMENTE"
echo "===================================================="
echo "   1. RED: Bridge Centralizado (br-lab)"
echo "   2. SERVICIOS: Aislados y Orquestados"
echo "   3. HARDENING: Logs y Machine-ID limpios"
echo ""
echo "VM se apagará en 60 segundos. ¡Listo para clonar!"
echo "===================================================="

sleep 60
poweroff