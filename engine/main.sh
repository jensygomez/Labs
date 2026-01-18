# /labs/engine/main.sh

#!/bin/bash
set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

#==============================================================================
# CONSTANTES GLOBALES
#==============================================================================
ENGINE_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$ENGINE_DIR/.." && pwd)"
DB_FILE="$ENGINE_DIR/labs.db"
BASE_IMAGE="/mnt/vms/rocky9_base.qcow2" 
LABS=()

# Exportar también esta variable
export BASE_IMAGE

#==============================================================================
# EXPORTAR CONSTANTES A FUNCTIONS.SH
#==============================================================================
export ENGINE_DIR ROOT_DIR DB_FILE LABS

#==============================================================================
# CARGA DE FUNCIONES
#==============================================================================
source "$ENGINE_DIR/functions.sh"  # ← ESTA LÍNEA ES CRÍTICA

#==============================================================================
# FUNCIONES DE CARGA DE LABS
#==============================================================================
load_db() {
    LABS=()

    # --- Validación del archivo DB ---
    if [[ ! -f "$DB_FILE" || ! -s "$DB_FILE" ]]; then
        echo "❌ ERROR: Base de datos inexistente o vacía: $DB_FILE" >&2
        exit 1
    fi

    # --- Carga segura de registros ---
    while IFS='|' read -r ID LEVEL LAB_PATH USES; do
        # Saltar header
        [[ "$ID" == "ID" ]] && continue

        # --- Validaciones estrictas ---
        [[ -z "$ID" || -z "$LEVEL" || -z "$LAB_PATH" || -z "$USES" ]] && {
            echo "❌ DB corrupta: campos vacíos → '$ID|$LEVEL|$LAB_PATH|$USES'" >&2
            exit 2
        }

        [[ ! "$USES" =~ ^[0-9]+$ ]] && {
            echo "❌ DB corrupta: USES no numérico para $ID → '$USES'" >&2
            exit 3
        }

        [[ "$LAB_PATH" == *":"* ]] && {
            echo "❌ DB corrupta: LAB_PATH parece PATH del sistema para $ID → '$LAB_PATH'" >&2
            exit 4
        }

        LABS+=("$ID|$LEVEL|$LAB_PATH|$USES")

    done < "$DB_FILE"

    echo "✅ DB cargada correctamente: ${#LABS[@]} laboratorios" >&2
}


#==============================================================================
# FUNCION DE LECTURA DE LAB POR NIVEL Y SELECCIÓN
#==============================================================================
select_lab_by_level() {
    echo "=== ENTRANDO A select_lab_by_level ===" >&2
    echo "Parámetro recibido: '$1'" >&2
    
    local LEVEL="$1"
    local FILTERED=()
    local MIN_USES=""
    local CANDIDATES=()
    local ID LAB_LEVEL LAB_PATH USES

    echo "Buscando nivel: '$LEVEL'" >&2
    echo "Total LABS: ${#LABS[@]}" >&2
    
    # 1. Filtrar por nivel
    for LAB in "${LABS[@]}"; do
        IFS='|' read -r ID LAB_LEVEL LAB_PATH USES <<< "$LAB"
        echo "Lab: ID=$ID, LEVEL='$LAB_LEVEL', PATH='$LAB_PATH', USES=$USES" >&2
        
        if [[ "${LAB_LEVEL,,}" == "${LEVEL,,}" ]]; then
            FILTERED+=("$LAB")
            echo "  ✓ COINCIDE - Agregado a FILTERED" >&2
        else
            echo "  ✗ NO coincide" >&2
        fi
    done

    echo "FILTERED encontrados: ${#FILTERED[@]}" >&2

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

    echo "CANDIDATES count = ${#CANDIDATES[@]}" >&2
    echo "CANDIDATES = ${CANDIDATES[*]}" >&2

    if [[ ${#CANDIDATES[@]} -eq 0 ]]; then
        echo "ERROR: No hay candidatos para seleccionar" >&2
        return 1
    fi

    local SELECTED_LAB="${CANDIDATES[RANDOM % ${#CANDIDATES[@]}]}"
    echo "SELECTED_LAB = $SELECTED_LAB" >&2

    IFS='|' read -r ID LAB_LEVEL LAB_PATH USES <<< "$SELECTED_LAB"

    update_lab_uses "$ID" "$((USES + 1))"

    # ✔️ ÚNICA salida por stdout
    echo "$ID|$LAB_LEVEL|$LAB_PATH"


}

#==============================================================================
# FUNCION DE ACTUALIZACIÓN DE LAB USAGES (0 DEPENDENCIAS)
#==============================================================================
update_lab_uses() {
    local TARGET_ID="$1"
    local NEW_USES="$2"

    awk -F'|' -v OFS='|' -v id="$TARGET_ID" -v uses="$NEW_USES" '
        NR==1 { print; next }
        $1==id { $4=uses }
        { print }
    ' "$DB_FILE" > "${DB_FILE}.tmp" && mv "${DB_FILE}.tmp" "$DB_FILE"

    echo "✅ Updated uses for $TARGET_ID → $NEW_USES" >&2
}




#==============================================================================
# FUNCION DE GESTIÓN DIRECTA POST-CREACIÓN DE VM
#==============================================================================
manage_single_vm() {
    local VM_NAME="$1"

    while true; do
        printf "\033c"
        STATE=$(sudo virsh domstate "$VM_NAME" 2>/dev/null || echo "unknown")
        IP=$(sudo virsh domifaddr "$VM_NAME" 2>/dev/null | awk 'NR>1{print $4}' || echo "no-ip")

        echo "=============================================="
        echo " GESTIÓN DE VM ACTIVA"
        echo "=============================================="
        echo " VM    : $VM_NAME"
        echo " Estado: $STATE"
        echo " IP    : $IP"
        echo
        echo "1) Reiniciar VM"
        echo "2) Parar VM"
        echo "3) Prender VM"
        echo "4) Eliminar VM (TOTAL)"
        echo "0) Volver al menú principal"
        echo
        read -rp "Opción: " opt

        case "$opt" in
            1)
                echo "🔄 Reiniciando VM..."
                sudo virsh reboot "$VM_NAME" >/dev/null 2>&1
                sleep 2
                ;;
            2)
                echo "⏹️  Parando VM..."
                sudo virsh shutdown "$VM_NAME" >/dev/null 2>&1
                sleep 3
                ;;
            3)
                echo "▶️  Encendiendo VM..."
                sudo virsh start "$VM_NAME" >/dev/null 2>&1
                sleep 2
                ;;
            4)
                echo "⚠️  Eliminando VM completamente..."
                cleanup_vm "$VM_NAME"
                echo "✅ VM eliminada sin residuos"
                sleep 2
                return 0   # ← vuelve al menú principal
                ;;
            0)
                return 0
                ;;
            *)
                echo "❌ Opción inválida"
                sleep 1
                ;;
        esac
    done
}



#==============================================================================
# FUNCION DE LIMPIEZA DE VM (MEJORADA)
#==============================================================================
cleanup_vm() {
    local VM_NAME="$1"

    echo "[CLEANUP] Apagando VM si está activa..."
    virsh destroy "$VM_NAME" >/dev/null 2>&1 || true

    echo "[CLEANUP] Eliminando definición y storage..."
    virsh undefine "$VM_NAME" --remove-all-storage >/dev/null 2>&1 || true

    echo "[CLEANUP] Limpiando archivos específicos de $VM_NAME..."
    rm -f /mnt/vms/labs/tmp/"${VM_NAME}.qcow2" 2>/dev/null || true
    rm -f "/tmp/${VM_NAME}-seed.iso" 2>/dev/null || true

    echo "[CLEANUP] LIMPIANDO DIRECTORIO /mnt/vms/labs/tmp/ COMPLETO..."
    # ✅ LIMPIEZA TOTAL segura (solo archivos, no directorio)
    find /mnt/vms/labs/tmp/ -mindepth 1 -delete 2>/dev/null || true
    
    # Alternativa más agresiva (si quieres borrar TODO incluyendo subdirs)
    rm -rf /mnt/vms/labs/tmp/* 2>/dev/null || true
    
    echo "[CLEANUP] Cleanup completo - /mnt/vms/labs/tmp/ vacía"
}


#==============================================================================
# FUNCION DEL MENÚ PRINCIPAL
#==============================================================================
main_menu() {
    while true; do
        printf "\033c"
        echo "================================================"
        echo " INCIDENT RESPONSE LAB ENGINE v1.1"
        echo "================================================"
        echo " Base VM: rocky9_base.qcow2"
        echo
        echo "1) Junior"
        echo "2) Pleno"
        echo "3) Senior"
        echo "0) Salir"
        echo
        read -rp "Opción: " option

        case "$option" in
            1) assign_lab "Junior" ;;
            2) assign_lab "Pleno" ;;
            3) assign_lab "Senior" ;;
            0)
                echo "Saliendo del Lab Engine..."
                exit 0
                ;;
            *)
                echo "❌ Opción inválida"
                sleep 1
                ;;
        esac
    done
}





#==============================================================================
# INICIO
#==============================================================================
echo "🚀 Incident Response Lab Engine v1.1"
load_db
while true; do main_menu; done

