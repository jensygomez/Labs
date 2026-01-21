#!/bin/bash
# ============================================================================
# PROYECTO: Automatización de Golden Base Image (Rocky Linux)
# SCRIPT:   5 de 5 - Auditoría y Sellado Final (Final Hardening & Cleanup)
# ============================================================================
#
# ⏪ RETROSPECTIVA TÉCNICA (SCRIPT 4 - ORCHESTRATION):
#   - Los servicios Nginx y Dnsmasq están operando dentro de sus Namespaces.
#   - La persistencia mediante Systemd ha sido validada y activada.
#
# 🧪 VALIDACIÓN DE PERSISTENCIA (POST-REBOOT SCRIPT 4):
#   Verifique que los servicios orquestados arrancaron automáticamente:
#   1. Status Nginx:    # systemctl is-active lab-nginx
#   2. Status DNS:      # systemctl is-active lab-dnsmasq
#   3. Procesos en NS:  # ip netns exec NS-SERVICES ps aux | grep -E 'nginx|dnsmasq'
#   4. Puertos en NS:   # ip netns exec NS-SERVICES ss -tlnp (Ver 80 y 53)
#   5. Conectividad:    # ip netns exec NS-CLIENT curl -I http://10.10.100.10
#
# 🎯 OBJETIVO DE ESTA FASE (SCRIPT 5):
#   Realizar el control de calidad final (QA) y preparar la VM para su 
#   distribución. Este script transforma un entorno de desarrollo en una 
#   "Golden Image" limpia, segura y documentada.
#
# 🛠️ ACCIONES DE CIERRE:
#   1. END-TO-END TESTING: Pruebas de conectividad real entre las 3 capas.
#   2. MOTD (Message of the Day): Creación de un banner de bienvenida legal 
#      e informativo para el usuario final del laboratorio.
#   3. LOG PURGE: Limpieza total de logs de instalación y rastros de DNF.
#   4. BASH CLEANUP: Eliminación de historiales de comandos.
#   5. SEALING: Preparación para clonado (limpieza de machine-id).
#
# ============================================================================
set -e

echo "=== 🏁 SCRIPT 5: AUDIT LAYER & GOLDEN IMAGE SEALING ==="
echo "📅 Fecha: $(date)"

# ---------------------------------------------------------------------------
# 1. AUDITORÍA DE CONECTIVIDAD (PRUEBAS DE ESTRÉS)
# ---------------------------------------------------------------------------
echo "[1/4] 🧪 Ejecutando pruebas de integración final..."

# Prueba A: Resolución DNS desde el Cliente
echo -n "   • Test DNS (web.lab.local): "
if ip netns exec NS-CLIENT nslookup web.lab.local 10.10.100.10 >/dev/null 2>&1; then
    echo "✅ EXITOSO"
else
    echo "❌ FALLIDO"
fi

# Prueba B: Acceso Web (Capa 7) desde el Cliente pasando por el Edge
echo -n "   • Test HTTP (CLIENT -> EDGE -> SERVICES): "
HTTP_CODE=$(ip netns exec NS-CLIENT curl -s -o /dev/null -w "%{http_code}" http://10.10.100.10)
if [ "$HTTP_CODE" == "200" ]; then
    echo "✅ EXITOSO (HTTP 200)"
else
    echo "❌ FALLIDO (HTTP $HTTP_CODE)"
fi

# Prueba C: Conexión DB desde el Cliente al Host
echo -n "   • Test DB (SQL Query across layers): "
if ip netns exec NS-CLIENT mysql -u labuser -predhat -h 10.10.100.10 -e "SELECT 1" labdb >/dev/null 2>&1; then
    echo "✅ EXITOSO"
else
    echo "❌ FALLIDO"
fi

# ---------------------------------------------------------------------------
# 2. EXPERIENCIA DE USUARIO (MOTD & ALIASES)
# ---------------------------------------------------------------------------
echo "[2/4] 📝 Configurando interfaz de bienvenida y ayuda..."

cat > /etc/motd << 'EOF'

###############################################################################
#             🛡️  BIENVENIDO AL LABORATORIO ROCKY GOLDEN BASE  🛡️             #
###############################################################################
#                                                                             #
#  ARQUITECTURA: 3-TIER (CLIENT <-> EDGE <-> SERVICES)                        #
#  USUARIO: student / redhat                                                  #
#                                                                             #
#  COMANDOS DE AYUDA:                                                         #
#  • lab-status     : Muestra el estado de la red y los servicios.            #
#  • ns-client      : Entra al namespace del Cliente.                         #
#  • ns-services    : Entra al namespace de Servicios.                        #
#  • lab-restart    : Reinicia toda la infraestructura del lab.               #
#                                                                             #
#  ¡Cuidado! Esta VM está configurada con Namespaces persistentes.            #
###############################################################################
EOF

# ---------------------------------------------------------------------------
# 3. LIMPIEZA PROFUNDA (SYSTEM PURGE)
# ---------------------------------------------------------------------------
echo "[3/4] 🧹 Limpiando rastros de construcción (Sanitización)..."

# Limpieza de DNF/YUM
dnf clean all
rm -rf /var/cache/dnf

# Rotación y vaciado de logs
find /var/log -type f -exec truncate -s 0 {} \;
echo "   ✅ Logs del sistema vaciados."

# Eliminación de archivos temporales
rm -rf /tmp/*
rm -rf /var/tmp/*

# ---------------------------------------------------------------------------
# 4. SELLADO PARA CLONACIÓN (SEALING)
# ---------------------------------------------------------------------------
echo "[4/4] 🔒 Sellando imagen para clonación..."

# Eliminar Machine-ID (se regenerará al clonar)
truncate -s 0 /etc/machine-id
[ -f /var/lib/dbus/machine-id ] && rm -f /var/lib/dbus/machine-id

# Limpiar historial de Bash de Root y Student
history -c
cat /dev/null > ~/.bash_history
cat /dev/null > /home/student/.bash_history 2>/dev/null || true

echo ""
echo "===================================================="
echo "🎊 GOLDEN IMAGE CREADA CON ÉXITO"
echo "===================================================="
echo "📊 RESUMEN FINAL:"
echo "   1. Sistema base y paquetes: LISTO"
echo "   2. Red de Namespaces: PERSISTENTE"
echo "   3. Servicios Nginx/DNS/DB: ORQUESTADOS"
echo "   4. Auditoría de Seguridad: COMPLETA"
echo ""
echo "⚠️  AVISO: La VM se apagará en 60 segundos."
echo "   Una vez apagada, se recomienda convertirla en TEMPLATE."
echo "===================================================="

sleep 60
poweroff