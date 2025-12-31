#!/bin/bash
# ==============================================================================
# RHCSA EX200 - Generador automático de laboratorios Boot & Recovery
# Módulo principal: selecciona, actualiza DB e inyecta el laboratorio en la VM
# Autor: Jensy - 2025
# ==============================================================================

set -euo pipefail

# ==============================================================================
# CONFIGURACIÓN GLOBAL
# ==============================================================================
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$BASE_DIR/config/lab.conf"

[[ -f "$CONFIG_FILE" ]] || { echo "ERROR: Falta $CONFIG_FILE"; exit 1; }
source "$CONFIG_FILE"

GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
RESET='\033[0m'

# ==============================================================================
# Verificación previa de conexión SSH + sudo (silenciosa y robusta)
# ==============================================================================
verify_connection() {
    echo -e "${CYAN}Verificando conexión a la VM y acceso sudo...${RESET}"

    # Prueba SSH sin mensajes innecesarios
    if ! ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
             -o BatchMode=yes -q "$VM_USER@$VM_HOST" exit 2>/dev/null; then
        echo -e "${RED}✗ Error: No se puede conectar por SSH a $VM_HOST${RESET}"
        exit 1
    fi

    # Prueba sudo (con pipe de password y silencioso)
    if ! ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o BatchMode=yes -q \
             "$VM_USER@$VM_HOST" "echo '$SUDO_PASS' | sudo -S whoami" 2>/dev/null | \
             grep -q "^root$"; then
        echo -e "${RED}✗ Error: sudo falla (password incorrecta o configuración)${RESET}"
        exit 1
    fi

    echo -e "${GREEN}✓ Conexión SSH y sudo verificados correctamente${RESET}"
    sleep 0.5
}

# ==============================================================================
# PASO 1: Leer base de datos
# ==============================================================================
echo -e "${YELLOW}Paso 1: Leyendo la base de datos con contadores...${RESET}"
sleep 0.5

declare -A LAB_COUNTERS
while IFS='=' read -r lab count; do
    [[ -z "$lab" || "$lab" == "#"* ]] && continue
    LAB_COUNTERS["$lab"]="$count"
done < "$DB_FILE"

[[ ${#LAB_COUNTERS[@]} -eq 0 ]] && {
    echo -e "${RED}ERROR: Base de datos vacía o sin laboratorios${RESET}"
    exit 1
}

echo -e "${GREEN}OK - Encontré ${#LAB_COUNTERS[@]} laboratorio(s)${RESET}"
sleep 0.5

# ==============================================================================
# PASO 2: Seleccionar laboratorio (menor contador + azar)
# ==============================================================================
MIN_COUNT=$(printf "%s\n" "${LAB_COUNTERS[@]}" | sort -n | head -1)
CANDIDATES=()
for lab in "${!LAB_COUNTERS[@]}"; do
    [[ "${LAB_COUNTERS[$lab]}" -eq "$MIN_COUNT" ]] && CANDIDATES+=("$lab")
done

index=$(( RANDOM % ${#CANDIDATES[@]} ))
SELECTED_LAB="${CANDIDATES[index]}"

echo -e "${GREEN}Laboratorio seleccionado: $SELECTED_LAB (uso=$MIN_COUNT)${RESET}"
sleep 0.5

# ==============================================================================
# PASO 3: Actualizar contador
# ==============================================================================
echo -e "${YELLOW}Paso 3: Actualizando contador en la base de datos...${RESET}"
sleep 0.5

NEW_COUNT=$(( LAB_COUNTERS["$SELECTED_LAB"] + 1 ))
sed -i "s/^${SELECTED_LAB}=.*$/${SELECTED_LAB}=$NEW_COUNT/" "$DB_FILE"

echo -e "${GREEN}OK - $SELECTED_LAB ahora tiene contador $NEW_COUNT${RESET}"
sleep 0.5

# ==============================================================================
# PASO 4: Verificar script
# ==============================================================================
patch_path="$BASE_DIR/${SELECTED_LAB}.sh"
[[ -f "$patch_path" ]] || {
    echo -e "${RED}ERROR: No existe el script $patch_path${RESET}"
    exit 1
}
echo -e "${GREEN}Encontrado: $patch_path${RESET}"
sleep 0.5

# ==============================================================================
# Verificamos conexión ANTES de continuar
# ==============================================================================
verify_connection

# ==============================================================================
# Mostrar ticket LOCAL (source + función)
# ==============================================================================
echo -e "${CYAN}Mostrando ticket del laboratorio $SELECTED_LAB...${RESET}"
sleep 1

source "$patch_path"  # Cargamos las funciones del lab seleccionado
show_ticket           # Ejecutamos localmente en el host

echo
echo -e "${YELLOW}Presiona Enter para inyectar el laboratorio en la VM...${RESET}"
read -r


# ==============================================================================
# Verificamos conexión ANTES de continuar
# ==============================================================================
verify_connection

# ==============================================================================
# PASO 5 y 6: Copiar y aplicar laboratorio en la VM (silencioso total)
# ==============================================================================
echo -e "${CYAN}Copiando y aplicando laboratorio en la VM...${RESET}"
sleep 0.5

# Copiar el script de forma silenciosa
scp -q -i "$SSH_KEY" -o StrictHostKeyChecking=no \
    "$patch_path" "$VM_USER@$VM_HOST:/tmp/lab_setup.sh" >/dev/null 2>&1

# Ejecutar todo en la VM de forma completamente silenciosa
ssh -T -q -i "$SSH_KEY" -o StrictHostKeyChecking=no "$VM_USER@$VM_HOST" << EOF
echo '$SUDO_PASS' | sudo -S chmod +x /tmp/lab_setup.sh >/dev/null 2>&1
echo '$SUDO_PASS' | sudo -S /tmp/lab_setup.sh --apply >/dev/null 2>&1
echo '$SUDO_PASS' | sudo -S rm -f /tmp/lab_setup.sh >/dev/null 2>&1
EOF

echo -e "${GREEN}¡Laboratorio $SELECTED_LAB inyectado con éxito!${RESET}"

# ==============================================================================
# Mensaje final
# ==============================================================================
echo
echo -e "${CYAN}==================================================${RESET}"
echo -e "${GREEN}¡LABORATORIO $SELECTED_LAB LISTO!${RESET}"
echo
echo -e "${CYAN}Conéctate y resuélvelo:${RESET}"
echo -e "${YELLOW}    ssh -i $SSH_KEY $VM_USER@$VM_HOST${RESET}"
echo -e "${CYAN}==================================================${RESET}"
echo -e "${GREEN}¡A practicar Boot & Recovery RHCSA! 🚀${RESET}"