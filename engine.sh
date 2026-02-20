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
            
            # EJECUCIÓN: Esto corre la red del lab
            bash "$LAB"
            
            if [ $? -ne 0 ]; then
                echo -e "${RED}✗ Error en lab-$(printf '%03d' $i).sh — abortando.${NC}"
                exit 1
            fi
            echo -e "${GREEN}✔ completado${NC}\n"
        fi
    done

    # INFO: Cargamos el último para mostrar su topología
    ULTIMO_LAB=$(printf "$LAB_DIR/lab-%03d.sh" $TARGET)
    source "$ULTIMO_LAB" # Gracias al 'if' del lab, esto NO repetirá la red
    print_topology
    echo " entra a cada namespace creado usando el siguietne ejemplo"
    echo "ip netns exec CORE-GW unshare -u bash"
}

limpiar_entorno() {
    echo ""

    echo -e "${YELLOW}Limpiando contenedores Docker del laboratorio...${NC}"
    containers=$(docker ps -aq 2>/dev/null)
    if [ -n "$containers" ]; then
        for container in $containers; do
            name=$(docker inspect -f '{{.Name}}' "$container" | tr -d '/')
            docker stop "$container" &>/dev/null
            docker rm "$container" &>/dev/null
            echo -e "  ${RED}✗ Contenedor eliminado: $name${NC}"
        done
    else
        echo -e "  ${YELLOW}No hay contenedores activos.${NC}"
    fi

    echo -e "${YELLOW}Limpiando symlinks de netns...${NC}"
    for ns_link in /var/run/netns/*; do
        [ -L "$ns_link" ] || continue
        name=$(basename "$ns_link")
        rm -f "$ns_link"
        echo -e "  ${RED}✗ Symlink netns eliminado: $name${NC}"
    done

    echo -e "${YELLOW}Limpiando interfaces veth del Host...${NC}"
    for iface in $(ip link show type veth 2>/dev/null | awk -F': ' '{print $2}' | awk '{print $1}'); do
        ip link del "$iface" 2>/dev/null
        echo -e "  ${RED}✗ Eliminada interface veth: $iface${NC}"
    done

    echo -e "${YELLOW}Limpiando reglas de red...${NC}"
    iptables -F FORWARD 2>/dev/null
    iptables -t nat -F POSTROUTING 2>/dev/null
    echo -e "  ${RED}✗ Reglas iptables limpiadas${NC}"

    echo -e "${YELLOW}Limpiando rutas del laboratorio (metric 1000)...${NC}"
    while IFS= read -r route; do
        [ -z "$route" ] && continue
        dest=$(echo "$route" | awk '{print $1}')
        ip route del "$dest" metric 1000 2>/dev/null
        echo -e "  ${RED}✗ Ruta eliminada: $dest${NC}"
    done < <(ip route show metric 1000 2>/dev/null)

    echo ""
    echo -e "${GREEN}✔ Entorno 100% limpio.${NC}"
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