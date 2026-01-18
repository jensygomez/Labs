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
    # CLONACIÓN VIRT-CLONE SINTAXIS 100% CORRECTA
    # =========================================================================

    echo "📍 Clonando VM '$VM_NAME' (LINKED CLONE)..."
    
    # 1. LIMPIAR VM anterior si existe
    virsh destroy "$VM_NAME" 2>/dev/null || true
    virsh undefine "$VM_NAME" 2>/dev/null || true
    sudo rm -f "/var/lib/libvirt/images/${VM_NAME}"*
    
    # 2. LINKED CLONE (2 SEGUNDOS ⚡)
    DISK_PATH="/var/lib/libvirt/images/${VM_NAME}.qcow2"
    sudo virt-clone \
        --original rocky9_base \
        --name "$VM_NAME" \
        --file "$DISK_PATH"
    
    # 3. ADJUNTAR CLOUD-INIT ISO AUTOMÁTICO
    SEED_PATH="/var/lib/libvirt/images/${VM_NAME}-seed.iso"
    sudo cp "$CLOUDINIT_DIR"/*.iso "$SEED_PATH"
    sudo virsh attach-disk "$VM_NAME" "$SEED_PATH" hdc \
        --type cdrom --mode readonly --config
    
    echo "✅ J01-V01 preparado. Iniciando..."
    virsh start "$VM_NAME"
}





#==============================================================================
# FUNCIÓN DE EJECUCIÓN DE LAB
#==============================================================================
run_lab() {
    echo "[INFO] run_lab - Usar 'assign_lab' para crear nuevas VMs"
    echo "Para gestionar VMs existentes, usar las opciones del menú principal"
}