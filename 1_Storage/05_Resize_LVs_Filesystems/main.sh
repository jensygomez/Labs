#!/bin/bash
# RHCSA EX200 – Storage Labs
# Main Controller (Linux philosophy: simple, explicit, modular)

set -euo pipefail

# ==============================================
# CONFIGURACIÓN GLOBAL
# ==============================================

BASE_DIR="/home/jensy/GitHub/Labs/1_Storage/05_Resize_LVs_Filesystems"
DB_FILE="$BASE_DIR/labs_database.txt"
SSH_KEY="/home/jensy/GitHub/Labs/.ssh/id_rhcsalabs"

VM_USER="student"
VM_HOST="192.168.122.231"

# ==============================================
# COLORES
# ==============================================

RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RESET="\033[0m"

# ==============================================
# 1. Leer base de datos
# ==============================================
read_lab_db() {
    [[ -f "$DB_FILE" ]] || {
        echo -e "${RED}ERROR: DB no encontrada: $DB_FILE${RESET}"
        exit 1
    }

    mapfile -t LABS < "$DB_FILE"

    [[ ${#LABS[@]} -gt 0 ]] || {
        echo -e "${RED}ERROR: DB vacía${RESET}"
        exit 1
    }
}

# ==============================================
# 2. Randomizar y escoger laboratorio
# ==============================================
choose_lab() {
    SELECTED_LAB=$(shuf -n1 "$DB_FILE")
    echo -e "${GREEN}Laboratorio seleccionado:${RESET} $SELECTED_LAB"
}

# ==============================================
# 3. Eliminar laboratorio usado de la DB
# ==============================================
remove_lab_from_db() {
    grep -vFx "$SELECTED_LAB" "$DB_FILE" > "$DB_FILE.tmp"
    mv "$DB_FILE.tmp" "$DB_FILE"
}

# ==============================================
# 4. Source del patch seleccionado
# ==============================================
source_patch() {
    PATCH_PATH="$BASE_DIR/$SELECTED_LAB.sh"

    [[ -f "$PATCH_PATH" ]] || {
        echo -e "${RED}ERROR: Patch no encontrado: $PATCH_PATH${RESET}"
        exit 1
    }

    source "$PATCH_PATH"
}

# ==============================================
# 5. Inyectar setup en la VM (corregido)
# ==============================================
inject_setup_vm() {
    echo -e "${CYAN}Inyectando setup en la VM...${RESET}"

    # Ruta completa del patch en host
    PATCH_PATH="$BASE_DIR/$SELECTED_LAB.sh"

    # Copiar patch a VM (temporalmente)
    scp -i "$SSH_KEY" -o StrictHostKeyChecking=no "$PATCH_PATH" "$VM_USER@$VM_HOST:/tmp/$SELECTED_LAB.sh"

    # Ejecutar patch en la VM como root
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$VM_USER@$VM_HOST" bash << EOF
        sudo bash /tmp/$SELECTED_LAB.sh
EOF

    # Opcional: eliminar el patch temporal de la VM
    ssh -i "$SSH_KEY" "$VM_USER@$VM_HOST" "rm -f /tmp/$SELECTED_LAB.sh"

    echo -e "${GREEN}Setup inyectado en la VM correctamente.${RESET}"
}


# ==============================================
# 6. Verificar inyección
# ==============================================
verify_injection() {
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no \
        "$VM_USER@$VM_HOST" \
        "sudo lvdisplay /dev/vg_exam/lv_data >/dev/null 2>&1" \
        && echo -e "${GREEN}Setup inyectado correctamente.${RESET}" \
        || {
            echo -e "${RED}ERROR: Setup no inyectado.${RESET}"
            exit 1
        }
}

# ==============================================
# 7. Mostrar ticket
# ==============================================
show_ticket() {
    ticket_storage
}

# ==============================================
# MAIN
# ==============================================
read_lab_db
choose_lab
remove_lab_from_db
source_patch
inject_setup_vm
verify_injection
show_ticket
