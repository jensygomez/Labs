#!/bin/bash
set -euo pipefail

BASE_DIR="/home/jensy/GitHub/Labs/1_Storage/05_Resize_LVs_Filesystems"
DB_FILE="$BASE_DIR/labs_database.txt"
SSH_KEY="/home/jensy/GitHub/Labs/.ssh/id_rhcsalabs"
VM_USER="student"
VM_HOST="192.168.122.231"

GREEN='\033[1;32m'
CYAN='\033[1;36m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
RESET='\033[0m'

echo -e "${CYAN}=== Iniciando generador de laboratorios RHCSA ===${RESET}"
sleep 0.5

echo -e "${YELLOW}Paso 1: Leyendo la base de datos...${RESET}"
sleep 0.5
if [[ ! -f "$DB_FILE" ]]; then
    echo -e "${RED}ERROR: No existe $DB_FILE${RESET}"
    exit 1
fi

mapfile -t LABS < <(grep -v '^$' "$DB_FILE" | tr -d '\r')  # Ignora líneas vacías y quita \r

if [[ ${#LABS[@]} -eq 0 ]]; then
    echo -e "${RED}ERROR: No hay laboratorios en la base de datos${RESET}"
    exit 1
fi
echo -e "${GREEN}OK - Encontré ${#LABS[@]} laboratorio(s)${RESET}"
sleep 0.5

echo -e "${YELLOW}Paso 2: Escogiendo uno al azar...${RESET}"
sleep 0.5
index=$(( RANDOM % ${#LABS[@]} ))
SELECTED_LAB="${LABS[index]}"
echo -e "${GREEN}Laboratorio seleccionado: '$SELECTED_LAB'${RESET}"
sleep 0.5

echo -e "${YELLOW}Paso 3: Borrando del archivo...${RESET}"
sleep 0.5
echo "Contenido actual (con caracteres visibles):"
cat -A "$DB_FILE"

SELECTED_LAB_CLEAN=$(echo "$SELECTED_LAB" | tr -d '\r')

echo "Eliminando línea exacta: '$SELECTED_LAB_CLEAN'"

if sed "/^${SELECTED_LAB_CLEAN}$/d" "$DB_FILE" > "$DB_FILE.tmp" && mv "$DB_FILE.tmp" "$DB_FILE"; then
    echo -e "${GREEN}OK - Laboratorio borrado de la base de datos${RESET}"
else
    echo -e "${RED}ERROR: No se pudo borrar la línea${RESET}"
    rm -f "$DB_FILE.tmp"
    exit 1
fi
sleep 0.5

echo -e "${YELLOW}Paso 4: Preparando inyección en VM...${RESET}"
sleep 0.5
patch_path="$BASE_DIR/${SELECTED_LAB}.sh"
if [[ ! -f "$patch_path" ]]; then
    echo -e "${RED}ERROR: No existe $patch_path${RESET}"
    exit 1
fi
echo -e "${GREEN}Encontrado: $patch_path${RESET}"

# Los pasos de SCP y SSH los dejamos para después de arreglar esto
echo -e "${CYAN}=== Por ahora paramos aquí para confirmar que borra bien ===${RESET}"
echo -e "${CYAN}Si ves este mensaje, ¡ya arreglamos el borrado!${RESET}"