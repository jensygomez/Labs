#!/bin/bash
# /home/jensy/GitHub/Labs/1_Storage/05_Resize_LVs_Filesystems/ticket_inc2471.sh
# Ticket CLI RHCSA - sincronizado con lab activo

set -e

LAB_DIR="/home/jensy/GitHub/Labs/1_Storage/05_Resize_LVs_Filesystems"
ACTIVE_LAB_FILE="$LAB_DIR/active_lab.tmp"

# Colores
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; PURPLE='\033[0;35m'; NC='\033[0m'

# 1. Validamos que exista lab activo
if [[ ! -f "$ACTIVE_LAB_FILE" ]] || [[ ! -s "$ACTIVE_LAB_FILE" ]]; then
    echo -e "${RED}[ERROR] No se encontró lab activo. Ejecuta run_lab.sh primero.${NC}"
    exit 1
fi

ACTIVE_LAB=$(cat "$ACTIVE_LAB_FILE")

# 2. Asignamos ticket y descripción según lab activo
case "$ACTIVE_LAB" in
    inject_V1.sh)
        TICKET_ID="INC-2471"
        INCIDENT_DESC="Dos nuevos volúmenes fueron provisionados para uso de aplicaciones internas."
        ;;
    inject_V2.sh)
        TICKET_ID="INC-2472"
        INCIDENT_DESC="Extensión de volumen lógico no reflejada en filesystem."
        ;;
    inject_V3.sh)
        TICKET_ID="INC-2473"
        INCIDENT_DESC="fstab con nombres de dispositivo en lugar de UUID, riesgo de persistencia."
        ;;
    *)
        echo -e "${RED}[ERROR] Lab no reconocido: $ACTIVE_LAB${NC}"
        exit 1
        ;;
esac

CATEGORY="Linux Storage"
PRIORITY="Media"
SYSTEM="AlmaLinux 10"
USER="Operaciones"

# 3. Mostramos ticket en CLI
clear
echo -e "${CYAN}============================================================${NC}"
echo -e "${BLUE}📌 Ticket ID: ${PURPLE}${TICKET_ID}${NC}"
echo -e "${BLUE}Categoría: ${YELLOW}${CATEGORY}${NC}"
echo -e "${BLUE}Prioridad: ${YELLOW}${PRIORITY}${NC}"
echo -e "${BLUE}Sistema: ${GREEN}${SYSTEM}${NC}"
echo -e "${BLUE}Usuario afectado: ${GREEN}${USER}${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${BLUE}Descripción del incidente:${NC}\n"
echo -e "${INCIDENT_DESC}\n"
echo -e "${BLUE}Se requiere:${NC}"
echo -e "- Diagnosticar el problema"
echo -e "- Corregirlo de forma persistente"
echo -e "- Validar que el sistema quede estable tras reboot"
echo -e "- No se permite reinstalar el sistema ni eliminar datos existentes\n"
echo -e "${BLUE}Rol esperado (cómo debes actuar):${NC}"
echo -e "- Actúa como Administrador Linux Junior–Mid en evaluación RHCSA"
echo -e "- No asumas nada"
echo -e "- Valida cada paso"
echo -e "- Usa herramientas estándar"
echo -e "- Documenta mentalmente lo que haces"
echo -e "${CYAN}============================================================${NC}\n"
