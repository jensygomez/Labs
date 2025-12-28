#!/bin/bash
# RHCSA Labs - Main controller
# Solo: escoger lab aleatorio, borrarlo de DB, inyectarlo en VM

set -euo pipefail

# Configuración
BASE_DIR="/home/jensy/GitHub/Labs/1_Storage/05_Resize_LVs_Filesystems"
DB_FILE="$BASE_DIR/labs_database.txt"
SSH_KEY="/home/jensy/GitHub/Labs/.ssh/id_rhcsalabs"

VM_USER="student"
VM_HOST="192.168.122.231"

# Colores
RED='\033[1;31m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
RESET='\033[0m'

# 1. Leer base de datos en un array
read_lab_db() {
    if [[ ! -f "$DB_FILE" ]]; then
        echo -e "${RED}ERROR: No se encuentra la base de datos $DB_FILE${RESET}"
        exit 1
    fi

    mapfile -t LABS < "$DB_FILE"
    
    if [[ ${#LABS[@]} -eq 0 ]]; then
        echo -e "${RED}ERROR: La base de datos está vacía${RESET}"
        exit 1
    fi
}

# 2. Escoger un laboratorio aleatoriamente
choose_lab() {
    local index=$(( RANDOM % ${#LABS[@]} ))
    SELECTED_LAB="${LABS[index]}"
    echo -e "${GREEN}Laboratorio seleccionado: $SELECTED_LAB${RESET}"
}

# 3. Borrar el laboratorio escogido del archivo (sin dejar líneas en blanco)
remove_lab_from_db() {
    local temp_file="$DB_FILE.tmp"
    
    # Filtrar la línea exacta y escribir en archivo temporal
    grep -vFx "$SELECTED_LAB" "$DB_FILE" > "$temp_file"
    
    # Reemplazar el archivo original
    mv "$temp_file" "$DB_FILE"
    
    echo "Laboratorio $SELECTED_LAB eliminado de la base de datos"
}

# 4. + 5. Conectar por SSH y ejecutar el patch como root
inject_patch_to_vm() {
    local patch_path="$BASE_DIR/${SELECTED_LAB}.sh"
    
    [[ -f "$patch_path" ]] || { echo -e "${RED}ERROR: No existe $patch_path${RESET}"; exit 1; }

    echo -e "${CYAN}Copiando archivo...${RESET}"
    if ! scp -i "$SSH_KEY" -o StrictHostKeyChecking=no "$patch_path" "$VM_USER@$VM_HOST:/tmp/lab_setup.sh"; then
        echo -e "${RED}Fallo al copiar archivo a la VM${RESET}"
        exit 1
    fi

    echo -e "${CYAN}Ejecutando en VM...${RESET}"
    if ! ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$VM_USER@$VM_HOST" << 'EOF'
        sudo bash /tmp/lab_setup.sh || { echo "Error al ejecutar el script"; exit 1; }
        sudo rm -f /tmp/lab_setup.sh
EOF
    then
        echo -e "${RED}Fallo al ejecutar comandos en la VM${RESET}"
        exit 1
    fi

    echo -e "${GREEN}Inyección completada${RESET}"
}

# Flujo principal
read_lab_db
choose_lab
remove_lab_from_db
inject_patch_to_vm

echo -e "${GREEN}Proceso finalizado${RESET}"