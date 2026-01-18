#!/bin/bash
#==============================================================================
# engine/functions.sh
#==============================================================================
# Funciones auxiliares para el Incident Response Lab Engine
# Refactorizado para bash/libvirt (sin Terraform)
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
select_variant() {
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

    # Seleccionar variante
    VARIANT=$(select_variant "$ROOT_DIR/$LAB_PATH") || return 1

    echo "📍 Variante seleccionada: $VARIANT"

    VM_NAME="lab-${ID,,}-${VARIANT,,}"
    echo "📍 Generando cloud-init para VM '$VM_NAME' con VARIANT='$VARIANT'"
    
    # Generar cloud-init
    CLOUDINIT_DIR=$("$ENGINE_DIR/cloudinit_generator.sh" "$LEVEL" "$ID" "$VARIANT")
    
    # =========================================================================
    # CLONACIÓN CORREGIDA CON APAGADO FUERTE
    # =========================================================================
    echo "📍 Clonando VM del laboratorio '$ID' ($VARIANT) usando libvirt..."
    
    # 1. ASEGURAR VM BASE APAGADA (CRÍTICO)
    echo "💾 Preparando clonación..."
    if virsh domstate rocky9_base 2>/dev/null | grep -q "running"; then
        echo "⚠️  VM base 'rocky9_base' encendida. Forzando apagado..."
        virsh destroy rocky9_base
        sleep 3
        until virsh domstate rocky9_base 2>/dev/null | grep -q "shut off"; do
            echo "⏳ Esperando VM apagada..."
            sleep 2
        done
        echo "✅ VM base completamente apagada"
    fi
    
    # 2. CLONAR CON SINTAXIS CORRECTA
    DISK_PATH="/var/lib/libvirt/images/${VM_NAME}.qcow2"
    SEED_PATH="/var/lib/libvirt/images/${VM_NAME}-seed.iso"
    
    echo "💾 Disco base: /var/lib/libvirt/images/rocky9_base.qcow2"
    echo "💾 Disco destino: $DISK_PATH"
    
    sudo virt-clone \
        --original rocky9_base \
        --name "$VM_NAME" \
        --file "$DISK_PATH=qcow2" \
        --disk "$SEED_PATH,device=cdrom" \
        --auto-mac || {
        echo "💥 ERROR en virt-clone" >&2
        return 1
    }
    
    echo "✅ VM '$VM_NAME' clonada exitosamente"
    echo "🚀 Iniciando VM '$VM_NAME'..."
    virsh start "$VM_NAME" || echo "⚠️ VM iniciada manualmente con virt-manager"
    
    echo "🚀 [assign_lab] >>> COMPLETADO <<<" >&2
}


#==============================================================================
# FUNCIÓN DE EJECUCIÓN DE LAB
#==============================================================================
run_lab() {
    echo "[INFO] run_lab - Usar 'assign_lab' para crear nuevas VMs"
    echo "Para gestionar VMs existentes, usar las opciones del menú principal"
}