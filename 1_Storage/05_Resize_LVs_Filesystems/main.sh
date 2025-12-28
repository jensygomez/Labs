#!/bin/bash
# ==============================================================================
# RHCSA EX200 - Generador automático de laboratorios Storage
# Módulo principal: selecciona, borra de DB e inyecta el laboratorio en la VM
# Autor: Jensy
# Fecha: 2025
# ==============================================================================

set -euo pipefail   # Seguridad: falla en errores, variables no definidas, etc.

# ==============================================================================
# CONFIGURACIÓN GLOBAL
# ==============================================================================
BASE_DIR="/home/jensy/GitHub/Labs/1_Storage/05_Resize_LVs_Filesystems"
DB_FILE="$BASE_DIR/labs_database.txt"
SSH_KEY="/home/jensy/GitHub/Labs/.ssh/id_rhcsalabs"
VM_USER="student"
VM_HOST="192.168.122.231"
SUDO_PASS="redhat"                  # Contraseña de sudo para student

# Colores para mensajes bonitos
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
RESET='\033[0m'

# ==============================================================================
# PASO 1: Leer la base de datos de laboratorios
# ==============================================================================

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

# ==============================================================================
# PASO 2: Seleccionar un laboratorio al azar
# ==============================================================================
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

# ==============================================================================
# PASO 4: Verificar existencia del script patch
# ==============================================================================
patch_path="$BASE_DIR/${SELECTED_LAB}.sh"
[[ -f "$patch_path" ]] || { echo -e "${RED}ERROR: No existe $patch_path${RESET}"; exit 1; }
echo -e "${GREEN}Encontrado: $patch_path${RESET}"
sleep 0.5


# ==============================================================================
# PASO 5: Copiar el script a la VM
# ==============================================================================
echo -e "${CYAN}Paso 5: Copiando script a la VM...${RESET}"
sleep 0.5


scp -i "$SSH_KEY" -o StrictHostKeyChecking=no "$patch_path" "$VM_USER@$VM_HOST:/tmp/lab_setup.sh" >/dev/null 2>&1
echo -e "${GREEN}✓ Archivo copiado correctamente${RESET}"
sleep 0.5

# ==============================================================================
# PASO 6: Ejecutar el setup en la VM y mostrar el ticket en el host
# ==============================================================================

echo -e "${CYAN}Paso 6: Ejecutando setup y generando ticket en la VM...${RESET}"
sleep 0.5

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$VM_USER@$VM_HOST" bash << 'EOF'
    # Suministrar contraseña de sudo automáticamente
    SUDO_PASS="redhat"

    echo "   → Entrando como student..."
    echo "   → Ejecutando el laboratorio..."
    echo "$SUDO_PASS" | sudo -S bash /tmp/lab_setup.sh



    # Si el script generó un ticket en /tmp/current_lab_ticket.txt, mostrarlo con colores
    if [[ -f /home/student/lab_ticket.txt ]]; then
        echo
        echo "=== TICKET DEL LABORATORIO GENERADO ==="
        cat /home/student/lab_ticket.txt
        echo "=== FIN DEL TICKET ==="
    else
        echo "   → Laboratorio ejecutado, pero no se encontró ticket"
    fi


    echo "   → Limpiando archivo temporal..."
    echo "$SUDO_PASS" | sudo -S rm -f /tmp/lab_setup.sh
EOF

# ==============================================================================
# FINAL: Mensaje de éxito en el host
# ==============================================================================

echo
echo -e "${CYAN}==================================================${RESET}"
echo -e "${GREEN}¡LABORATORIO $SELECTED_LAB INYECTADO CON ÉXITO!${RESET}"
echo -e "${GREEN}El ticket con pistas apareció arriba (directo desde la VM)${RESET}"
echo -e "${CYAN}También está guardado en la VM para el estudiante:${RESET}"
echo -e "${YELLOW}    /home/student/lab_ticket.txt${RESET}"

echo
echo -e "${CYAN}Conéctate y resuelve como administrador real:${RESET}"
echo -e "${YELLOW}    ssh -i $SSH_KEY $VM_USER@$VM_HOST${RESET}"
echo -e "${CYAN}==================================================${RESET}"
echo -e "${GREEN}¡Listo para practicar troubleshooting RHCSA! 🚀${RESET}"