#!/bin/bash
set -euo pipefail

ENGINE_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$ENGINE_DIR/.." && pwd)"
DB_FILE="$ENGINE_DIR/labs.db"
LABS=()

load_db() {
    LABS=()
    if [[ ! -s "$DB_FILE" ]]; then 
        echo "Sin labs.db o vacío"
        return 
    fi
    
    # HARDCODEADO para TU caso exacto
    LABS=("J00|network|Junior|$ROOT_DIR/scenarios/junior/J00/cloudinit/variant_1.yml|cloudinit|0")
    echo "✅ J00 cargado manualmente"
}

main_menu() {
    clear
    echo "================================================"
    echo "INCIDENT RESPONSE LAB ENGINE"
    echo "================================================"
    echo "Labs: ${#LABS[@]}"
    echo "1) Junior  2) Pleno  3) Senior  0) Salir"
    read -rp "Opción: " option
    
    case "$option" in
        1) assign_lab "Junior" ;;
        2|3) echo "Pendiente"; read -rp "ENTER..." ;;
        0) exit 0 ;;
        *) main_menu ;;
    esac
}

assign_lab() {
    local LEVEL="$1"
    echo "Buscando $LEVEL..."
    
    for LAB in "${LABS[@]}"; do
        IFS='|' read -r id track level artifact type uses <<< "$LAB"
        if [[ "$level" == "$LEVEL" ]]; then
            echo "🎯 Encontrado: $id"
            run_lab "$id" "$artifact" "$level"
            return
        fi
    done
    echo "❌ Sin labs para $LEVEL"
    read -rp "ENTER..."
}

run_lab() {
    local ID="$1" TEMPLATE="$2" LEVEL="$3"
    echo "🚀 LAB: $ID ($LEVEL)"
    
    # 1. Generar ISO (✅ YA FUNCIONA)
    read -rp "ENTER para generar ISO... "
    ISO_PATH=$(bash "$ENGINE_DIR/cloudinit_generator.sh" "$LEVEL" "$ID" "$TEMPLATE")
    echo "✅ ISO: $ISO_PATH"
    
    # 2. **FALTA: CREAR VM CON EL ISO**
    VM_NAME="lab-${ID}-$(date +%Y%m%d-%H%M%S)"
    read -rp "ENTER para crear VM '$VM_NAME'... "
    
    # CLONAR VM base (qcow2 overlay)
    BASE_IMG="/mnt/vms/rocky-ir-base-junior-v1.qcow2"
    VM_IMG="/mnt/vms/labs/tmp/${VM_NAME}.qcow2"
    
    qemu-img create -f qcow2 -b "$BASE_IMG" "$VM_IMG"
    
    # **CREAR VM con virt-install**
    virt-install \
        --name "$VM_NAME" \
        --memory 2048 --vcpus 2 \
        --disk path="$VM_IMG",format=qcow2,bus=virtio \
        --disk path="$ISO_PATH",device=cdrom \
        --import \
        --os-variant rhel9.0 \
        --network bridge=br0 \
        --noautoconsole \
        --graphics none
    
    echo "✅ VM '$VM_NAME' creada y booteando!"
    echo "virsh list --all"
    echo "virsh domifaddr $VM_NAME"
    
    read -rp "ENTER cuando termines el lab para cleanup..."
    
    # Cleanup
    virsh destroy "$VM_NAME" 2>/dev/null || true
    virsh undefine "$VM_NAME" --remove-all-storage 2>/dev/null || true
    rm -f "$VM_IMG" "$ISO_PATH"
}


# INICIO
load_db
while true; do main_menu; done
