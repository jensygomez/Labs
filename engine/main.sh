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
#
#------------------------------------------------------------------------------
# VARIABLES GLOBALES DEL MOTOR
#------------------------------------------------------------------------------
#
# VARIABLES DE PATH Y ENTORNO
# --------------------------
# ENGINE_ROOT
#   Directorio raíz del Incident Response Lab Engine.
#
# PROJECT_ROOT
#   Raíz del proyecto de laboratorios (scenarios, imágenes, cloud-init).
#
# LAB_DB_FILE
#   Archivo de base de datos de laboratorios (formato delimitado por '|').
#
# SCENARIOS_ROOT
#   Directorio base que contiene todos los escenarios de laboratorio.
#
# VARIABLES DE CONTROL DEL MENÚ
# ----------------------------
# MENU_OPTION
#   Opción numérica seleccionada por el usuario en el menú principal.
#
# SELECTED_LEVEL
#   Nivel lógico elegido por el usuario:
#   Junior | Pleno | Senior
#
# VARIABLES DE SELECCIÓN DE LABORATORIO
# ------------------------------------
# AVAILABLE_LABS
#   Lista de laboratorios disponibles filtrados por nivel seleccionado.
#
# MIN_USES
#   Número mínimo de usos detectado entre los labs del nivel seleccionado.
#
# CANDIDATE_LABS
#   Laboratorios empatados con el menor número de usos.
#
# SELECTED_LAB_ID
#   Identificador del laboratorio seleccionado (ej: J01, P02, S01).
#
# SELECTED_LAB_PATH
#   Ruta base del laboratorio seleccionado
#   (ej: scenarios/junior/J01).
#
# VARIABLES DE VARIANTES
# ---------------------
# AVAILABLE_VARIANTS
#   Variantes disponibles dentro del laboratorio seleccionado.
#
# SELECTED_VARIANT
#   Variante elegida aleatoriamente para ejecución.
#
# VARIABLES DE PERSISTENCIA
# ------------------------
# UPDATED_USES
#   Nuevo contador de usos del laboratorio seleccionado.
#
# DB_UPDATE_STATUS
#   Resultado de la operación de actualización de la base de datos.
#
# VARIABLES DE EJECUCIÓN
# ---------------------
# LAB_TYPE
#   Tipo de artefacto a ejecutar (cloudinit, terraform, etc.).
#
# EXECUTION_ARTIFACT
#   Archivo final ejecutado por el motor (lab + variante).
#
#------------------------------------------------------------------------------
# NOTA ARQUITECTÓNICA
# ------------------
# Este bloque define el contrato global del motor.
# Cualquier nueva funcionalidad debe reutilizar estas variables o introducir
# nuevas únicamente si representan estado global real.
#------------------------------------------------------------------------------


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

    if [[ ! -f "$DB_FILE" || ! -s "$DB_FILE" ]]; then
        echo "❌ ERROR: Base de datos inexistente o vacía: $DB_FILE" >&2
        exit 1
    fi

    while IFS='|' read -r ID LEVEL PATH USES; do
        [[ "$ID" == "ID" ]] && continue   # saltar header si existe
        LABS+=("$ID|$LEVEL|$PATH|$USES")
    done < "$DB_FILE"

    echo "✅ DB cargada: ${#LABS[@]} laboratorios"
}


#==============================================================================
# FUNCION DE LECTURA DE LAB POR NIVEL Y SELECCIÓN
#==============================================================================
select_lab_by_level() {
    local LEVEL="$1"
    local FILTERED=()
    local MIN_USES=""
    local CANDIDATES=()

    # 1. Filtrar por nivel
    for LAB in "${LABS[@]}"; do
        IFS='|' read -r ID LAB_LEVEL PATH USES <<< "$LAB"
        [[ "$LAB_LEVEL" == "$LEVEL" ]] && FILTERED+=("$LAB")
    done

    if [[ ${#FILTERED[@]} -eq 0 ]]; then
        echo "❌ No hay labs para nivel $LEVEL" >&2
        return 1
    fi

    # 2. Encontrar mínimo USES
    for LAB in "${FILTERED[@]}"; do
        IFS='|' read -r _ _ _ USES <<< "$LAB"
        [[ -z "$MIN_USES" || "$USES" -lt "$MIN_USES" ]] && MIN_USES="$USES"
    done

    # 3. Candidatos con mínimo USES
    for LAB in "${FILTERED[@]}"; do
        IFS='|' read -r _ _ _ USES <<< "$LAB"
        [[ "$USES" -eq "$MIN_USES" ]] && CANDIDATES+=("$LAB")
    done

    # 4. Elegir aleatoriamente
    SELECTED_LAB="${CANDIDATES[RANDOM % ${#CANDIDATES[@]}]}"

    IFS='|' read -r ID LAB_LEVEL PATH USES <<< "$SELECTED_LAB"

    echo "🎯 Lab seleccionado: $ID (USES=$USES → $((USES+1)))"

    # 5. Incrementar USES y persistir
    update_lab_uses "$ID" "$((USES+1))"

    # 6. Devolver datos
    echo "$ID|$LAB_LEVEL|$PATH"
}


#==============================================================================
# FUNCION DE ACTUALIZACIÓN DE LAB USAGES
#==============================================================================
update_lab_uses() {
    local TARGET_ID="$1"
    local NEW_USES="$2"
    local TMP_DB

    TMP_DB="$(mktemp)"

    while IFS='|' read -r ID LEVEL PATH USES; do
        if [[ "$ID" == "$TARGET_ID" ]]; then
            echo "$ID|$LEVEL|$PATH|$NEW_USES" >> "$TMP_DB"
        else
            echo "$ID|$LEVEL|$PATH|$USES" >> "$TMP_DB"
        fi
    done < "$DB_FILE"

    mv "$TMP_DB" "$DB_FILE"
}



#==============================================================================
# FUNCION DE SELECCIÓN DE VARIANTE
#==============================================================================
select_variant() {
    local LAB_PATH="$1"
    local VARIANT_DIR="$ROOT_DIR/$LAB_PATH"

    if [[ ! -d "$VARIANT_DIR" ]]; then
        echo "❌ No existe directorio de variantes: $VARIANT_DIR" >&2
        return 1
    fi

    mapfile -t VARIANTS < <(ls "$VARIANT_DIR"/variant_*.yml 2>/dev/null)

    if [[ ${#VARIANTS[@]} -eq 0 ]]; then
        echo "❌ No hay variantes en $VARIANT_DIR" >&2
        return 1
    fi

    echo "${VARIANTS[RANDOM % ${#VARIANTS[@]}]}"
}

#==============================================================================
# FUNCION DE ASIGNACIÓN DE LAB
#==============================================================================
assign_lab() {
    local LEVEL="$1"

    load_db

    LAB_INFO="$(select_lab_by_level "$LEVEL")" || return 1
    IFS='|' read -r ID LAB_LEVEL LAB_PATH <<< "$LAB_INFO"

    VARIANT="$(select_variant "$LAB_PATH")" || return 1

    run_lab "$ID" "$VARIANT" "$LAB_LEVEL"
}

#==============================================================================
# FUNCION DE EJECUCIÓN DE LAB
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
    
    echo ""
    echo "➡️  Entrando en gestión directa de la VM..."
    sleep 1

    manage_single_vm "$VM_NAME"

} 


#==============================================================================
# FUNCION DEL MENÚ PRINCIPAL
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
# FUNCION DE ESTADO DE VMs
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
# FUNCION DE GESTIÓN DE VMs
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


#==============================================================================
# FUNCION DE GESTIÓN DE VM INDIVIDUAL
#==============================================================================
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
        5) cleanup_vm "$VM_NAME" "/mnt/vms/labs/tmp/${VM_NAME}.qcow2"; 
           echo "✅ VM eliminada COMPLETAMENTE"; sleep 1 ;;
        0) return ;;
        *) echo "❌ Opción inválida" ;;
    esac
    
    manage_single_vm "$VM_NAME"
}





#==============================================================================
# FUNCION DEL MENÚ POST-LAB
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
# FUNCION DE LIMPIEZA DE VM
#==============================================================================
cleanup_vm() {
    local VM_NAME="${1:-}" VM_IMG="${2:-}"
    
    [[ -z "$VM_NAME" ]] && { echo "❌ VM_NAME requerido"; return 1; }
    
    echo "🧹 ELIMINANDO VM: $VM_NAME"
    
    # 1. DESTROZAR
    sudo virsh destroy "$VM_NAME" 2>/dev/null || true
    
    # 2. ELIMINAR DEFINICIÓN + STORAGE
    sudo virsh undefine "$VM_NAME" --remove-all-storage 2>/dev/null || true
    
    # 3. BORRAR OVERLAY MANUAL
    [[ -n "$VM_IMG" && -f "$VM_IMG" ]] && rm -f "$VM_IMG" && echo "   ✅ Disco: $VM_IMG"
    
    # 4. LIMPIAR CACHÉ LIBVIRT (¡EL CLAVE!)
    sudo virsh pool-refresh default 2>/dev/null || true
    sudo systemctl reload libvirtd 2>/dev/null || true
    
    echo "✅ VM $VM_NAME ELIMINADA + caché limpiado"
}




#==============================================================================
# INICIO
#==============================================================================
echo "🚀 Incident Response Lab Engine v1.1"
load_db
while true; do main_menu; done
