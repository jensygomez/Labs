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
    echo "Template: $TEMPLATE"
    
    read -rp "ENTER para generar ISO cloud-init... " 
    ISO_PATH=$(bash "$ENGINE_DIR/cloudinit_generator.sh" "$LEVEL" "$ID" "$TEMPLATE")
    echo "✅ ISO creado: $ISO_PATH"
    
    # ✅ PAUSA PRINCIPAL - Aquí haces tu lab
    echo "🖥️  VM lista! Conéctate SSH o Virt-Manager"
    echo "Cuando TERMINE el lab, presiona ENTER aquí:"
    read -rp "ENTER para cleanup y volver al menú... "
    
    echo "🧹 Limpiando..."
    increment_uses "$ID"
    echo "✅ Lab completado!"
}


# INICIO
load_db
while true; do main_menu; done
