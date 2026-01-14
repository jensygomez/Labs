#!/bin/bash
#==============================================================================
# INCIDENT RESPONSE LAB ENGINE v1.1
# =================================
# Plataforma automatizada para labs RHCSA/RHCE Incident Response
# Creada para jensy@mx (MX Linux + KVM/QEMU + Rocky Linux 9)
#
# FLUJO COMPLETO:
#   1. Genera ISO cloud-init con escenario específico
#   2. Crea overlay qcow2 desde imagen base rocky-ir-base-junior-v1.qcow2
#   3. Lanza VM con EFI+VNC usando virt-install
#   4. Usuario conecta via virt-manager/VNCviewer
#   5. MENU POST-LAB: Mantener/Eliminar/Status VM
#   6. Cleanup automático o manual
#
# REQUISITOS:
#   - KVM/libvirt corriendo (sudo systemctl status libvirtd)
#   - Imagen base: /mnt/vms/rocky-ir-base-junior-v1.qcow2 (31GB)
#   - Network default activa (virbr0 UP)
#   - Usuario en grupos: kvm,libvirt
#   - Paquetes: virt-install, qemu-img, genisoimage, tigervnc-viewer
#
# NUEVO v1.1: MENU POST-LAB con opciones Mantener/Eliminar/Status
#==============================================================================

set -euo pipefail

#==============================================================================
# CONSTANTES GLOBALES
#==============================================================================
ENGINE_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$ENGINE_DIR/.." && pwd)"
DB_FILE="$ENGINE_DIR/labs.db"
LABS=()

#==============================================================================
# FUNCIONES DE CARGA DE LABS
#==============================================================================
load_db() {
    LABS=()
    
    # PRIORIDAD 1: Si NO hay DB, usar HARDCODEADO (TU CASO)
    if [[ ! -s "$DB_FILE" ]]; then 
        echo "⚠️  Sin labs.db o vacío - usando J00 hardcodeado"
        LABS=("J00|network|Junior|$ROOT_DIR/scenarios/junior/J00/cloudinit/variant_1.yml|cloudinit|0")
        echo "✅ ${#LABS[@]} lab cargado: J00 (Junior)"
        return 0
    fi
    
    # PRIORIDAD 2: Si hay DB pero está vacío, igual HARDCODEAR
    if [[ ! -s "$DB_FILE" ]]; then
        echo "⚠️  DB existe pero vacío - usando J00 hardcodeado"
        LABS=("J00|network|Junior|$ROOT_DIR/scenarios/junior/J00/cloudinit/variant_1.yml|cloudinit|0")
        echo "✅ ${#LABS[@]} lab cargado: J00 (Junior)"
        return 0
    fi
    
    # PRIORIDAD 3: Leer desde SQLite (futuro)
    echo "📖 Leyendo labs desde SQLite: $DB_FILE"
    # TODO: Implementar sqlite3 query cuando tengas estructura DB
    # mapfile -t LABS < <(sqlite3 "$DB_FILE" "SELECT id||'|'||track||'|'||level||'|'||artifact||'|'||type||'|'||uses FROM labs;")
    
    # FALLBACK: Si SQLite falla, HARDCODEAR J00
    if [[ ${#LABS[@]} -eq 0 ]]; then
        echo "⚠️  SQLite vacío/falló - usando J00 hardcodeado"
        LABS=("J00|network|Junior|$ROOT_DIR/scenarios/junior/J00/cloudinit/variant_1.yml|cloudinit|0")
    fi
    
    echo "✅ ${#LABS[@]} labs totales cargados"
    printf '%s\n' "${LABS[@]}" | head -3  # Debug: muestra primeros 3
}

#==============================================================================
# INTERFAZ PRINCIPAL
#==============================================================================
main_menu() {
    clear
    echo "================================================"
    echo "INCIDENT RESPONSE LAB ENGINE v1.1"
    echo "================================================"
    echo "Labs: ${#LABS[@]} | Base VM: rocky-ir-base-junior-v1.qcow2"
    echo ""
    echo "1) Junior    2) Pleno    3) Senior"
    echo "4) Estado VMs  5) Gestión VMs  0) Salir"
    read -rp "Opción: " option
    
    case "$option" in
        1) assign_lab "Junior" ;;
        2) assign_lab "Pleno" ;;
        3) assign_lab "Senior" ;;
        4) show_vm_status ;;
        5) manage_vms ;;
        0) echo "👋 ¡Hasta luego!"; exit 0 ;;
        *) echo "❌ Opción inválida"; sleep 1; main_menu ;;
    esac
}

#==============================================================================
# ASIGNADOR DE LABS
#==============================================================================
assign_lab() {
    local LEVEL="$1"
    echo "🔍 Buscando $LEVEL..."
    
    for LAB in "${LABS[@]}"; do
        IFS='|' read -r id track level artifact type uses <<< "$LAB"
        if [[ "$level" == "$LEVEL" ]]; then
            echo "🎯 $id ($track)"
            run_lab "$id" "$artifact" "$level"
            return 0
        fi
    done
    echo "❌ Sin labs $LEVEL"
    read -rp "ENTER..."
}

#==============================================================================
# ESTADO DE VMs
#==============================================================================
show_vm_status() {
    clear
    echo "📊 ESTADO VMs (libvirt)"
    echo "======================"
    sudo virsh list --all 2>/dev/null | cat || echo "❌ Error libvirt"
    echo ""
    echo "Redes:"
    virsh net-list --all 2>/dev/null | head -5
    echo ""
    echo "Base: $(ls -lh /mnt/vms/rocky-ir-base-junior-v1.qcow2 2>/dev/null || echo 'NO ENCONTRADA')"
    read -rp "ENTER..."
}

#==============================================================================
# GESTIÓN DE VMs (NUEVA v1.1)
#==============================================================================
manage_vms() {
    clear
    echo "🔧 GESTIÓN DE VMs"
    echo "=================="
    
    # Filtrar solo VMs de labs (lab-*)
    local LAB_VMS=()
    mapfile -t LAB_VMS < <(sudo virsh list --all --name 2>/dev/null | grep '^lab-' || true)
    
    if [[ ${#LAB_VMS[@]} -eq 0 ]]; then
        echo "✅ No hay VMs de labs activas"
        read -rp "ENTER..."
        return
    fi
    
    echo "VMs de labs encontradas: ${#LAB_VMS[@]}"
    echo ""
    for i in "${!LAB_VMS[@]}"; do
        local VM="${LAB_VMS[$i]}"
        local STATE=$(sudo virsh domstate "$VM" 2>/dev/null || echo "unknown")
        local IP=$(sudo virsh domifaddr "$VM" 2>/dev/null | awk 'NR>1{print $4}' || echo "no-ip")
        printf "%d) %s [%-9s] IP:%s\n" $((i+1)) "$VM" "$STATE" "$IP"
    done
    
    echo ""
    echo "0) Volver"
    read -rp "Opción: " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -le ${#LAB_VMS[@]} ]]; then
        local VM="${LAB_VMS[$((choice-1))]}"
        manage_single_vm "$VM"
    fi
}

manage_single_vm() {
    local VM_NAME="$1"
    clear
    echo "🔧 VM: $VM_NAME"
    echo "================"
    
    STATE=$(sudo virsh domstate "$VM_NAME" 2>/dev/null || echo "unknown")
    IP=$(sudo virsh domifaddr "$VM_NAME" 2>/dev/null | awk 'NR>1{print $4}' || echo "no-ip")
    
    echo "Estado: $STATE | IP: $IP"
    echo ""
    echo "1) Console VNC     2) IP detallada"
    echo "3) Reiniciar       4) Parar"
    echo "5) Eliminar VM     0) Volver"
    read -rp "Opción: " opt
    
    case "$opt" in
        1) echo "VNC: $(sudo virsh vncdisplay "$VM_NAME")"; read -rp "ENTER..." ;;
        2) sudo virsh domifaddr "$VM_NAME" 2>/dev/null || echo "Sin IP"; read -rp "ENTER..." ;;
        3) sudo virsh reboot "$VM_NAME"; echo "Reiniciando..."; sleep 2 ;;
        4) sudo virsh shutdown "$VM_NAME" || sudo virsh destroy "$VM_NAME"; echo "Parando..." ;;
        5) cleanup_vm "$VM_NAME"; echo "✅ VM eliminada"; sleep 1 ;;
        0) return ;;
        *) echo "❌ Opción inválida" ;;
    esac
    
    manage_single_vm "$VM_NAME"
}


#==============================================================================
# MOTOR CORE DE LABS v1.4 (VM QUEDA ACTIVA)
#==============================================================================
run_lab() {
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
    
    read -rp "ENTER para MENÚ PRINCIPAL (VM sigue activa)..."
    
    echo "✅ Lab $ID completado - VM '$VM_NAME' en Gestión VMs"
}  # ← FIN - SIN CLEANUP



#==============================================================================
# MENÚ POST-LAB (NUEVA FUNCIÓN v1.1)
#==============================================================================
post_lab_menu() {
    local VM_NAME="$1" ISO_PATH="$2" VM_IMG="$3"
    
    while true; do
        clear
        echo "🎓 LAB $VM_NAME COMPLETADO"
        echo "═══════════════════════════"
        
        STATE=$(sudo virsh domstate "$VM_NAME" 2>/dev/null || echo "unknown")
        IP=$(sudo virsh domifaddr "$VM_NAME" 2>/dev/null | awk 'NR>1{print $4}' || echo "no-ip")
        
        echo "Estado: $STATE | IP: $IP"
        echo "VNC: $(sudo virsh vncdisplay "$VM_NAME" 2>/dev/null || echo "no-vnc")"
        echo ""
        echo "1) Usar VM más tiempo     2) Eliminar VM ahora"
        echo "3) Parar VM (mantener)    4) Reiniciar VM"
        echo "5) Gestión completa VMs   0) Volver menú principal"
        echo ""
        read -rp "Opción: " choice
        
        case "$choice" in
            1) echo "✅ Sigue usando la VM"; echo "Pulsa ENTER cuando termines"; read -rp ""; continue ;;
            2) cleanup_vm "$VM_NAME" "$VM_IMG"; rm -f "$ISO_PATH"; return 0 ;;
            3) sudo virsh shutdown "$VM_NAME" 2>/dev/null || sudo virsh destroy "$VM_NAME"; echo "✅ VM parada (archivada)"; return 0 ;;
            4) sudo virsh reboot "$VM_NAME"; echo "🔄 Reiniciando..."; sleep 3; continue ;;
            5) manage_vms; continue ;;
            0) return 1 ;;  # Volver a menú principal
            *) echo "❌ Opción inválida"; sleep 1; continue ;;
        esac
    done
}

#==============================================================================
# CLEANUP
#==============================================================================
cleanup_vm() {
    local VM_NAME="${1:-}"      # VM_NAME (obligatorio)
    local VM_IMG="${2:-}"       # VM_IMG (opcional)
    
    # Validación estricta
    [[ -z "$VM_NAME" ]] && { 
        echo "❌ ERROR: VM_NAME requerido" 
        return 1 
    }
    
    echo "🧹 Cleanup VM: '$VM_NAME'"
    
    # 1. Detener VM si está corriendo
    sudo virsh destroy "$VM_NAME" 2>/dev/null || true
    
    # 2. Eliminar definición + storage
    sudo virsh undefine "$VM_NAME" --remove-all-storage 2>/dev/null || true
    
    # 3. Borrar overlay qcow2 (si se pasa)
    if [[ -n "$VM_IMG" && -f "$VM_IMG" ]]; then
        rm -f "$VM_IMG" && echo "   ✅ Borrado: $VM_IMG"
    fi
    
    echo "✅ Cleanup VM completado"
}


#==============================================================================
# INICIO
#==============================================================================
echo "🚀 Incident Response Lab Engine v1.1"
load_db
while true; do main_menu; done
