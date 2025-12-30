#!/bin/bash
# ============================================================
# RHCSA EX200 – Boot & Recovery
# Slot: 03
# Scenario: /etc/fstab bloqueando el boot
# Nivel: Producción realista
# Author: Jensy Gomez
# ============================================================

set -euo pipefail

# -------------------------------
# Variables
# -------------------------------
VG_NAME="vg_data"
LV_NAME="lv_app"
MNT_POINT="/mnt/fake"
LOG_FILE="/var/log/inject_fstab.log"
TICKET_FILE="/root/TICKET_BOOT_03.txt"

# -------------------------------
# Logging silencioso
# -------------------------------
log_injection() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Inject V3 Boot executed" >> "$LOG_FILE"
}

# -------------------------------
# Preparar mount “falso”
# -------------------------------
# No se crea directorio ni dispositivo: fallará en boot
# Esto simula fstab realista roto en producción

FAKE_UUID=$(uuidgen)

echo "UUID=$FAKE_UUID $MNT_POINT xfs defaults 0 0" >> /etc/fstab
log_injection

# -------------------------------
# Ticket de incidente
# -------------------------------
cat << 'EOF' > "$TICKET_FILE"
==================================================
        INCIDENTE – SISTEMA NO FINALIZA EL ARRANQUE
==================================================

Escenario:
  Tras un reinicio, el sistema queda detenido durante
  el proceso de arranque y no alcanza el estado operativo.

Síntomas observados:
  - multi-user.target no alcanzado
  - Boot interrumpido por error de montaje
  - Mensajes de “cannot find filesystem” o “mount failed”

Tarea:
  1. Identificar qué línea de /etc/fstab provoca el fallo.
  2. Determinar la causa del error (UUID o dispositivo inexistente).
  3. Corregir /etc/fstab para permitir arranque normal.
  4. Verificar persistencia tras reboot.
  5. Confirmar que todos los demás mounts y servicios funcionan.

Restricciones:
  - No eliminar servicios ni desinstalar paquetes
  - Mantener consistencia del sistema
  - Evitar pérdida de datos

Criterios de validación:
  ✓ Boot completo sin bloqueos
  ✓ multi-user.target alcanzado
  ✓ Montajes válidos y persistentes
  ✓ Datos existentes intactos

==================================================
EOF

chmod 600 "$TICKET_FILE"

echo "Ticket V3 generado en $TICKET_FILE"
echo "==> Setup V3 (fstab roto) completado"
exit 0
