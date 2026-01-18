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
    echo "📍 Creando lab '$VM_NAME'..."
    
    # Generar cloud-init
    CLOUDINIT_DIR=$("$ENGINE_DIR/cloudinit_generator.sh" "$LEVEL" "$ID" "$VARIANT")
    
    # =========================================================================
    # CLONACIÓN OPTIMIZADA (BYPASS SNAPSHOTS)
    # =========================================================================
    
    # 1. ASEGURAR VM BASE APAGADA
    if virsh domstate rocky9_base 2>/dev/null | grep -q "running"; then
        echo "⚠️  VM base encendida. Apagando..."
        virsh destroy rocky9_base
        sleep 2
    fi
    
    # 2. LIMPIAR VM anterior si existe
    virsh destroy "$VM_NAME" 2>/dev/null || true
    virsh undefine "$VM_NAME" --remove-all-storage 2>/dev/null || true
    sudo rm -f "/var/lib/libvirt/images/${VM_NAME}.qcow2"*
    sudo rm -f "/var/lib/libvirt/images/${VM_NAME}-seed.iso"
    
    # 3. LINKED CLONE DIRECTO (BYPASS SNAPSHOTS)
    BASE_DISK="/mnt/vms/rocky9_base.qcow2"  # DISCO BASE REAL
    DISK_PATH="/var/lib/libvirt/images/${VM_NAME}.qcow2"
    
    echo "📍 Creando linked clone directo..."
    sudo qemu-img create -f qcow2 -F qcow2 -b "$BASE_DISK" "$DISK_PATH"
    
    # 4. CLONAR DEFINICIÓN DE VM
    echo "📍 Clonando definición de VM..."
    sudo virt-clone \
        --original rocky9_base \
        --name "$VM_NAME" \
        --file "$DISK_PATH" \
        --preserve-data || {
        echo "💥 Fallback: clon simple..."
        sudo virt-clone --original rocky9_base --name "$VM_NAME" --file "$DISK_PATH=qcow2"
    }
    
    # 5. CLOUD-INIT ISO
    SEED_PATH="/var/lib/libvirt/images/${VM_NAME}-seed.iso"
    if [[ -f "$CLOUDINIT_DIR"/*.iso ]]; then
        echo "📍 Copiando cloud-init ISO..."
        sudo cp "$CLOUDINIT_DIR"/*.iso "$SEED_PATH"
        sudo chown libvirt-qemu:libvirt "$SEED_PATH"
        sudo virsh attach-disk "$VM_NAME" "$SEED_PATH" hdc \
            --type cdrom --mode readonly --config --persistent 2>/dev/null || \
            echo "⚠️  CDROM ya adjunto o error al adjuntar"
    fi
    
    # 6. INICIAR VM
    echo "📍 Iniciando VM '$VM_NAME'..."
    virsh start "$VM_NAME" || {
        echo "⚠️  Error al iniciar automáticamente. Inicia manualmente con:"
        echo "    virsh start $VM_NAME"
        echo "    virt-manager &"
    }
    
    echo "✅ VM '$VM_NAME' creada exitosamente (~128KB)!"
    echo "🔗 Accede con: ssh admin@<ip-vm> (password: admin)"
    echo "🚀 [assign_lab] >>> COMPLETADO <<<" >&2
}



#==============================================================================
# FUNCIÓN DE EJECUCIÓN DE LAB
#==============================================================================
run_lab() {
    echo "[INFO] run_lab - Usar 'assign_lab' para crear nuevas VMs"
    echo "Para gestionar VMs existentes, usar las opciones del menú principal"
}