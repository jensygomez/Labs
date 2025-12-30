#!/bin/bash
# ============================================================
# RHCSA EX200 – Boot & Recovery
# Slot: 01
# Scenario: Default target incorrecto
# Impact: Sistema no alcanza estado operativo normal
# Author: Jensy Gomez
# Version: Standalone – Reproducible – Silencioso
# ============================================================

set -euo pipefail

# -------------------------------
# Variables internas
# -------------------------------
TARGET_INCORRECTO="rescue.target"
TARGET_CORRECTO="multi-user.target"

LOG_FILE="/var/log/inject_boot.log"
TICKET_FILE="/home/student/lab_ticket.txt"

# -------------------------------
# Función de logging silencioso
# -------------------------------
log_injection() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Inject V1 Boot executed" >> "$LOG_FILE"
}

# -------------------------------
# Validaciones básicas
# -------------------------------
if ! command -v systemctl &>/dev/null; then
    exit 1
fi

if ! systemctl list-unit-files | grep -q "^${TARGET_INCORRECTO}"; then
    exit 1
fi

# -------------------------------
# Creación del ticket antes de cualquier cambio
# -------------------------------
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

# Ajustar permisos y propiedad para que main.sh y el estudiante puedan leerlo
chmod 644 "$TICKET_FILE"
chown student:student "$TICKET_FILE"

# -------------------------------
# Logging
# -------------------------------
log_injection

# -------------------------------
# Inyección del fallo
# -------------------------------
# Cambiar el default target sin afectar el target activo
systemctl set-default "$TARGET_INCORRECTO"

# -------------------------------
# Salida limpia
# -------------------------------
exit 0
