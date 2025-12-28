#!/bin/bash
set -euo pipefail

BASE_DIR="/home/jensy/GitHub/Labs/1_Storage/05_Resize_LVs_Filesystems"
DB_FILE="$BASE_DIR/labs_database.txt"
SSH_KEY="/home/jensy/GitHub/Labs/.ssh/id_rhcsalabs"

VM_USER="student"
VM_HOST="192.168.122.231"

# Colores
RED="\033[1;31m"; GREEN="\033[1;32m"; YELLOW="\033[1;33m"; BLUE="\033[1;34m"; CYAN="\033[1;36m"; RESET="\033[0m"

read_lab_db() {
    [[ -f "$DB_FILE" ]] || { echo -e "${RED}ERROR: DB no encontrada${RESET}"; exit 1; }
    mapfile -t LABS < "$DB_FILE"
    [[ ${#LABS[@]} -gt 0 ]] || { echo -e "${RED}ERROR: DB vacía${RESET}"; exit 1; }
}

choose_lab() {
    SELECTED_LAB=$(shuf -n1 "$DB_FILE")
    echo -e "${GREEN}Laboratorio seleccionado:${RESET} $SELECTED_LAB"
}

remove_lab_from_db() {
    grep -vFx "$SELECTED_LAB" "$DB_FILE" > "$DB_FILE.tmp"
    mv "$DB_FILE.tmp" "$DB_FILE"
}

inject_setup_vm() {
    echo -e "${CYAN}Inyectando setup en la VM...${RESET}"
    PATCH_PATH="$BASE_DIR/${SELECTED_LAB}.sh"

    [[ -f "$PATCH_PATH" ]] || { echo -e "${RED}ERROR: Patch no encontrado: $PATCH_PATH${RESET}"; exit 1; }

    scp -i "$SSH_KEY" -o StrictHostKeyChecking=no "$PATCH_PATH" "$VM_USER@$VM_HOST:/tmp/lab_setup.sh"

    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$VM_USER@$VM_HOST" bash << EOF
        sudo bash /tmp/lab_setup.sh
        sudo rm -f /tmp/lab_setup.sh
EOF

    echo -e "${GREEN}Setup inyectado correctamente.${RESET}"
}

verify_injection() {
    echo -e "${CYAN}Verificando estado del laboratorio...${RESET}"
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$VM_USER@$VM_HOST" bash << EOF
        if sudo lvdisplay /dev/vg_exam/lv_data >/dev/null 2>&1; then
            echo "LV existe"
            sudo lvs -o lv_name,lv_size vg_exam/lv_data
            sudo df -h /data | grep /data
        else
            echo "FAIL: LV no existe"
            exit 1
        fi
EOF
}

show_ticket() {
    echo -e "${YELLOW}=========================================${RESET}"
    echo -e "${BLUE}     RHCSA EX200 - Storage Lab${RESET}"
    echo -e "${CYAN}Variación:${RESET} $SELECTED_LAB"
    echo -e "${CYAN}Objetivo:${RESET} Redimensionar Logical Volumes y Filesystems"
    echo -e "${CYAN}Tarea:${RESET} El LV ha sido extendido, pero el filesystem NO se ha actualizado."
    echo -e "${CYAN}Debes:${RESET} resize2fs /dev/vg_exam/lv_data (o equivalente para XFS en otras variaciones)"

    # Obtener info real de la VM
    INFO=$(ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$VM_USER@$VM_HOST" bash << 'EOF'
        PV=$(sudo vgs -o pv_name --noheadings vg_exam | xargs)
        LV_SIZE=$(sudo lvs -o lv_size --noheadings --units g vg_exam/lv_data | xargs)
        FS_SIZE=$(sudo df -BG /data | tail -1 | awk '{print $2}')
        echo "PV:$PV"
        echo "LV_SIZE:$LV_SIZE"
        echo "FS_SIZE:$FS_SIZE"
EOF
    )

    PV=$(echo "$INFO" | grep ^PV: | cut -d: -f2)
    LV_SIZE=$(echo "$INFO" | grep ^LV_SIZE: | cut -d: -f2)
    FS_SIZE=$(echo "$INFO" | grep ^FS_SIZE: | cut -d: -f2)

    echo -e "${CYAN}Disco físico usado:${RESET} /dev/$PV"
    echo -e "${CYAN}Volume Group:${RESET} vg_exam"
    echo -e "${CYAN}Logical Volume:${RESET} lv_data  (${LV_SIZE} actual)"
    echo -e "${CYAN}Filesystem actual:${RESET} ${FS_SIZE} (debe crecer)"
    echo -e "${CYAN}Punto de montaje:${RESET} /data"
    echo -e "${YELLOW}=========================================${RESET}"
}

# MAIN
read_lab_db
choose_lab
remove_lab_from_db
inject_setup_vm
verify_injection
show_ticket