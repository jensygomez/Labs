#!/bin/bash
# /home/jensy/Labs/engine/ansible_wrapper.sh
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
# Configuración de rutas (PORTABLE)
# ------------------------------------------------------------------------------
ENGINE_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$ENGINE_DIR/.." && pwd)"

# Exportar variables para inventory.yml
export LAB_ENGINE_DIR="$ENGINE_DIR"
export LAB_ROOT_DIR="$ROOT_DIR"

LOG_DIR="$ENGINE_DIR/logs"
RUN_ID="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$LOG_DIR/ansible_${RUN_ID}.log"

mkdir -p "$LOG_DIR"

# ------------------------------------------------------------------------------
# Parámetros
# ------------------------------------------------------------------------------
PLAYBOOK="$1"
INVENTORY="$2"

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
# Información de depuración
# ------------------------------------------------------------------------------
clear
echo "========================================"
echo " Ansible Incident Lab Execution"
echo "========================================"
echo
echo "Playbook : $PLAYBOOK"
echo "Inventory: $INVENTORY"
echo "Log file : $LOG_FILE"
echo "Engine Dir: $LAB_ENGINE_DIR"
echo "Root Dir  : $LAB_ROOT_DIR"
echo "Clave SSH : $LAB_ROOT_DIR/.ssh/id_rhcsalabs"
echo

# Verificar que la clave SSH existe (solo warning)
if [[ ! -f "$LAB_ROOT_DIR/.ssh/id_rhcsalabs" ]]; then
    echo "[WRAPPER] WARNING: Clave SSH no encontrada en: $LAB_ROOT_DIR/.ssh/id_rhcsalabs"
    echo "[WRAPPER] Verifique inventory.yml si falla la conexión"
fi

# ------------------------------------------------------------------------------
# Ejecución
# ------------------------------------------------------------------------------
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
    echo "[WRAPPER] ERROR: Fallo durante ejecución de Ansible (código: $RC)"
    echo "[WRAPPER] Revise el log: $LOG_FILE"
    exit "$RC"
fi

echo
echo "[WRAPPER] Ejecución completada correctamente"
exit 0