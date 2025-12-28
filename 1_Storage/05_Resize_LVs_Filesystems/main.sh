#!/bin/bash
# RHCSA Labs - Versión simple con mensajes claros y pausas
set -euo pipefail

BASE_DIR="/home/jensy/GitHub/Labs/1_Storage/05_Resize_LVs_Filesystems"
DB_FILE="$BASE_DIR/labs_database.txt"
SSH_KEY="/home/jensy/GitHub/Labs/.ssh/id_rhcsalabs"
VM_USER="student"
VM_HOST="192.168.122.231"

# Colores bonitos
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
mapfile -t LABS < "$DB_FILE"
if [[ ${#LABS[@]} -eq 0 ]]; then
    echo -e "${RED}ERROR: La base de datos está vacía${RESET}"
    exit 1
fi
echo -e "${GREEN}OK - Encontré ${#LABS[@]} laboratorio(s) en la lista${RESET}"
sleep 0.5

echo -e "${YELLOW}Paso 2: Escogiendo uno al azar...${RESET}"
sleep 0.5
index=$(( RANDOM % ${#LABS[@]} ))
SELECTED_LAB="${LABS[index]}"
echo -e "${GREEN}Laboratorio seleccionado: $SELECTED_LAB${RESET}"
sleep 0.5

echo -e "${YELLOW}Paso 3: Borrando $SELECTED_LAB de la lista...${RESET}"
sleep 0.5
grep -vFx "$SELECTED_LAB" "$DB_FILE" > "$DB_FILE.tmp"
mv "$DB_FILE.tmp" "$DB_FILE"
echo -e "${GREEN}OK - Laboratorio borrado de la base de datos${RESET}"
sleep 0.5

echo -e "${YELLOW}Paso 4: Intentando conectar a la VM ($VM_HOST)...${RESET}"
sleep 0.5
patch_path="$BASE_DIR/${SELECTED_LAB}.sh"
if [[ ! -f "$patch_path" ]]; then
    echo -e "${RED}ERROR: No existe el archivo $patch_path${RESET}"
    exit 1
fi

echo -e "${CYAN}Copiando el script a la VM...${RESET}"
sleep 0.5
if ! scp -i "$SSH_KEY" -o StrictHostKeyChecking=no "$patch_path" "$VM_USER@$VM_HOST:/tmp/lab_setup.sh" >/dev/null 2>&1; then
    echo -e "${RED}FALLÓ la copia (SCP)${RESET}"
    echo "   Posibles causas: clave SSH mala, VM apagada o red mala"
    exit 1
fi
echo -e "${GREEN}OK - Archivo copiado${RESET}"
sleep 0.5

echo -e "${CYAN}Ejecutando el setup como root en la VM...${RESET}"
sleep 0.5
if ! ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$VM_USER@$VM_HOST" bash << 'EOF'
    echo "   Entrando como student..."
    echo "   Elevando a root con sudo..."
    sudo bash /tmp/lab_setup.sh
    sudo rm -f /tmp/lab_setup.sh
    echo "   Listo en la VM"
EOF
then
    echo -e "${RED}FALLÓ la ejecución en la VM${RESET}"
    echo "   Causa más común: sudo pide la contraseña 'redhat'"
    echo "   Solución: ejecuta en la VM:  sudo visudo"
    echo "             y añade esta línea al final:"
    echo "             student ALL=(ALL) NOPASSWD: ALL"
    exit 1
fi

echo -e "${GREEN}OK - Todo completado perfectamente${RESET}"
echo -e "${CYAN}=== ¡Laboratorio $SELECTED_LAB listo en la VM! ===${RESET}"
echo -e "${CYAN}Conéctate con: ssh -i $SSH_KEY $VM_USER@$VM_HOST${RESET}"