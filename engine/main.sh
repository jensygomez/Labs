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
    echo "[DEBUG] Iniciando carga de BD desde: $DB_FILE" >&2
    LABS=()

    if [[ ! -f "$DB_FILE" ]]; then
        echo "[ERROR] No se encuentra el archivo labs.db en: $DB_FILE" >&2
        return 1
    fi

    # DEBUG: mostrar qué hay en la BD
    echo "[DEBUG] Verificando labs activos..." >&2
    awk -F'|' 'NR>1 && $7=="active" {print "[DEBUG] Lab activo en BD: " $1}' "$DB_FILE" >&2

    # Leer la BD - versión simple
    local line_count=0
    while IFS= read -r line; do
        ((line_count++))
        [[ $line_count -eq 1 ]] && continue  # Saltar cabecera
        [[ -z "$line" ]] && continue         # Saltar líneas vacías
        
        # Separar campos
        IFS='|' read -r id track level artifact type uses status <<< "$line"
        
        # Limpiar cualquier espacio
        status=$(echo "$status" | tr -d '[:space:]')
        
        echo "[DEBUG] Procesando: $id, status='$status'" >&2
        
        if [[ "$status" == "active" ]]; then
            # Limpiar todos los campos
            id=$(echo "$id" | xargs)
            track=$(echo "$track" | xargs)
            level=$(echo "$level" | xargs)
            artifact=$(echo "$artifact" | xargs)
            type=$(echo "$type" | xargs)
            uses=$(echo "$uses" | xargs)
            
            LABS+=("$id|$track|$level|$artifact|$type|$uses")
            echo "[DEBUG] Agregado a LABS: $id" >&2
        fi
    done < "$DB_FILE"

    echo "[INFO] Cargados ${#LABS[@]} laboratorio(s) activo(s)" >&2
    
    # DEBUG: mostrar qué se cargó
    for lab in "${LABS[@]}"; do
        echo "[DEBUG] En array: $lab" >&2
    done
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
    echo "2) Junior-Pleno (18–24 meses)"
    echo "3) Pleno (24–36 meses)"
    echo "4) Senior (36+ meses)"
    echo "0) Salir"
    echo
    read -rp "Opción: " option

    case "$option" in
        1) assign_lab "Junior" ;;
        2) assign_lab "Junior-Pleno" ;;
        3) assign_lab "Pleno" ;;
        4) assign_lab "Senior" ;;
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

    echo "[DEBUG] Nivel solicitado: $LEVEL" >&2
    echo "[DEBUG] Total de labs en array: ${#LABS[@]}" >&2
    
    if [[ "${#LABS[@]}" -eq 0 ]]; then
        echo "[ERROR] No hay laboratorios activos en la base de datos."
        echo "DEBUG: El array LABS está vacío"
        echo "Contacte al administrador para activar laboratorios."
        sleep 3
        return
    fi

    # Mostrar todos los labs disponibles
    echo "[DEBUG] Labs disponibles:" >&2
    for LAB in "${LABS[@]}"; do
        IFS='|' read -r ID TRACK LAB_LEVEL ARTIFACT TYPE USES <<< "$LAB"
        echo "[DEBUG]   - $ID ($LAB_LEVEL)" >&2
    done

    # Buscar labs activos del nivel con menor USES
    for LAB in "${LABS[@]}"; do
        IFS='|' read -r ID TRACK LAB_LEVEL ARTIFACT TYPE USES <<< "$LAB"
        
        echo "[DEBUG] Evaluando: $ID (Nivel: $LAB_LEVEL, Target: $LEVEL)" >&2
        
        # Filtrar por nivel
        if [[ "$LAB_LEVEL" == "$LEVEL" ]]; then
            echo "[DEBUG] ¡Coincide! $ID tiene $USES usos" >&2
            
            if [[ -z "$MIN_USES" || "$USES" -lt "$MIN_USES" ]]; then
                MIN_USES="$USES"
                CANDIDATES=("$LAB")
                echo "[DEBUG] Nuevo mínimo: $MIN_USES usos (lab: $ID)" >&2
            elif [[ "$USES" -eq "$MIN_USES" ]]; then
                CANDIDATES+=("$LAB")
                echo "[DEBUG] Mismo mínimo: $USES usos (lab: $ID)" >&2
            fi
        fi
    done

    [[ "${#CANDIDATES[@]}" -eq 0 ]] && {
        echo "[INFO] No hay laboratorios activos para el nivel '$LEVEL'."
        echo "Laboratorios disponibles para otros niveles:"
        for LAB in "${LABS[@]}"; do
            IFS='|' read -r ID TRACK LAB_LEVEL ARTIFACT TYPE USES <<< "$LAB"
            echo "  - $ID ($LAB_LEVEL): $USES usos"
        done
        sleep 3
        return
    }

    echo "[DEBUG] Candidatos encontrados: ${#CANDIDATES[@]}" >&2
    
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

    if [[ ! -f "$PLAYBOOK" ]]; then
        echo "[ERROR] No se encuentra el playbook: $PLAYBOOK"
        echo "Verifique la ruta del artifact en la base de datos."
        sleep 3
        return
    fi

    "$ANSIBLE_WRAPPER" \
        "$PLAYBOOK" \
        "$INVENTORY"

    increment_uses "$ID"

    echo
    echo "========================================"
    echo " Laboratorio $ID finalizado"
    echo "========================================"
    echo "Revisa el log para más detalles."
    echo
    read -rp "Presione ENTER para volver al menú..."
    clear
}

# ==============================================================================
# BLOQUE 5 - MÉTRICAS (USES++)
# ==============================================================================
increment_uses() {
    local ID="$1"

    awk -F'|' -v id="$ID" 'BEGIN {OFS=FS}
        NR==1 {print; next}
        {
            # Limpiar espacios del ID para comparación
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1)
            if ($1 == id) {
                # Limpiar USES y convertir a número
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", $6)
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
# Cargar base de datos
if ! load_db; then
    echo "[ADVERTENCIA] Problema al cargar la base de datos"
    echo "Continuando con lista de laboratorios vacía..."
fi

while true; do
    main_menu
done