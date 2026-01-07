#!/bin/bash
# ==============================================================================
# LABS ENGINE v2 — Orquestador de Laboratorios
# Soporta niveles: Junior / Junior-Pleno / Senior
# Ejecución desacoplada (Ansible, Bash, futuro)
# Autor: Jensy - 2026
# ==============================================================================

set -euo pipefail

# ==============================================================================
# CONFIGURACIÓN GLOBAL
# ==============================================================================
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$BASE_DIR/lab.conf"
DB_FILE="$BASE_DIR/labs.db"

[[ -f "$CONFIG_FILE" ]] || { echo "ERROR: Falta lab.conf"; exit 1; }
[[ -f "$DB_FILE" ]]     || { echo "ERROR: Falta labs.db"; exit 1; }

source "$CONFIG_FILE"

# ==============================================================================
# CARGA DE BASE DE DATOS
# ==============================================================================
load_db() {
    declare -gA LAB_LEVEL LAB_SCRIPT LAB_USES LAB_STATUS LAB_TYPE

    while IFS='|' read -r id level type script uses status; do
        [[ "$id" == "ID" || -z "$id" ]] && continue
        LAB_LEVEL["$id"]="$level"
        LAB_TYPE["$id"]="$type"       # bash | ansible | future
        LAB_SCRIPT["$id"]="$script"
        LAB_USES["$id"]="$uses"
        LAB_STATUS["$id"]="$status"
    done < "$DB_FILE"
}

# ==============================================================================
# SELECCIÓN DE LAB
# ==============================================================================
select_lab_auto() {
    local min_use
    min_use=$(printf "%s\n" "${LAB_USES[@]}" | sort -n | head -1)

    CANDIDATES=()
    for id in "${!LAB_USES[@]}"; do
        [[ "${LAB_USES[$id]}" -eq "$min_use" && "${LAB_STATUS[$id]}" == "active" ]] && \
            CANDIDATES+=("$id")
    done

    SELECTED_LAB="${CANDIDATES[RANDOM % ${#CANDIDATES[@]}]}"
}

select_lab_by_level() {
    local level="$1"
    CANDIDATES=()

    for id in "${!LAB_LEVEL[@]}"; do
        [[ "${LAB_LEVEL[$id]}" == "$level" && "${LAB_STATUS[$id]}" == "active" ]] && \
            CANDIDATES+=("$id")
    done

    [[ ${#CANDIDATES[@]} -eq 0 ]] && {
        echo "No hay labs activos para nivel $level"
        exit 1
    }

    SELECTED_LAB="${CANDIDATES[RANDOM % ${#CANDIDATES[@]}]}"
}

# ==============================================================================
# EJECUCIÓN DEL LAB
# ==============================================================================
execute_lab() {
    local level="${LAB_LEVEL[$SELECTED_LAB]}"
    local type="${LAB_TYPE[$SELECTED_LAB]}"
    local script="${LAB_SCRIPT[$SELECTED_LAB]}"

    LABS_DIR="$(realpath "$BASE_DIR/../scenarios")"
    LAB_PATH="$LABS_DIR/${level,,}/$script"

    [[ -f "$LAB_PATH" ]] || {
        echo "ERROR: No existe $LAB_PATH"
        exit 1
    }

    echo
    echo "▶ Ejecutando laboratorio $SELECTED_LAB"
    echo "  Nivel : $level"
    echo "  Tipo  : $type"
    echo "  Script: $script"
    echo

    case "$type" in
        ansible)
            "$BASE_DIR/ansible_wrapper.sh" "$LAB_PATH" "$BASE_DIR/inventory.yml"
            ;;
        bash)
            echo "⚠️  Bash labs no soportados en v2 (legacy)"
            ;;
        *)
            echo "ERROR: Tipo de lab desconocido ($type)"
            exit 1
            ;;
    esac
}

# ==============================================================================
# MENÚ
# ==============================================================================
show_menu() {
    echo
    echo "LABS ENGINE"
    echo "───────────"
    echo "1) Ejecutar laboratorio (auto)"
    echo "2) Ejecutar laboratorio por nivel"
    echo "3) Listar laboratorios"
    echo "4) Salir"
    echo
    read -rp "Selecciona una opción: " opt

    case "$opt" in
        1)
            select_lab_auto
            execute_lab
            ;;
        2)
            read -rp "Nivel (junior | junior_pleno | senior): " lvl
            select_lab_by_level "$lvl"
            execute_lab
            ;;
        3)
            printf "%-6s %-15s %-10s %-20s %-5s\n" "ID" "Nivel" "Tipo" "Script" "Usos"
            for id in "${!LAB_LEVEL[@]}"; do
                printf "%-6s %-15s %-10s %-20s %-5s\n" \
                    "$id" "${LAB_LEVEL[$id]}" "${LAB_TYPE[$id]}" \
                    "${LAB_SCRIPT[$id]}" "${LAB_USES[$id]}"
            done
            ;;
        4)
            exit 0
            ;;
        *)
            echo "Opción inválida"
            ;;
    esac
}

# ==============================================================================
# MAIN
# ==============================================================================
load_db
show_menu
