#!/bin/bash
# ============================================================
# RHCSA EX200 – Boot & Recovery
# Slot: 01
# Scenario: Default target incorrecto
# ============================================================

set -euo pipefail

TARGET_INCORRECTO="rescue.target"
TARGET_CORRECTO="multi-user.target"
LOG_FILE="/var/log/inject_boot.log"

# -------------------------------
# Función para mostrar el ticket
# -------------------------------
show_ticket() {
    cat << 'EOF'
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
}


# -------------------------------
# Logging (seguro: no falla aunque no tenga permisos)
# -------------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') - inject_V1 Boot ejecutado" >> "$LOG_FILE" 2>/dev/null || true

# -------------------------------
# Mostrar ticket inmediatamente
# -------------------------------
show_ticket

# -------------------------------
# Inyección simulada/del fallo
# -------------------------------
echo "[DEBUG] Inyectando fallo..."
echo "[DEBUG] Target actual: $(systemctl get-default)"

# Aquí ya puedes descomentar sin miedo
systemctl set-default "$TARGET_INCORRECTO"

echo "[DEBUG] Default target cambiado a $TARGET_INCORRECTO"
echo "[DEBUG] inject_V1 terminado correctamente"
exit 0