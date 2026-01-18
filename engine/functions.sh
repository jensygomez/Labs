#!/bin/bash
#==============================================================================
# engine/functions.sh
#==============================================================================
# Funciones auxiliares para el Incident Response Lab Engine
# Refactorizado para cloud-init + Terraform
#==============================================================================

#==============================================================================
# VALIDACIÓN DEL ENTORNO
#==============================================================================
check_env() {
    echo "[DEBUG] check_env ejecutándose..." >&2
    [[ -z "${PATH:-}" ]] && {
        echo "❌ PATH CORRUPTO — abortando" >&2
        exit 99
    }
    echo "[DEBUG] check_env completado OK" >&2
}

#==============================================================================
# SELECCIÓN ALEATORIA DE VARIANTE
#==============================================================================
select_variant() {  # ← CAMBIÉ EL NOMBRE de select_variant_file
    local LAB_DIR="$1/cloudinit"
    shopt -s nullglob
    local VARIANTS=("$LAB_DIR"/V*)
    shopt -u nullglob

    if [[ ${#VARIANTS[@]} -eq 0 ]]; then
        echo "❌ No hay variantes en $LAB_DIR" >&2
        return 1
    fi

    # Devuelve solo el nombre de la variante (ej: V01)
    local SELECTED_VARIANT
    SELECTED_VARIANT="$(basename "${VARIANTS[RANDOM % ${#VARIANTS[@]}]}")"
    echo "$SELECTED_VARIANT"
}

#==============================================================================
# ASIGNACIÓN DE LAB
#==============================================================================
assign_lab() {
    check_env

    local LEVEL="$1"
    LEVEL="${LEVEL//[[:space:]]/}"
    local ORIGINAL_LEVEL="$LEVEL"

    echo "🚀 [assign_lab] >>> INICIANDO <<<" >&2

    # Selección del lab
    LAB_INFO=$(select_lab_by_level "$ORIGINAL_LEVEL")
    local RET_CODE=$?
    if [[ $RET_CODE -ne 0 ]]; then
        echo "💥 ERROR en select_lab_by_level" >&2
        echo "$LAB_INFO" >&2
        return 1
    fi

    IFS='|' read -r ID LAB_LEVEL LAB_PATH <<< "$LAB_INFO"
    [[ -n "$ID" && -n "$LAB_PATH" ]] || { echo "💥 LAB_PATH vacío"; return 1; }

    echo "📍 LAB seleccionado: ID='$ID', LEVEL='$LAB_LEVEL', PATH='$LAB_PATH'"

    # ✅ CAMBIO: Llamar a select_variant (no select_variant_file)
    VARIANT=$(select_variant "$ROOT_DIR/$LAB_PATH") || return 1

    echo "📍 Variante seleccionada: $VARIANT"

    # ✅ CAMBIO: Eliminar el loop de roles (1 LAB = 1 VM según cloudinit_generator.sh)
    VM_NAME="lab-${ID,,}-${VARIANT,,}"
    
    echo "📍 Generando cloud-init para VM '$VM_NAME' con VARIANT='$VARIANT'"
    
    # ✅ CAMBIO: Llamar a cloudinit_generator.sh sin parámetro ROLE
    "$ENGINE_DIR/cloudinit_generator.sh" "$LEVEL" "$ID" "$VARIANT"

    # =========================================================================
    # Levantar las VMs con Terraform
    # =========================================================================
    echo "📍 Levantando VM del laboratorio '$ID' ($VARIANT) usando Terraform..."
    
    # ✅ CAMBIO: Pasar la VARIANT a terraform_runner.sh (3er parámetro)
    "$ENGINE_DIR/terraform_runner.sh" "$LEVEL" "$ID" "$VARIANT" "/mnt/vms/rocky-ir-base-junior-v1.qcow2"

    echo "🚀 [assign_lab] >>> COMPLETADO <<<" >&2
}

#==============================================================================
# EJEMPLO DE FUNCIÓN DE EJECUCIÓN DE LAB
#==============================================================================
run_lab() {
    # En este flujo Terraform tomará la carpeta /mnt/vms/labs/tmp/cloudinit/$VM_NAME
    echo "[INFO] run_lab ahora depende de Terraform para aprovisionar VMs"
    echo "Use terraform_runner.sh pasando los VM_NAME generados"
}