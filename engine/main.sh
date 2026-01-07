#!/bin/bash
# ==============================================================================
# INCIDENT RESPONSE LAB ENGINE
# main.sh
# ------------------------------------------------------------------------------
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
        # Limpiar espacios en blanco
        ID=$(echo "$ID" | xargs)
        STATUS=$(echo "$STATUS" | xargs)
        
        [[ "$ID" == "ID" ]] && continue
        [[ "$STATUS" != "active" ]] && continue  # Solo labs activos

        LABS+=("$ID|$TRACK|$LEVEL|$ARTIFACT|$TYPE|$USES")
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
    echo "1) Junior (0 –18 meses)"
    echo "2) Pleno  (24–36 meses)"
    echo "3) Senior (36+   meses)"
    echo "0) Salir"
    echo
    read -rp "Opción: " option

    case "$option" in
        1) assign_lab "Junior" ;;          # Corresponde a LEVEL en DB
        2) assign_lab "Pleno" ;;
        3) assign_lab "Senior" ;;
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
    local LEVEL="$1"
    local CANDIDATES=()
    local MIN_USES=""

    clear
    echo "========================================"
    echo " Asignando laboratorio automáticamente"
    echo " Nivel: $LEVEL"
    echo "========================================"
    echo

    # Buscar labs activos del nivel con menor USES
    for LAB in "${LABS[@]}"; do
        IFS='|' read -r ID TRACK LAB_LEVEL ARTIFACT TYPE USES <<< "$LAB"
        
        # Filtrar por nivel y estado activo (ya filtrado en load_db)
        [[ "$LAB_LEVEL" != "$LEVEL" ]] && continue

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
    IFS='|' read -r ID TRACK LEVEL ARTIFACT TYPE USES <<< "$SELECTED"

    echo "Laboratorio asignado:"
    echo "ID        : $ID"
    echo "Track     : $TRACK"
    echo "Nivel     : $LEVEL"
    echo "Artifact  : $ARTIFACT"
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
        {
            # Limpiar espacios
            gsub(/^[ \t]+|[ \t]+$/, "", $1)
            if ($1 == id) {
                # Limpiar y convertir USES a número
                gsub(/^[ \t]+|[ \t]+$/, "", $6)
                $6 = $6 + 1
            }
            print
        }
    ' "$DB_FILE" > "$DB_FILE.tmp" && mv "$DB_FILE.tmp" "$DB_FILE"
    
    # Recargar base de datos después del cambio
    load_db
}

# ==============================================================================
# BLOQUE PRINCIPAL
# ==============================================================================
load_db

while true; do
    main_menu
done