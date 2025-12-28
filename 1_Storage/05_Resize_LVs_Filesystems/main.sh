#!/bin/bash
set -euo pipefail

BASE_DIR="/home/jensy/GitHub/Labs/1_Storage/05_Resize_LVs_Filesystems"
DB_FILE="$BASE_DIR/labs_database.txt"
SSH_KEY="/home/jensy/GitHub/Labs/.ssh/id_rhcsalabs"

VM_USER="student"
VM_HOST="192.168.122.231"

# Colores
RED="\033[1;31m"; GREEN="\033[1;32m"; YELLOW="\033[1;33m"; BLUE="\033[1;34m"; CYAN="\033[1;36m"; RESET="\033[0m"

echo -e "${BLUE}=== Iniciando generador de laboratorio RHCSA Storage ===${RESET}"

read_lab_db() {
    [[ -f "$DB_FILE" ]] || { echo -e "${RED}ERROR: DB no encontrada: $DB_FILE${RESET}"; exit 1; }
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
    echo -e "${YELLOW}Laboratorio removido de la base de datos.${RESET}"
}

inject_setup_vm() {
    echo -e "${CYAN}Inyectando setup en la VM ($VM_HOST)...${RESET}"

    PATCH_PATH="$BASE_DIR/${SELECTED_LAB}.sh"
    echo "Ruta del patch: $PATCH_PATH"

    if [[ ! -f "$PATCH_PATH" ]]; then
        echo -e "${RED}ERROR: No existe el archivo $PATCH_PATH${RESET}"
        exit 1
    fi

    echo "Copiando script a la VM con SCP..."
    if ! scp -i "$SSH_KEY" -o StrictHostKeyChecking=no -v "$PATCH_PATH" "$VM_USER@$VM_HOST:/tmp/lab_setup.sh"; then
        echo -e "${RED}FALLÓ el SCP. Problema de conexión o clave SSH?${RESET}"
        exit 1
    fi
    echo -e "${GREEN}SCP completado.${RESET}"

    echo "Ejecutando script en la VM como root..."
    if ! ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -v "$VM_USER@$VM_HOST" bash << 'EOF'
        echo "=== Intentando ejecutar con sudo ==="
        sudo -n bash /tmp/lab_setup.sh || { echo "Fallo sudo (¿pide password?)"; exit 1; }
        sudo -n rm -f /tmp/lab_setup.sh
        echo "=== Script ejecutado y limpiado ==="
EOF
    then
        echo -e "${RED}FALLÓ la ejecución en la VM. Lo más probable: sudo pide contraseña.${RESET}"
        echo -e "${YELLOW}Solución: Configura sudo sin password para 'student' (ver abajo)${RESET}"
        exit 1
    fi

    echo -e "${GREEN}Setup inyectado correctamente en la VM.${RESET}"
}

# (el resto de funciones verify_injection y show_ticket igual que antes)

verify_injection() {
    echo -e "${CYAN}Verificando estado del laboratorio...${RESET}"
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$VM_USER@$VM_HOST" bash << 'EOF'
        if sudo -n lvdisplay /dev/vg_exam/lv_data >/dev/null 2>&1; then
            echo "Logical Volume existe"
            sudo lvs -o lv_name,lv_size vg_exam/lv_data
            df -h /data 2>/dev/null | grep /data || echo "No montado aún"
        else
            echo "FAIL: lv_data no existe"
        fi
EOF
}

show_ticket() {
    # (igual que tu versión anterior, pero con manejo si INFO falla)
    echo -e "${YELLOW}=========================================${RESET}"
    echo -e "${BLUE}     RHCSA EX200 - Storage Lab${RESET}"
    echo -e "${CYAN}Variación:${RESET} $SELECTED_LAB"
    echo -e "${CYAN}Tarea:${RESET} Extender el filesystem tras lvextend"
    echo -e "${CYAN}Comando esperado:${RESET} resize2fs /dev/vg_exam/lv_data"

    INFO=$(ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$VM_USER@$VM_HOST" bash << 'EOF' || echo "FAIL"
        PV=$(sudo -n vgs -o pv_name --noheadings vg_exam 2>/dev/null | xargs | sed 's|.*/||')
        LV_SIZE=$(sudo -n lvs -o lv_size --noheadings --units g vg_exam/lv_data 2>/dev/null | xargs)
        FS_SIZE=$(df -BG /data 2>/dev/null | tail -1 | awk '{print $2}')
        echo "PV:$PV"
        echo "LV_SIZE:$LV_SIZE"
        echo "FS_SIZE:$FS_SIZE"
EOF
    )

    if echo "$INFO" | grep -q FAIL; then
        echo -e "${RED}No se pudo obtener info de la VM (¿sudo falla?)${RESET}"
    else
        PV=$(echo "$INFO" | grep ^PV: | cut -d: -f2)
        LV_SIZE=$(echo "$INFO" | grep ^LV_SIZE: | cut -d: -f2)
        FS_SIZE=$(echo "$INFO" | grep ^FS_SIZE: | cut -d: -f2)

        echo -e "${CYAN}Disco físico usado:${RESET} /dev/$PV (¡aleatorio!)"
        echo -e "${CYAN}Volume Group:${RESET} vg_exam"
        echo -e "${CYAN}Logical Volume:${RESET} lv_data → $LV_SIZE"
        echo -e "${CYAN}Filesystem actual:${RESET} $FS_SIZE (debe crecer)"
        echo -e "${CYAN}Punto de montaje:${RESET} /data"
    fi
    echo -e "${YELLOW}=========================================${RESET}"
}

# MAIN
read_lab_db
choose_lab
remove_lab_from_db
inject_setup_vm
verify_injection
show_ticket