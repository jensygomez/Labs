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
mapfile -t LABS < <(grep -v '^$' "$DB_FILE" | tr -d '\r')

[[ ${#LABS[@]} -eq 0 ]] && { echo -e "${RED}ERROR: No hay laboratorios${RESET}"; exit 1; }
echo -e "${GREEN}OK - Encontré ${#LABS[@]} laboratorio(s)${RESET}"
sleep 0.5

echo -e "${YELLOW}Paso 2: Escogiendo uno al azar...${RESET}"
sleep 0.5
index=$(( RANDOM % ${#LABS[@]} ))
SELECTED_LAB="${LABS[index]}"
echo -e "${GREEN}Laboratorio seleccionado: $SELECTED_LAB${RESET}"
sleep 0.5

echo -e "${YELLOW}Paso 3: Borrando de la base de datos...${RESET}"
sleep 0.5
SELECTED_LAB_CLEAN=$(echo "$SELECTED_LAB" | tr -d '\r')
sed "/^${SELECTED_LAB_CLEAN}$/d" "$DB_FILE" > "$DB_FILE.tmp" && mv "$DB_FILE.tmp" "$DB_FILE"
echo -e "${GREEN}OK - Laboratorio borrado${RESET}"
sleep 0.5

echo -e "${YELLOW}Paso 4: Preparando inyección en VM ($VM_HOST)...${RESET}"
sleep 0.5
patch_path="$BASE_DIR/${SELECTED_LAB}.sh"
[[ -f "$patch_path" ]] || { echo -e "${RED}ERROR: No existe $patch_path${RESET}"; exit 1; }
echo -e "${GREEN}Encontrado: $patch_path${RESET}"
sleep 0.5

echo -e "${CYAN}Paso 5: Copiando script a la VM...${RESET}"
sleep 0.5
if ! scp -i "$SSH_KEY" -o StrictHostKeyChecking=no "$patch_path" "$VM_USER@$VM_HOST:/tmp/lab_setup.sh" >/dev/null 2>&1; then
    echo -e "${RED}✗ FALLÓ la copia (SCP)${RESET}"
    echo "   → Verifica: VM encendida, red OK, clave SSH correcta"
    exit 1
fi
echo -e "${GREEN}✓ Archivo copiado correctamente${RESET}"
sleep 0.5

echo -e "${CYAN}Paso 6: Ejecutando setup como root en la VM...${RESET}"
sleep 0.5
if ! ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$VM_USER@$VM_HOST" bash << EOF
    echo "   → Entrando como $VM_USER..."
    echo "   → Elevando privilegios con sudo..."
    sudo bash /tmp/lab_setup.sh
    echo "   → Limpiando archivo temporal..."
    sudo rm -f /tmp/lab_setup.sh
    echo "   → ¡Setup completado en la VM!"
EOF
then
    echo -e "${RED}✗ FALLÓ la ejecución en la VM${RESET}"
    echo -e "${YELLOW}   Causa más común: sudo pide contraseña.${RESET}"
    echo -e "${YELLOW}   Solución rápida:${RESET}"
    echo "       Conéctate a la VM y ejecuta:"
    echo "         sudo visudo"
    echo "       Añade al final:"
    echo "         student ALL=(ALL) NOPASSWD: ALL"
    exit 1
fi

echo -e "${GREEN}✓ ¡Todo completado perfectamente!${RESET}"
echo -e "${CYAN}=== Laboratorio $SELECTED_LAB inyectado y listo ===${RESET}"
echo -e "${CYAN}Conéctate ahora:${RESET} ssh -i $SSH_KEY $VM_USER@$VM_HOST"
echo -e "${GREEN}¡Éxito total! 🚀${RESET}"