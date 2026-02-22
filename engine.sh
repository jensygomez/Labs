#!/bin/bash
# ===================================================================================
# LAB ENGINE - GOLDEN BASE
# Directorio: ~/Labs/Golden-Base
# ===================================================================================

# ── Configuración inicial ─────────────────────────────────────────────────────
set -e  # Salir si hay error

# ── Determinar directorio base ────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="${SCRIPT_DIR}/Golden-Base"

# ── Colores ───────────────────────────────────────────────────────────────────
VERDE='\033[0;32m'
GRIS='\033[0;37m'
ROJO='\033[0;31m'
AMARILLO='\033[1;33m'
AZUL='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Aliases para compatibilidad con otros nombres
GREEN="$VERDE"
RED="$ROJO"
YELLOW="$AMARILLO"
BLUE="$AZUL"

# ── Detectar labs disponibles ─────────────────────────────────────────────────
contar_labs() {
    ls "$LAB_DIR"/lab-*.sh 2>/dev/null | wc -l
}

# ── Verificar que existen labs ────────────────────────────────────────────────
verificar_labs() {
    if [ "$(contar_labs)" -eq 0 ]; then
        echo -e "${RED}✗ No se encontraron labs en: $LAB_DIR${NC}"
        echo -e "${YELLOW}  Buscando archivos: lab-*.sh${NC}"
        return 1
    fi
    return 0
}

# ── Ejecutar labs en cadena ───────────────────────────────────────────────────
# ── Ejecutar labs en cadena ───────────────────────────────────────────────────
ejecutar_hasta() {
    local TARGET=$1
    echo ""
    
    # Verificar que existen labs antes de ejecutar
    verificar_labs || return 1
    
    for i in $(seq 1 "$TARGET"); do
        LAB=$(printf "%s/lab-%03d.sh" "$LAB_DIR" "$i")

        if [ -f "$LAB" ]; then
            echo -e "${CYAN}══════════════════════════════════════════${NC}"
            echo -e "${CYAN}  Ejecutando: lab-$(printf '%03d' "$i").sh${NC}"
            echo -e "${CYAN}══════════════════════════════════════════${NC}"

            chmod +x "$LAB"

            # Ejecutar lab en modo silencioso
            if ! bash "$LAB"; then
                echo -e "${RED}✗ Error en lab-$(printf '%03d' "$i").sh — abortando.${NC}"
                return 1
            fi

            echo -e "${GREEN}✔ lab-$(printf '%03d' "$i").sh completado${NC}\n"
        else
            echo -e "${YELLOW}⚠ No existe: $LAB${NC}"
        fi
    done

    # ✅ SOLUCIÓN: Ejecutar print_topology en un subshell para no contaminar el entorno
    ULTIMO_LAB=$(printf "$LAB_DIR/lab-%03d.sh" $TARGET)
    if [ -f "$ULTIMO_LAB" ]; then
        # Ejecutar en un subshell para no afectar el entorno actual
        (
            source "$ULTIMO_LAB" 2>/dev/null
            type print_topology &>/dev/null && print_topology
        ) || echo -e "${YELLOW}⚠ No hay función print_topology() en el último lab${NC}"
    fi
    
    echo -e "\n${CYAN}➤ Para acceder a los Containers:${NC}"
    echo -e "  ${GRIS}docker ps -a${NC}"
    echo -e "  ${GRIS}docker exec -it NOMBRE-DEL-DOCKER bash${NC}"
    echo ""
}

limpiar_entorno() {
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════${NC}"
    echo -e "${CYAN}  LIMPIEZA COMPLETA DEL ENTORNO${NC}"
    echo -e "${CYAN}══════════════════════════════════════════${NC}"
    echo ""

    echo -e "${YELLOW}Limpiando contenedores Docker del laboratorio...${NC}"
    containers=$(docker ps -aq 2>/dev/null)
    if [ -n "$containers" ]; then
        for container in $containers; do
            name=$(docker inspect -f '{{.Name}}' "$container" 2>/dev/null | tr -d '/')
            docker stop "$container" &>/dev/null
            docker rm "$container" &>/dev/null
            echo -e "  ${RED}✗ Contenedor eliminado: $name${NC}"
        done
    else
        echo -e "  ${GREEN}✓ No hay contenedores activos.${NC}"
    fi

    echo -e "${YELLOW}Limpiando symlinks de netns...${NC}"
    if [ -d /var/run/netns ]; then
        for ns_link in /var/run/netns/*; do
            [ -L "$ns_link" ] || continue
            name=$(basename "$ns_link")
            rm -f "$ns_link"
            echo -e "  ${RED}✗ Symlink netns eliminado: $name${NC}"
        done
    fi

    echo -e "${YELLOW}Limpiando interfaces veth del Host...${NC}"
    for iface in $(ip link show type veth 2>/dev/null | awk -F': ' '{print $2}' | cut -d'@' -f1); do
        ip link del "$iface" 2>/dev/null && echo -e "  ${RED}✗ Eliminada interface veth: $iface${NC}"
    done

    echo -e "${YELLOW}Limpiando reglas de red...${NC}"
    iptables -F FORWARD 2>/dev/null
    iptables -t nat -F POSTROUTING 2>/dev/null
    echo -e "  ${GREEN}✓ Reglas iptables limpiadas${NC}"

    echo -e "${YELLOW}Limpiando rutas del laboratorio (metric 1000)...${NC}"
    while IFS= read -r route; do
        [ -z "$route" ] && continue
        dest=$(echo "$route" | awk '{print $1}')
        ip route del "$dest" metric 1000 2>/dev/null && echo -e "  ${RED}✗ Ruta eliminada: $dest${NC}"
    done < <(ip route show metric 1000 2>/dev/null)

    echo ""
    echo -e "${GREEN}✔ Entorno 100% limpio.${NC}"
    echo ""
}

# ── Ejecutar todos los labs ───────────────────────────────────────────────────
ejecutar_laboratorios() {
    local TOTAL=$(contar_labs)
    if [ "$TOTAL" -eq 0 ]; then
        echo -e "${RED}No se encontraron labs en:${NC}"
        echo -e "  $LAB_DIR"
        echo -e "${YELLOW}Debe haber archivos lab-001.sh, lab-002.sh, etc.${NC}"
        return
    fi
    echo -e "${CYAN}══════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Ejecutando todos los labs (001 → $(printf '%03d' $TOTAL))${NC}"
    echo -e "${CYAN}══════════════════════════════════════════${NC}"
    ejecutar_hasta "$TOTAL"
}

# ── Mostrar estado actual ─────────────────────────────────────────────────────
mostrar_estado() {
    echo -e "${CYAN}══════════════════════════════════════════${NC}"
    echo -e "${CYAN}  ESTADO DEL LABORATORIO${NC}"
    echo -e "${CYAN}══════════════════════════════════════════${NC}"
    
    # Contenedores Docker activos
    echo -e "\n${YELLOW}Contenedores Docker:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.IPAddress}}" 2>/dev/null || echo "  No hay contenedores"
    
    # Namespaces de red
    echo -e "\n${YELLOW}Namespaces de red:${NC}"
    ip netns list 2>/dev/null || echo "  No hay namespaces"
    
    echo ""
}

# ── Menú principal ────────────────────────────────────────────────────────────
while true; do
    clear
    echo -e "${CYAN}"
    echo "  ╔══════════════════════════════════════════╗"
    echo "  ║      LAB ENGINE - GOLDEN BASE            ║"
    echo "  ║      $(date '+%Y-%m-%d %H:%M:%S')                  ║"
    echo "  ╚══════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  Directorio: ${GRIS}$LAB_DIR${NC}"
    echo -e "  Labs disponibles: ${GREEN}$(contar_labs)${NC}"
    echo ""
    echo "  1) Ejecutar todos los laboratorios"
    echo "  2) Limpiar entorno"
    echo "  3) Ver estado actual"
    echo "  0) Salir"
    echo ""
    read -p "  Selección: " OPT

    case $OPT in
        1) ejecutar_laboratorios ;;
        2) limpiar_entorno ;;
        3) mostrar_estado ;;
        0) echo -e "${GREEN}Saliendo...${NC}"; exit 0 ;;
        *) echo -e "${RED}Opción inválida.${NC}" ;;
    esac

    echo ""
    read -p "  Presiona Enter para continuar..." 
done