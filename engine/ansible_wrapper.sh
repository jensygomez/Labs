#!/bin/bash
# ==============================================================================
# Ansible Wrapper - Incident Labs Engine
# ------------------------------------------------------------------------------
# Centraliza ejecución de Ansible
# - Validaciones
# - Selección de variante
# - Logging
# - Punto único de ejecución
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------
# Parámetros de entrada
# ------------------------------------------------------------------
PLAYBOOK="$1"
INVENTORY="$2"

ENGINE_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$ENGINE_DIR/logs"
RUN_ID="$(date +%Y%m%d_%H%M%S)"
VARIANTS=(A B C D)

mkdir -p "$LOG_DIR"

# ------------------------------------------------------------------
# Validaciones
# ------------------------------------------------------------------
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

# ------------------------------------------------------------------
# Selección de variante (oculta al operador)
# ------------------------------------------------------------------
VARIANT="${VARIANT:-${VARIANTS[$RANDOM % ${#VARIANTS[@]}]}}"

# ------------------------------------------------------------------
# Logging
# ------------------------------------------------------------------
LOG_FILE="$LOG_DIR/ansible_${RUN_ID}.log"

echo "[WRAPPER] Ejecutando playbook: $PLAYBOOK"
echo "[WRAPPER] Variante seleccionada: (oculta)"
echo "[WRAPPER] Log: $LOG_FILE"
echo

# ------------------------------------------------------------------
# Ejecución
# ------------------------------------------------------------------
ansible-playbook \
    -i "$INVENTORY" \
    "$PLAYBOOK" \
    -e "variant=$VARIANT" \
    | tee "$LOG_FILE"

RC=${PIPESTATUS[0]}

# ------------------------------------------------------------------
# Resultado
# ------------------------------------------------------------------
if [[ "$RC" -ne 0 ]]; then
    echo
    echo "[WRAPPER] ERROR: Fallo durante ejecución de Ansible"
    exit "$RC"
fi

echo
echo "[WRAPPER] Ejecución completada correctamente"
exit 0
