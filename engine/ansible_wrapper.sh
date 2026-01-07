#!/bin/bash
# ==============================================================================
# Ansible Wrapper - Incident Labs Engine
# ------------------------------------------------------------------------------
# Rol:
# - Punto único de ejecución de Ansible
# - Validaciones
# - Logging por ejecución
# - Totalmente agnóstico al lab
#
# NO:
# - No selecciona variantes
# - No interpreta lógica de escenarios
#
# Autor: Jensy - 2026
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Parámetros
# ------------------------------------------------------------------------------
PLAYBOOK="$1"
INVENTORY="$2"

ENGINE_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$ENGINE_DIR/logs"
RUN_ID="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$LOG_DIR/ansible_${RUN_ID}.log"

mkdir -p "$LOG_DIR"

# ------------------------------------------------------------------------------
# Validaciones
# ------------------------------------------------------------------------------
[[ -f "$PLAYBOOK" ]] || {
    echo "[WRAPPER] ERROR: Playbook no encontrado: $PLAYBOOK"
    exit 1
}

[[ -f "$INVENTORY" ]] || {
    echo "[WRAPPER] ERROR: Inventory no encontrado: $INVENTORY"
    exit 1
}

command -v ansible-playbook >/dev/null || {
    echo "[WRAPPER] ERROR: ansible-playbook no está instalado"
    exit 1
}

# ------------------------------------------------------------------------------
# Ejecución
# ------------------------------------------------------------------------------
clear
echo "========================================"
echo " Ansible Incident Lab Execution"
echo "========================================"
echo
echo "Playbook : $PLAYBOOK"
echo "Inventory: $INVENTORY"
echo "Log file : $LOG_FILE"
echo

ansible-playbook \
    -i "$INVENTORY" \
    "$PLAYBOOK" \
    | tee "$LOG_FILE"

RC=${PIPESTATUS[0]}

# ------------------------------------------------------------------------------
# Resultado
# ------------------------------------------------------------------------------
if [[ "$RC" -ne 0 ]]; then
    echo
    echo "[WRAPPER] ERROR: Fallo durante ejecución de Ansible"
    exit "$RC"
fi

echo
echo "[WRAPPER] Ejecución completada correctamente"
exit 0
