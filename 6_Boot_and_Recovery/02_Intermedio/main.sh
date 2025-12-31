#!/bin/bash
# ==============================================================================
# RHCSA EX200 - Generador automático de laboratorios Boot & Recovery
# Módulo principal: selecciona, borra de DB e inyecta el laboratorio en la VM
# Autor: Jensy
# Fecha: 2025
# ==============================================================================

set -euo pipefail   # Seguridad: falla en errores, variables no definidas, etc.

# ==============================================================================
# CONFIGURACIÓN GLOBAL
# ==============================================================================
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CONFIG_FILE="$BASE_DIR/config/lab.conf"

[[ -f "$CONFIG_FILE" ]] || {
    echo "ERROR: Falta $CONFIG_FILE"
    exit 1
}

source "$CONFIG_FILE"

# ==============================================================================
# COLORES (para usar en el host)
# ==============================================================================
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
RESET='\033[0m'

# ==============================================================================
# PASO 1: Leer la base de datos de laboratorios con contadores
# ==============================================================================

echo -e "${YELLOW}Paso 1: Leyendo la base de datos con contadores...${RESET}"
sleep 0.5

declare -A LAB_COUNTERS

while IFS='=' read -r lab count; do
    [[ -z "$lab" ]] && continue
    LAB_COUNTERS["$lab"]="$count"
done < "$DB_FILE"

[[ ${#LAB_COUNTERS[@]} -eq 0 ]] && {
    echo -e "${RED}ERROR: Base de datos vacía${RESET}"
    exit 1
}

echo -e "${GREEN}OK - Encontré ${#LAB_COUNTERS[@]} laboratorio(s)${RESET}"
sleep 0.5

# ==============================================================================
# PASO 2: Seleccionar laboratorio con menor contador (azar controlado)
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
# PASO 3: Incrementar contador del laboratorio seleccionado
# ==============================================================================

echo -e "${YELLOW}Paso 3: Actualizando contador en la base de datos...${RESET}"
sleep 0.5

NEW_COUNT=$(( LAB_COUNTERS["$SELECTED_LAB"] + 1 ))

sed -i "s/^${SELECTED_LAB}=${LAB_COUNTERS[$SELECTED_LAB]}/${SELECTED_LAB}=${NEW_COUNT}/" "$DB_FILE"

echo -e "${GREEN}OK - $SELECTED_LAB ahora tiene contador $NEW_COUNT${RESET}"
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



# Selector de ticket según laboratorio (fácil de extender)
case "$SELECTED_LAB" in
    inject_V4)
        show_ticket_inject_V4
        ;;
    *)
        echo -e "${YELLOW}Advertencia: Aún no hay ticket definido para $SELECTED_LAB${RESET}"
        ;;
esac

echo -e "${GREEN}¡Ticket mostrado arriba! Ahora inyectando el fallo en la VM...${RESET}"
sleep 1.5



# ==============================================================================
# PASO 6: Mostrar ticket (local) y ejecutar inyección en VM con progreso
# ==============================================================================
echo -e "${CYAN}Paso 6: Mostrando ticket y ejecutando inyección en la VM...${RESET}"
sleep 0.5

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$VM_USER@$VM_HOST" bash << 'EOF'
    echo "   → Conectado como $VM_USER"

    # 1. Mostrar ticket (visible en host, con clear y colores)
    echo "   → Ejecutando visualización del ticket..."
    sudo bash /tmp/lab_setup.sh --show-ticket

    echo
    # 2. Inyectar fallo (con progreso detallado)
    echo "   → Inyectando fallo en el sistema (requiere root)..."
    echo "$SUDO_PASS" | sudo -S bash /tmp/lab_setup.sh --inject

    echo
    echo "   → Laboratorio inyectado correctamente"
    echo "   → Limpiando archivo temporal..."
    sudo rm -f /tmp/lab_setup.sh

    echo "   → Todo completado en la VM"
EOF





# ==============================================================================
# FINAL: Mensaje de éxito en el host
# ==============================================================================

echo
echo -e "${CYAN}==================================================${RESET}"
echo -e "${GREEN}¡LABORATORIO $SELECTED_LAB INYECTADO CON ÉXITO!${RESET}"
echo
echo -e "${CYAN}Conéctate y resuelve como administrador real:${RESET}"
echo -e "${YELLOW}    ssh -i $SSH_KEY $VM_USER@$VM_HOST${RESET}"
echo -e "${CYAN}==================================================${RESET}"
echo -e "${GREEN}¡Listo para practicar troubleshooting Boot & Recovery RHCSA! 🚀${RESET}"