#!/bin/bash

#==============================================================================
# IMPORTAR CONSTANTES DESDE MAIN.SH
#==============================================================================
# Estas variables ya están exportadas desde main.sh
# ENGINE_DIR, ROOT_DIR, DB_FILE, LABS

#==============================================================================
# FUNCIONES QUE NECESITAN ACCEDER A LAS FUNCIONES DE MAIN.SH
#==============================================================================
# Para llamar funciones de main.sh, necesitamos que estén definidas primero
# O podemos declararlas aquí también



#==============================================================================
# FUNCION DE ASIGNACIÓN DE LAB (CON CHECKPOINTS)
#==============================================================================
assign_lab() {

    echo "🚀 [assign_lab] >>> INICIANDO <<<" >&2
    
    local LEVEL="$1"
    echo "📍 [1/7] Recibido parámetro LEVEL='$LEVEL'" >&2
    
    # Limpiar espacios
    LEVEL="${LEVEL//[[:space:]]/}"
    echo "📍 [2/7] LEVEL limpio = '$LEVEL'" >&2
    
    local ORIGINAL_LEVEL="$LEVEL"

    echo "📍 [3/7] Llamando load_db()..." >&2

    echo "📍 [3/7] load_db() TERMINADO - LABS=${#LABS[@]}" >&2
    
    echo "📍 [4/7] === LLAMANDO select_lab_by_level '$ORIGINAL_LEVEL' ===" >&2
    
    # ✅ FIX 1: NOMBRE CORRECTO + ORIGINAL_LEVEL
    LAB_INFO=$(select_lab_by_level "$ORIGINAL_LEVEL")
    


    local RET_CODE=$?
    
    # ✅ FIX 2: Usa LAB_INFO (no LLAB_INFO)
    echo "📍 [4/7] select_lab_by_level RETORNÓ CODE=$RET_CODE" >&2
    echo "📍 [4/7] LAB_INFO capturado = '$LAB_INFO'" >&2
    
    if [[ $RET_CODE -ne 0 ]]; then
        echo "💥 [4/7] ERROR en select_lab_by_level" >&2
        echo "💥 [4/7] Salida fue: $LAB_INFO" >&2
        return 1
    fi
    echo "✅ [4/7] === select_lab_by_level COMPLETADO ===" >&2

    # ✅ FIX 3: Ya existe LAB_INFO válido
    echo "📍 [5/7] Parseando LAB_INFO='$LAB_INFO'" >&2
    IFS='|' read -r ID LAB_LEVEL LAB_PATH <<< "$LAB_INFO"
    echo "📍 [5/7] EXTRAÍDO → ID='$ID' LAB_LEVEL='$LAB_LEVEL' LAB_PATH='$LAB_PATH'" >&2
    
    if [[ -z "$ID" || -z "$LAB_PATH" ]]; then
        echo "💥 [5/7] ERROR: ID o LAB_PATH vacío" >&2
        return 1
    fi
    echo "✅ [5/7] Parseo correcto" >&2

    echo "📍 [6/7] Llamando select_variant('$LAB_PATH')" >&2
    VARIANT="$(select_variant "$LAB_PATH")"
    local RET_VARIANT=$?
    echo "📍 [6/7] select_variant RETORNÓ CODE=$RET_VARIANT" >&2
    echo "📍 [6/7] VARIANT='$VARIANT'" >&2
    
    if [[ $RET_VARIANT -ne 0 || -z "$VARIANT" ]]; then
        echo "💥 [6/7] ERROR en select_variant" >&2
        return 1
    fi

    echo "📍 [7/7] 🚀 LLAMANDO run_lab('$ID', '$VARIANT', '$LAB_LEVEL')" >&2
    run_lab "$ID" "$VARIANT" "$LAB_LEVEL"
    
    echo "🚀 [assign_lab] >>> COMPLETADO <<<" >&2
}


#==============================================================================
# FUNCION DE SELECCIÓN DE VARIANTE
#==============================================================================
select_variant() {
    local LAB_PATH="$1"
    local VARIANT_DIR="$ROOT_DIR/$LAB_PATH/cloudinit"
    local -a VARIANTS=()

    if [[ ! -d "$VARIANT_DIR" ]]; then
        echo "❌ No existe cloudinit dir: $VARIANT_DIR" >&2
        return 1
    fi

    shopt -s nullglob
    VARIANTS=("$VARIANT_DIR"/V*/)
    shopt -u nullglob

    if [[ ${#VARIANTS[@]} -eq 0 ]]; then
        echo "❌ No hay variantes Vxx en $VARIANT_DIR" >&2
        return 1
    fi

    # stdout LIMPIO → solo el nombre de la variante
    basename "${VARIANTS[RANDOM % ${#VARIANTS[@]}]}"
}



#==============================================================================
# FUNCION DE EJECUCIÓN DE LAB
#==============================================================================
run_lab() {
    echo "=== ENTRANDO A run_lab ===" >&2
    echo "Parámetros recibidos: ID='$1', TEMPLATE='$2', LEVEL='$3'" >&2
    echo "[DEBUG] ENGINE_DIR='$ENGINE_DIR'" >&2
    echo "[DEBUG] cloudinit_generator.sh path: $ENGINE_DIR/cloudinit_generator.sh" >&2
    
    echo "[DEBUG] PATH=$PATH"
    command -v bash date mkdir qemu-img virt-install || true
    local ID="$1" TEMPLATE="$2" LEVEL="$3"
    
    echo "🚀 LAB: $ID ($LEVEL)"
    echo "═══════════════════════"
    
    # 1. ISO
    echo "🔨 [1/5] ISO..."
    local ISO_PATH=$(bash "$ENGINE_DIR/cloudinit_generator.sh" "$LEVEL" "$ID" "$TEMPLATE")
    echo "✅ [1/5] $ISO_PATH"
    
    # 2. VM
    local VM_NAME="lab-${ID}-$(date +%Y%m%d-%H%M%S)"
    local VM_IMG="/mnt/vms/labs/tmp/${VM_NAME}.qcow2"
    
    echo "🔧 [2/5] Overlay..."
    mkdir -p /mnt/vms/labs/tmp
    qemu-img create -f qcow2 -F qcow2 -b "/mnt/vms/rocky-ir-base-junior-v1.qcow2" "$VM_IMG"
    echo "✅ [2/5] $VM_IMG"
    
    # 3. VM
    echo "🎮 [3/5] Creando VM..."
    sudo virt-install \
        --name "$VM_NAME" \
        --memory 2048 --vcpus 2 \
        --disk path="$VM_IMG",format=qcow2,bus=virtio \
        --disk path="$ISO_PATH",device=cdrom \
        --import \
        --os-variant rhel9.0 \
        --boot uefi \
        --network network=default \
        --graphics vnc,listen=0.0.0.0 \
        --video virtio \
        --noautoconsole || echo "⚠️  Warning normal"
    
    echo "✅ [3/5] VM '$VM_NAME' CREADA!"
    
    # 4. Espera arranque
    sleep 5
    STATE=$(sudo virsh domstate "$VM_NAME" 2>/dev/null || echo "starting")
    if [[ "$STATE" == "running" ]]; then
        echo "✅ [4/5] VM RUNNING!"
    else
        echo "🚀 [4/5] Estado: $STATE (arrancando...)"
    fi
    
    # 5. INFO CONEXIÓN + VOLVER AL MENÚ (SIN CLEANUP)
    echo ""
    echo "🔗 ===== VM ACTIVA Y LISTA ====="
    echo "VM: $VM_NAME"
    echo "VNC: $(sudo virsh vncdisplay "$VM_NAME" 2>/dev/null || echo 'starting...')"
    IP=$(sudo virsh domifaddr "$VM_NAME" 2>/dev/null | awk 'NR>1{print $4}' || echo 'booting...')
    echo "IP: $IP"
    echo ""
    echo "💡 VM queda CORRIENDO → Opción 5) Gestión VMs para administrar"
    echo "💡 ISO queda en: $(dirname "$ISO_PATH")"
    echo ""
    
    echo ""
    echo "➡️  Entrando en gestión directa de la VM..."
    sleep 1

    manage_single_vm "$VM_NAME"
}


