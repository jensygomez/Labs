#!/bin/bash
#==============================================================================
# engine/functions.sh
# Incident Response Lab Engine — Orquestador
# MODELO DEFINITIVO:
#   - Base disk: rocky9_base.qcow2 (INMUTABLE)
#   - 1 LAB = 1 VM
#   - Overlay qcow2 + cloud-init
#   - Toda la creación real ocurre en vm_cloner.sh
#==============================================================================

#==============================================================================
# VALIDACIÓN DEL ENTORNO
#==============================================================================
check_env() {
    echo "[DEBUG] check_env ejecutándose..." >&2

    [[ -z "${PATH:-}" ]] && {
        echo "❌ PATH corrupto — abortando" >&2
        exit 99
    }

    for cmd in virsh qemu-img genisoimage; do
        command -v "$cmd" &>/dev/null || {
            echo "❌ Dependencia faltante: $cmd" >&2
            exit 1
        }
    done

    echo "[DEBUG] check_env completado OK" >&2
}

#==============================================================================
# SELECCIÓN ALEATORIA DE VARIANTE
#==============================================================================
select_variant() {
    local LAB_DIR="$1/cloudinit"

    shopt -s nullglob
    local VARIANTS=("$LAB_DIR"/V*)
    shopt -u nullglob

    [[ ${#VARIANTS[@]} -eq 0 ]] && {
        echo "❌ No hay variantes en $LAB_DIR" >&2
        return 1
    }

    echo "$(basename "${VARIANTS[RANDOM % ${#VARIANTS[@]}]}")"
}

#==============================================================================
# ASIGNACIÓN DE LAB (FUNCIÓN CLAVE)
#==============================================================================
assign_lab() {
    check_env

    local LEVEL="$1"
    LEVEL="${LEVEL//[[:space:]]/}"

    echo "🚀 [assign_lab] >>> INICIANDO <<<" >&2

    #------------------------------------------------------------
    # Seleccionar LAB por nivel
    #------------------------------------------------------------
    local LAB_INFO
    LAB_INFO="$(select_lab_by_level "$LEVEL")" || {
        echo "💥 ERROR en select_lab_by_level" >&2
        return 1
    }

    IFS='|' read -r ID LAB_LEVEL LAB_PATH <<< "$LAB_INFO"
    [[ -z "$ID" || -z "$LAB_PATH" ]] && {
        echo "💥 LAB inválido" >&2
        return 1
    }

    echo "📍 LAB seleccionado: ID='$ID', LEVEL='$LAB_LEVEL', PATH='$LAB_PATH'"

    #------------------------------------------------------------
    # Seleccionar variante
    #------------------------------------------------------------
    local VARIANT
    VARIANT="$(select_variant "$ROOT_DIR/$LAB_PATH")" || return 1
    echo "📍 Variante seleccionada: $VARIANT"

    #------------------------------------------------------------
    # NOMBRE DE VM
    #------------------------------------------------------------
    local VM_NAME="lab-${ID,,}-${VARIANT,,}"
    echo "📍 Creando lab '$VM_NAME'..."

    #------------------------------------------------------------
    # Generar cloud-init (SIN DEBUG)
    #------------------------------------------------------------
    local CLOUDINIT_DIR
    CLOUDINIT_DIR="$("$ENGINE_DIR/cloudinit_generator.sh" \
        "$(echo "$LAB_LEVEL" | tr '[:upper:]' '[:lower:]')" "$ID" "$VARIANT")"

    [[ -d "$CLOUDINIT_DIR" ]] || {
        echo "💥 Cloud-init no generado: $CLOUDINIT_DIR" >&2
        ls -la "$CLOUDINIT_DIR" 2>/dev/null || echo "Directorio NO existe"
        return 1
    }

    #------------------------------------------------------------
    # CREACIÓN REAL DE LA VM
    #------------------------------------------------------------
    echo "📍 Invocando vm_cloner.sh..."
    sudo "$ENGINE_DIR/vm_cloner.sh" "$VM_NAME" "$CLOUDINIT_DIR"

    echo "✅ VM '$VM_NAME' creada correctamente"
    echo "🚀 [assign_lab] >>> VM LISTA <<<" >&2

    #------------------------------------------------------------
    # 🎯 NUEVO: GESTIÓN AUTOMÁTICA DE VM
    #------------------------------------------------------------
    echo ""
    echo "🎮 ENTRANDO A GESTIÓN VM AUTOMÁTICA..."
    echo "======================================"
    manage_single_vm "$VM_NAME"
    
    echo "✅ Lab completado. Volviendo al menú principal..."
}

#==============================================================================
# FUNCIÓN DE EJECUCIÓN DE LAB
#==============================================================================
run_lab() {
    echo "[INFO] Usar 'assign_lab <nivel>' para crear nuevos laboratorios"
}
