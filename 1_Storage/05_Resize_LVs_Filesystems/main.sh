#!/bin/bash
# Main script RHCSA EX200 – Storage Labs
# Todo modularizado en funciones

set -e

# --- Configuración ---
DB_FILE="./1_Storage/05_Resize_LVs_Filesystems/labs_database.txt"   # Archivo que contiene lista de injects
VM_USER="usuario"                                                   # Usuario normal para SSH
VM_HOST="192.168.100.10"                                            # IP de la VM
VM_PASS="redhat"                                                    # Contraseña de SSH (si usas sshpass)
VM_ROOT="root"                                                      # Usuario root dentro de la VM

# Colores para ticket
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RESET="\033[0m"

# --- Funciones ---

# ==============================================
# 1. Leer base de datos
# ==============================================
read_lab_db() {
    if [[ ! -f "$DB_FILE" ]]; then
        echo -e "${RED}Archivo de base de datos no encontrado: $DB_FILE${RESET}"
        exit 1
    fi
    mapfile -t LABS < "$DB_FILE"                                    # Carga todas las líneas en un array
}

# ==============================================
# 2. Randomizar y escoger un laboratorio
# ==============================================
choose_lab() {
    RANDOM_INDEX=$(( RANDOM % ${#LABS[@]} ))
    SELECTED_LAB="${LABS[$RANDOM_INDEX]}"
    echo -e "${GREEN}Laboratorio seleccionado: $SELECTED_LAB${RESET}"
}

# ==============================================
# 3. Borrar la línea escogida de la base de datos
# ==============================================
remove_lab_from_db() {
    grep -vFx "$SELECTED_LAB" "$DB_FILE" > "${DB_FILE}.tmp" && mv "${DB_FILE}.tmp" "$DB_FILE"
}

# ==============================================
# 4. Source del patch seleccionado
# ==============================================
source_patch() {
    PATCH_PATH="./$SELECTED_LAB.sh"
    if [[ ! -f "$PATCH_PATH" ]]; then
        echo -e "${RED}Patch no encontrado: $PATCH_PATH${RESET}"
        exit 1
    fi
    source "$PATCH_PATH"
}

# ==============================================
# 5. Conectar a la VM y ejecutar setup_storage()
# ==============================================

inject_setup_vm() {
    echo -e "${CYAN}Conectando a la VM y ejecutando setup...${RESET}"

    ssh -i /home/jensy/GitHub/Labs/.ssh/id_rhcsalabs -o StrictHostKeyChecking=no "$VM_USER@$VM_HOST" bash << 'EOF'
        sudo -i
        setup_storage
EOF
}

# ==============================================
# 6. Verificar inyección (ejemplo simple: verificar LV)
# ==============================================
verify_injection() {
    # Aquí podrías hacer un SSH y comprobar el LV, ejemplo simple:
    INJECTED=$(sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no "$VM_USER@$VM_HOST" "sudo lvdisplay /dev/vg_exam/lv_data >/dev/null 2>&1 && echo OK || echo FAIL")
    if [[ "$INJECTED" == "OK" ]]; then
        echo -e "${GREEN}Setup inyectado correctamente.${RESET}"
    else
        echo -e "${RED}Error: setup no inyectado.${RESET}"
        exit 1
    fi
}

# ==============================================
# 7. Mostrar ticket
# ==============================================
show_ticket() {
    ticket_storage  # La función ticket_storage se debe definir en el patch
}

# --- EJECUCIÓN MAIN ---
read_lab_db
choose_lab
remove_lab_from_db
source_patch
inject_setup_vm
verify_injection
show_ticket


