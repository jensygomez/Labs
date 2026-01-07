#!/bin/bash
# ==============================================================================
# INCIDENT RESPONSE LAB ENGINE
# main.sh
# ------------------------------------------------------------------------------
# - Selector de laboratorios por nivel
# - Soporte Bash y Ansible
# - Métricas de uso
# - Arquitectura escalable (Senior-ready)
# Autor: Jensy - 2026
# ==============================================================================

set -euo pipefail

# ==============================================================================
# BLOQUE 0 - CONFIGURACIÓN GLOBAL
# ==============================================================================
ENGINE_DIR="$(cd "$(dirname "$0")" && pwd)"
DB_FILE="$ENGINE_DIR/labs.db"
INVENTORY="$ENGINE_DIR/inventory.yml"

LABS=()

# ==============================================================================
# BLOQUE 1 - CARGA DE BASE DE DATOS
# ==============================================================================
load_db() {
    LABS=()

    while IFS='|' read -r ID TRACK LEVEL ARTIFACT TYPE USES STATUS; do
        [[ "$ID" == "ID" ]] && continue
        [[ "$STATUS" != "active" ]] && continue

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
    echo "1) Junior (0–18 meses)"
    echo "2) Junior-Pleno (18–36 meses)"
    echo "3) Senior (36+ meses) [PRÓXIMAMENTE]"
    echo "0) Salir"
    echo
    read -rp "Opción: " option

    case "$option" in
        1) select_track "junior" ;;
        2) select_track "junior_pleno" ;;
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
# BLOQUE 3 - SELECCIÓN DE LAB POR TRACK
# ==============================================================================
select_track() {
    local TRACK="$1"
    local AVAILABLE=()

    clear
    echo "========================================"
    echo " Laboratorios disponibles: $TRACK"
    echo "========================================"
    echo

    for LAB in "${LABS[@]}"; do
        IFS='|' read -r ID LAB_TRACK LEVEL ARTIFACT TYPE USES <<< "$LAB"

        if [[ "$LAB_TRACK" == "$TRACK" ]]; then
            AVAILABLE+=("$LAB")
            printf "%-6s %-30s [%s]\n" "$ID" "$LEVEL" "$TYPE"
        fi
    done

    [[ "${#AVAILABLE[@]}" -eq 0 ]] && {
        echo
        echo "No hay laboratorios disponibles para este nivel."
        sleep 2
        return
    }

    echo
    read -rp "Ingrese ID del laboratorio (o 'b' para volver): " choice
    [[ "$choice" == "b" ]] && return

    for LAB in "${AVAILABLE[@]}"; do
        IFS='|' read -r ID LAB_TRACK LEVEL ARTIFACT TYPE USES <<< "$LAB"
        if [[ "$ID" == "$choice" ]]; then
            run_lab "$ID" "$ARTIFACT" "$TYPE"
            return
        fi
    done

    echo
    echo "Laboratorio no encontrado."
    sleep 2
}

# ==============================================================================
# BLOQUE 4 - EJECUTOR GENÉRICO DE LABS
# ==============================================================================
run_lab() {
    local ID="$1"
    local ARTIFACT="$2"
    local TYPE="$3"

    clear
    echo "========================================"
    echo " Ejecutando laboratorio $ID"
    echo "========================================"
    echo

    case "$TYPE" in
        bash)
            bash "$ARTIFACT"
            ;;
        ansible)
            run_ansible_lab "$ID" "$ARTIFACT"
            ;;
        *)
            echo "[ERROR] Tipo de laboratorio desconocido: $TYPE"
            ;;
    esac

    increment_uses "$ID"

    echo
    echo "Laboratorio finalizado."
    read -rp "Presione ENTER para continuar..."
}

# ==============================================================================
# BLOQUE 5 - WRAPPER ANSIBLE
# ==============================================================================
run_ansible_lab() {
    local ID="$1"
    local PLAYBOOK="$2"

    local VARIANT
    VARIANT="$(shuf -e A B C D -n 1)"

    echo "Variante seleccionada: $VARIANT"
    echo

    ansible-playbook \
        -i "$INVENTORY" \
        "$PLAYBOOK" \
        -e "variant=$VARIANT"
}

# ==============================================================================
# BLOQUE 6 - MÉTRICAS (USES++)
# ==============================================================================
increment_uses() {
    local ID="$1"

    awk -F'|' -v id="$ID" 'BEGIN {OFS=FS}
        NR==1 {print; next}
        $1==id {$6=$6+1}
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
