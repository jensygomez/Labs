#!/bin/bash
# ===================================================================================
# LAB ENGINE - GOLDEN BASE
# Directorio: ~/Labs/Golden-Base
# ===================================================================================

LAB_DIR="$(dirname "$(realpath "$0")")/Golden-Base"

# ── Colores ─────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── Detectar labs disponibles ────────────────────────────────────────────────────
contar_labs() {
    ls "$LAB_DIR"/lab-*.sh 2>/dev/null | wc -l
}

# ── Ejecutar labs en cadena ──────────────────────────────────────────────────────
ejecutar_hasta() {
    local TARGET=$1
    echo ""
    for i in $(seq 1 $TARGET); do
        LAB=$(printf "$LAB_DIR/lab-%03d.sh" $i)
        if [ -f "$LAB" ]; then
            echo -e "${CYAN}══════════════════════════════════════════${NC}"
            echo -e "${CYAN}  Ejecutando: lab-$(printf '%03d' $i).sh${NC}"
            echo -e "${CYAN}══════════════════════════════════════════${NC}"
            bash "$LAB"
            if [ $? -ne 0 ]; then
                echo -e "${RED}✗ Error en lab-$(printf '%03d' $i).sh — abortando.${NC}"
                exit 1
            fi
            echo -e "${GREEN}✔ lab-$(printf '%03d' $i).sh completado${NC}"
            echo ""
        else
            echo -e "${RED}✗ $LAB no encontrado — abortando.${NC}"
            exit 1
        fi
    done
    # Imprimir topología del último lab ejecutado
    local ULTIMO=$(printf "$LAB_DIR/lab-%03d.sh" $TARGET)
    source "$ULTIMO"
    print_topology
}

# ── Limpiar entorno ──────────────────────────────────────────────────────────────
limpiar_entorno() {
    echo ""
    echo -e "${YELLOW}Limpiando namespaces...${NC}"
    for ns in $(ip netns list | awk '{print $1}'); do
        ip netns del "$ns" 2>/dev/null
        echo -e "  ${RED}✗ Eliminado: $ns${NC}"
    done

    echo -e "${YELLOW}Limpiando interfaces veth del host...${NC}"
    for iface in $(ip link show | grep -oP '(?<=\d: )[^@:]+(?=@)'); do
        ip link del "$iface" 2>/dev/null
        echo -e "  ${RED}✗ Eliminada: $iface${NC}"
    done

    echo -e "${YELLOW}Limpiando rutas y reglas iptables...${NC}"
    iptables -F FORWARD 2>/dev/null
    iptables -t nat -F POSTROUTING 2>/dev/null
    ip route del 10.0.0.0/24 2>/dev/null
    ip addr del 172.16.255.1/30 dev v-wan-gw 2>/dev/null

    echo -e "${GREEN}✔ Entorno limpio.${NC}"
    echo ""
}

# ── Ejecutar todos los labs ──────────────────────────────────────────────────────
ejecutar_laboratorios() {
    local TOTAL=$(contar_labs)
    if [ "$TOTAL" -eq 0 ]; then
        echo -e "${RED}No se encontraron labs en $LAB_DIR${NC}"
        return
    fi
    echo -e "${CYAN}  Ejecutando todos los labs (001 → $(printf '%03d' $TOTAL))...${NC}"
    ejecutar_hasta "$TOTAL"
}

# ── Menú principal ───────────────────────────────────────────────────────────────
while true; do
    clear
    echo -e "${CYAN}"
    echo "  ╔══════════════════════════════════════════╗"
    echo "  ║      LAB ENGINE - GOLDEN BASE            ║"
    echo "  ║      $(date '+%Y-%m-%d %H:%M:%S')                  ║"
    echo "  ╚══════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  Labs disponibles: ${GREEN}$(contar_labs)${NC} encontrados en Golden-Base/"
    echo ""
    echo "  1) Ejecutar laboratorio"
    echo "  2) Limpiar entorno"
    echo "  0) Salir"
    echo ""
    read -p "  Selección: " OPT

    case $OPT in
        1) ejecutar_laboratorios ;;
        2) limpiar_entorno ;;
        0) echo "Saliendo..."; exit 0 ;;
        *) echo -e "${RED}Opción inválida.${NC}" ;;
    esac

    read -p "  Presiona Enter para continuar..." 
done