#!/bin/bash
# ============================================================
# RHCSA EX200 – Boot & Recovery
# Slot: 01
# Scenario: Default target incorrecto
# Impact: Sistema no alcanza estado operativo normal
# Author: Jensy Gomez
# Version: Standalone – Ticket first
# ============================================================

set -euo pipefail

# -------------------------------
# Variables internas
# -------------------------------
TARGET_INCORRECTO="rescue.target"
TARGET_CORRECTO="multi-user.target"

LOG_FILE="/var/log/inject_boot.log"
DEBUG_LOG="/tmp/inject_V1.debug"
TICKET_FILE="/home/student/lab_ticket.txt"

# Redirigir stdout y stderr a debug log
exec > >(tee -a "$DEBUG_LOG") 2>&1

echo "=== [DEBUG] Inicio inject_V1 ==="
date
hostname
whoami
pwd

# -------------------------------
# Función de logging silencioso
# -------------------------------
log_injection() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Inject V1 Boot executed" >> "$LOG_FILE"
}

# -------------------------------
# Validaciones básicas
# -------------------------------
echo "[STEP 1] Verificando existencia de systemctl..."
if ! command -v systemctl &>/dev/null; then
    echo "[ERROR] systemctl no encontrado"
    exit 1
fi

echo "[STEP 2] Comprobando target a inyectar: $TARGET_INCORRECTO"
if ! systemctl list-unit-files | grep -q "^${TARGET_INCORRECTO}"; then
    echo "[ERROR] Target $TARGET_INCORRECTO no existe en el sistema"
    exit 1
fi

# -------------------------------
# Creación del ticket
# -------------------------------
echo "[STEP 3] Creando ticket en $TICKET_FILE..."
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
echo "[OK] Ticket creado correctamente"

# -------------------------------
# Mostrar ticket antes de cualquier cambio
# -------------------------------
echo
echo "=== [TICKET] Inicio ==="
cat "$TICKET_FILE"
echo "=== [TICKET] Fin ==="
echo

# -------------------------------
# Logging
# -------------------------------
log_injection

# -------------------------------
# Inyección del fallo (después de mostrar ticket)
# -------------------------------
echo "[STEP 4] Cambiando default target a $TARGET_INCORRECTO..."
systemctl set-default "$TARGET_INCORRECTO" && echo "[OK] Default target cambiado a $TARGET_INCORRECTO"

# -------------------------------
# Estado final para verificación
# -------------------------------
echo "[STEP 5] Estado final del default target:"
systemctl get-default

echo "=== [DEBUG] Fin inject_V1 ==="
