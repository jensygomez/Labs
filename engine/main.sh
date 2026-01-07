#!/bin/bash
# ==============================================================================
# INCIDENT RESPONSE LAB ENGINE
# main.sh
# ------------------------------------------------------------------------------
# Rol:
# - Orquestador de laboratorios
# - Menú por nivel (Junior / Junior-Pleno / Senior)
# - Asignación AUTOMÁTICA de labs
# - Métricas de uso
#
# Backend único:
# - Ansible (vía ansible_wrapper.sh)
#
# Autor: Jensy - 2026
# ==============================================================================

set -euo pipefail

# ==============================================================================
# BLOQUE 0 - CONFIGURACIÓN GLOBAL
# ==============================================================================
ENGINE_DIR="$(cd "$(dirname "$0")" && pwd)"
DB_FILE="$ENGINE_DIR/labs.db"
INVENTORY="$ENGINE_DIR/inventory.yml"
ANSIBLE_WRAPPER="$ENGINE_DIR/ansible_wrapper.sh"

LABS=()

# ==============================================================================
# BLOQUE 1 - CARGA DE BASE DE DATOS
# ==============================================================================
load_db() {
    LABS=()

    while IFS='|' read -r ID TRACK LEVEL ARTIFACT TYPE USES STATUS; do
        [[ "$ID" == "ID" ]] && continue
        [[ "$STATUS" != "active" ]] && continue

        LABS+=("$ID|$TRACK|$LEVEL|$ARTIFACT|$USES")
    done < "$DB_FILE"

    [[ "${#LABS[@]}" -eq 0 ]] && {
        echo "[ERROR] No hay laboratorios activos en labs.db"
        exit 1
    }
}

# ==============================================================================
# BLOQUE 2 - MENÚ PRINCIPAL
# ==============================================================================
main_menu() {
    clear
    echo "========================================"
    echo "  INCIDENT RESPONSE LAB ENGINE"
    echo "========================================"
    echo
    echo "Seleccione su nivel actual:"
    echo
    echo "1) Junior ( 0–18 meses)"
    echo "2) Pleno  (18–36 meses)"
    echo "3) Senior (36+   meses) [PRÓXIMAMENTE]"
    echo "0) Salir"
    echo
    read -rp "Opción: " option

    case "$option" in
        1) assign_lab "junior" ;;
        2) assign_lab "pleno" ;;
        3)
            echo
            echo "Nivel Senior aún no disponible."
            sleep 2
            ;;
        0) exit 0 ;;
        *)
            echo
            echo "Opción inválida."
            sleep 1
            ;;
    esac
}

# ==============================================================================
# BLOQUE 3 - ASIGNACIÓN AUTOMÁTICA DE LAB
# ==============================================================================
assign_lab() {
    local TRACK="$1"
    local CANDIDATES=()
    local MIN_USES=""

    clear
    echo "========================================"
    echo " Asignando laboratorio automáticamente"
    echo " Nivel: $TRACK"
    echo "========================================"
    echo

    # Buscar labs activos del track con menor USE
    for LAB in "${LABS[@]}"; do
        IFS='|' read -r ID LAB_TRACK LEVEL ARTIFACT USES <<< "$LAB"
        [[ "$LAB_TRACK" != "$TRACK" ]] && continue

        if [[ -z "$MIN_USES" || "$USES" -lt "$MIN_USES" ]]; then
            MIN_USES="$USES"
            CANDIDATES=("$LAB")
        elif [[ "$USES" -eq "$MIN_USES" ]]; then
            CANDIDATES+=("$LAB")
        fi
    done

    [[ "${#CANDIDATES[@]}" -eq 0 ]] && {
        echo "No hay laboratorios activos para este nivel."
        sleep 2
        return
    }

    # Selección aleatoria entre los menos usados
    SELECTED="${CANDIDATES[$RANDOM % ${#CANDIDATES[@]}]}"
    IFS='|' read -r ID LAB_TRACK LEVEL ARTIFACT USES <<< "$SELECTED"

    echo "Laboratorio asignado:"
    echo "ID        : $ID"
    echo "Nivel     : $LEVEL"
    echo "Usos prev.: $USES"
    echo
    sleep 2

    run_lab "$ID" "$ARTIFACT"
}

# ==============================================================================
# BLOQUE 4 - EJECUCIÓN DE LAB (ANSIBLE ONLY)
# ==============================================================================
run_lab() {
    local ID="$1"
    local PLAYBOOK="$2"

    clear
    echo "========================================"
    echo " Ejecutando laboratorio $ID"
    echo "========================================"
    echo

    "$ANSIBLE_WRAPPER" \
        "$PLAYBOOK" \
        "$INVENTORY"

    increment_uses "$ID"

    echo
    echo "Laboratorio finalizado."
    read -rp "Presione ENTER para continuar..."
}

# ==============================================================================
# BLOQUE 5 - MÉTRICAS (USES++)
# ==============================================================================
increment_uses() {
    local ID="$1"

    awk -F'|' -v id="$ID" 'BEGIN {OFS=FS}
        NR==1 {print; next}
        $1==id {$5=$5+1}
        {print}
    ' "$DB_FILE" > "$DB_FILE.tmp" && mv "$DB_FILE.tmp" "$DB_FILE"
}

# ==============================================================================
# BLOQUE PRINCIPAL
# ==============================================================================
load_db

while true; do
    main_menu
done
