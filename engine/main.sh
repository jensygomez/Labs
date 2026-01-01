#!/bin/bash
# ==============================================================================
# LABS ENGINE - Generador automático de laboratorios Linux
# Soporta niveles: Junior / Pleno / Senior
# Selección automática + contador + inyección remota en VM
# Autor: Jensy - 2026
# ==============================================================================

set -uo pipefail

# ==============================================================================
# BLOQUE 0 - CONFIGURACIÓN GLOBAL
# ==============================================================================
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$BASE_DIR/lab.conf"

[[ -f "$CONFIG_FILE" ]] || { echo "ERROR: Falta $CONFIG_FILE"; exit 1; }
source "$CONFIG_FILE"

# ==============================================================================
# BLOQUE 1 - FUNCIONES AUXILIARES
# ==============================================================================
# ------------------------------------------------------------------------------
# Verifica conexión SSH + sudo
# ------------------------------------------------------------------------------
verify_connection() {
    echo -e "${CYAN}Verificando conexión a la VM y acceso sudo...${RESET}"

    if ! ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
             -o BatchMode=yes -q "$VM_USER@$VM_HOST" exit 2>/dev/null; then
        echo -e "${RED}✗ Error: No se puede conectar por SSH a $VM_HOST${RESET}"
        exit 1
    fi

    if ! ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o BatchMode=yes -q \
             "$VM_USER@$VM_HOST" "echo '$SUDO_PASS' | sudo -S whoami" 2>/dev/null | \
             grep -q "^root$"; then
        echo -e "${RED}✗ Error: sudo falla (password incorrecta o configuración)${RESET}"
        exit 1
    fi

    echo -e "${GREEN}✓ Conexión SSH y sudo verificados correctamente${RESET}"
    sleep 0.5
}

# ------------------------------------------------------------------------------
# Leer base de datos labs.db y cargar arrays
# ------------------------------------------------------------------------------
load_db() {
    declare -gA LAB_LEVEL LAB_SCRIPT LAB_USES LAB_STATUS
    while IFS='|' read -r id level script uses status; do
        [[ "$id" == "ID" || -z "$id" ]] && continue
        LAB_LEVEL["$id"]="$level"
        LAB_SCRIPT["$id"]="$script"
        LAB_USES["$id"]="$uses"
        LAB_STATUS["$id"]="$status"
    done < "$DB_FILE"

    [[ ${#LAB_LEVEL[@]} -eq 0 ]] && {
        echo -e "${RED}ERROR: Base de datos vacía o inválida${RESET}"
        exit 1
    }
}

# ------------------------------------------------------------------------------
# Selecciona lab con menor contador + azar
# ------------------------------------------------------------------------------
select_lab() {
    local min_use
    min_use=$(printf "%s\n" "${LAB_USES[@]}" | sort -n | head -1)

    CANDIDATES=()
    for id in "${!LAB_USES[@]}"; do
        [[ "${LAB_USES[$id]}" -eq "$min_use" && "${LAB_STATUS[$id]}" == "active" ]] && \
            CANDIDATES+=("$id")
    done

    index=$(( RANDOM % ${#CANDIDATES[@]} ))
    SELECTED_LAB="${CANDIDATES[index]}"
    SELECTED_LAB_LEVEL="${LAB_LEVEL[$SELECTED_LAB]}"
    SELECTED_LAB_SCRIPT="${LAB_SCRIPT[$SELECTED_LAB]}"

    echo -e "${GREEN}Laboratorio seleccionado: $SELECTED_LAB (${SELECTED_LAB_LEVEL}) - Script: $SELECTED_LAB_SCRIPT (uso=${LAB_USES[$SELECTED_LAB]})${RESET}"
    sleep 0.5
}

# ------------------------------------------------------------------------------
# Actualiza contador del lab
# ------------------------------------------------------------------------------
update_lab_counter() {
    local new_count=$(( LAB_USES["$SELECTED_LAB"] + 1 ))
    sed -i "s/^${SELECTED_LAB}|.*|.*|.*|.*/${SELECTED_LAB}|${SELECTED_LAB_LEVEL}|${SELECTED_LAB_SCRIPT}|${new_count}|${LAB_STATUS[$SELECTED_LAB]}/" "$DB_FILE"
    echo -e "${GREEN}OK - $SELECTED_LAB ahora tiene contador $new_count${RESET}"
    sleep 0.5
}

# ------------------------------------------------------------------------------
# Construir ruta del script según nivel
# ------------------------------------------------------------------------------
build_patch_path() {
    # LABS_DIR apunta a la carpeta principal de escenarios
    LABS_DIR="$(realpath "$BASE_DIR/../scenarios")"
    patch_path="$LABS_DIR/${SELECTED_LAB_LEVEL,,}/$SELECTED_LAB_SCRIPT"

    [[ -f "$patch_path" ]] || { echo -e "${RED}ERROR: No existe el script $patch_path${RESET}"; exit 1; }
    echo -e "${GREEN}Encontrado script: $patch_path${RESET}"
    sleep 0.5
}

# ------------------------------------------------------------------------------
# Mostrar ticket localmente
# ------------------------------------------------------------------------------
show_lab_ticket() {
    source "$patch_path"
    show_ticket
    echo
    echo -e "${YELLOW}Presiona Enter para inyectar el laboratorio en la VM...${RESET}"
    read -r
}

# ------------------------------------------------------------------------------
# Aplicar laboratorio usando la función definida en el lab
# ------------------------------------------------------------------------------
apply_lab_remote() {
echo -e "${CYAN}Ejecutando función apply_lab() del laboratorio $SELECTED_LAB...${RESET}"
sleep 0.5
apply_lab --apply   # Llama directamente a la función del lab inyectando el fallo
}


# ------------------------------------------------------------------------------
# Mensaje final
# ------------------------------------------------------------------------------
print_completion() {
    echo
    echo -e "${CYAN}==================================================${RESET}"
    echo -e "${GREEN}¡LABORATORIO $SELECTED_LAB LISTO!${RESET}"
    echo
    echo -e "${CYAN}Conéctate y resuélvelo:${RESET}"
    echo -e "${YELLOW}    ssh -i $SSH_KEY $VM_USER@$VM_HOST${RESET}"
    echo -e "${CYAN}==================================================${RESET}"
    echo -e "${GREEN}¡A practicar! 🚀${RESET}"
}



# ==============================================================================
# BLOQUE PRINCIPAL - EJECUCIÓN
# ==============================================================================
echo "Leyendo la base de datos"
load_db
sleep 0.5
echo "Selecionando la Base de datos"
select_lab
sleep 0.5
update_lab_counter
sleep 0.5
echo "actualizando el contador"
build_patch_path
sleep 0.5
echo "construyendo el path"
verify_connection
sleep 0.5
echo "Verificando conexion"
show_lab_ticket
sleep 0.5
echo "Mostrando el ticket"
apply_lab_remote
sleep 0.5
echo "aplicando el lab remotamente"
print_completion
sleep 0.5
echo "completado"
