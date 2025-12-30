#!/bin/bash
# ============================================================
# RHCSA EX200 – Boot & Recovery
# Slot: 01 (BÁSICO)
# Scenario: Default target incorrecto
# Impact: Sistema no alcanza estado operativo normal
# Author: Jensy Gomez
# ============================================================

set -euo pipefail

# ------------------------------------------------------------
# Variables
# ------------------------------------------------------------
TARGET_INCORRECTO="rescue.target"
LOG_FILE="/var/log/inject_boot.log"
TICKET_FILE="/home/student/lab_ticket.txt"

# ------------------------------------------------------------
# 1. CREAR TICKET (SIEMPRE)
# ------------------------------------------------------------
cat << 'EOF' > "$TICKET_FILE"
==================================================
        INCIDENTE – SISTEMA NO ARRANCA EN MODO NORMAL
==================================================

Escenario:
  Tras un reinicio programado, el sistema no alcanza
  el estado operativo esperado. No hay servicios
  disponibles para los usuarios.

Síntomas observados:
  - El sistema arranca, pero no presenta login normal
  - No se levantan servicios de aplicación
  - No se reportan errores de hardware ni filesystem

Tarea:
  1. Determinar por qué el sistema no alcanza el estado operativo normal.
  2. Restaurar el comportamiento correcto de arranque.
  3. Verificar que el cambio sea persistente tras reinicio.

Restricciones:
  - No reinstalar el sistema
  - No modificar servicios innecesarios
  - No afectar datos existentes

Criterios de validación:
  ✓ El sistema arranca en multi-user.target
  ✓ El default target es el correcto
  ✓ El cambio persiste tras reboot
==================================================
EOF

chmod 644 "$TICKET_FILE"
chown student:student "$TICKET_FILE"

# ------------------------------------------------------------
# 2. MOSTRAR TICKET EN STDOUT (PARA EL HOST)
# ------------------------------------------------------------
echo
echo "=== TICKET DEL LABORATORIO ==="
cat "$TICKET_FILE"
echo "=== FIN DEL TICKET ==="
echo

# ------------------------------------------------------------
# 3. INYECTAR FALLO (SIN BLOQUEAR EL LAB)
# ------------------------------------------------------------
if systemctl list-unit-files | grep -q "^${TARGET_INCORRECTO}"; then
    systemctl set-default "$TARGET_INCORRECTO"
else
    # Fallback seguro (si rescue.target no existe)
    systemctl set-default multi-user.target
fi

# ------------------------------------------------------------
# 4. LOG SILENCIOSO
# ------------------------------------------------------------
echo "$(date '+%F %T') - inject_V1 ejecutado" >> "$LOG_FILE"

exit 0
