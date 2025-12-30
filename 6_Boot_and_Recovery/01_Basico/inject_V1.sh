#!/bin/bash
# ============================================================
# RHCSA EX200 – Boot & Recovery
# Slot: 01
# Scenario: Default target incorrecto
# Impact: Sistema no alcanza estado operativo normal
# ============================================================

set -euo pipefail

TARGET_INCORRECTO="rescue.target"
LOG_FILE="/var/log/inject_boot.log"
TICKET_FILE="/home/student/lab_ticket.txt"

echo "=== [INJECT_V1] Inicio ==="

# ------------------------------------------------
# 1. Crear ticket SIEMPRE (antes de romper nada)
# ------------------------------------------------
cat << 'EOF' > "$TICKET_FILE"
==================================================
        INCIDENTE – SISTEMA NO ARRANCA NORMALMENTE
==================================================

Escenario:
  Tras un reinicio programado, el sistema no alcanza
  el estado operativo esperado.

Síntomas reportados:
  - El sistema arranca, pero no presenta login normal
  - No se levantan servicios de usuario
  - No hay errores de hardware reportados

Tarea del administrador:
  1. Identificar por qué el sistema no alcanza el estado normal.
  2. Corregir la configuración de arranque.
  3. Verificar que el sistema arranca correctamente tras reinicio.

Restricciones:
  - No reinstalar el sistema
  - No modificar servicios innecesarios

Criterios de validación:
  ✓ El default target es el correcto
  ✓ El sistema arranca en modo multi-user
  ✓ El cambio persiste tras reboot

==================================================
EOF

chmod 644 "$TICKET_FILE"
chown student:student "$TICKET_FILE"

# Mostrar ticket en stdout (para el host)
echo
echo "=== TICKET DEL LABORATORIO ==="
cat "$TICKET_FILE"
echo "=== FIN DEL TICKET ==="
echo

# ------------------------------------------------
# 2. Inyectar el fallo REAL (sin validaciones)
# ------------------------------------------------
echo "[INJECT] Cambiando default target a $TARGET_INCORRECTO"

systemctl set-default "$TARGET_INCORRECTO"

# ------------------------------------------------
# 3. Logging silencioso
# ------------------------------------------------
echo "$(date '+%F %T') - Inject V1 aplicado: default=$TARGET_INCORRECTO" \
    >> "$LOG_FILE"

echo "=== [INJECT_V1] Finalizado ==="
exit 0
