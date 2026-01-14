#!/bin/bash
set -euo pipefail

# RUTAS BASE
ENGINE_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$ENGINE_DIR/.." && pwd)"
VM_DISK="/mnt/vms"
DB_FILE="$ENGINE_DIR/labs.db"
LABS=()

# load_db SIMPLIFICADO que SIEMPRE FUNCIONA
load_db() {
    LABS=()
    [[ ! -f "$DB_FILE" ]] && return 0
    
    # Leer limpiando \r y procesando robustamente
    while IFS=$'\r' read -r line || [[ -n "$line" ]]; do
        line="${line//$'\r'/}"  # Strip carriage return
        [[ "${line:0:2}" == "ID" || "${line:0:2}" == "id" ]] && continue  # Skip header
        [[ "$line" =~ active$ ]] || continue  # Skip inactive
        
        IFS='|' read -r id track level artifact type uses <<< "$line"
        full_artifact="$ROOT_DIR/$artifact"
        
        # CARGAR INCONDICIONALMENTE (template opcional)
        LABS+=("$id|$track|$level|$full_artifact|$type|$uses")
    done < "$DB_FILE"
}

main_menu() {
    clear
    echo "============================================"
    echo " INCIDENT RESPONSE LAB ENGINE"
    echo "============================================"
    echo "  💾 VMs: $VM_DISK"
    echo "  📊 Labs: ${#LABS[@]}"
    echo "1) Junior    2) Pleno    3) Senior    0) Salir"
    echo
    read -rp "Opción: " option
    case "$option" in 1) assign_lab "Junior" ;; 2) assign_lab "Pleno" ;; 3) assign_lab "Senior" ;; 0) exit 0 ;; *) main_menu ;; esac
}

assign_lab() {
    local LEVEL="$1"
    local CANDIDATES=() MIN_USES=999999
    
    for LAB in "${LABS[@]}"; do
        IFS='|' read -r id track lab_level artifact type uses <<< "$LAB"
        [[ "${lab_level,,}" != "${LEVEL,,}" ]] && continue
        
        if (( uses < MIN_USES )); then 
            MIN_USES="$uses" 
            CANDIDATES=("$LAB") 
        elif (( uses == MIN_USES )); then 
            CANDIDATES+=("$LAB") 
        fi
    done
    
    if [[ ${#CANDIDATES[@]} -eq 0 ]]; then
        echo "[ERROR] Sin labs para $LEVEL"
        read -rp "ENTER..."
        return
    fi
    
    local SELECTED="${CANDIDATES[$RANDOM % ${#CANDIDATES[@]}]}"
    IFS='|' read -r id track level artifact type uses <<< "$SELECTED"
    run_lab "$id" "$artifact" "$level"
}

run_lab() {
    local ID="$1" TEMPLATE="$2" LEVEL="$3"
    echo "🚀 Iniciando Lab: $ID ($LEVEL)"
    echo "Template: $TEMPLATE"
    
    read -rp "ENTER para generar ISO cloud-init..."
    ISO_PATH=$(bash "$ENGINE_DIR/cloudinit_generator.sh" "$LEVEL" "$ID" "$TEMPLATE")
    echo "✅ ISO: $ISO_PATH"
    
    read -rp "ENTER para continuar..."
}

# INICIO
echo "🚀 Lab Engine iniciado"
load_db
echo "📊 ${#LABS[@]} labs cargados"
while true; do main_menu; done
