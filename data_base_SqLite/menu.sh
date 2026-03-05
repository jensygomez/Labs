#!/bin/bash
# ============================================================
#  menu.sh — Versión Final Optimizada
# ============================================================

# ── Colores y Formato ────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'
GRAY='\033[0;90m'; NC='\033[0m'
SEP="${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Cargar funciones
source ./db.sh
source ./ejercicio.sh

# Asegurar que la DB existe
inicializar_db

# ── Configuración de Bloques ────────────────────────────────
BLOQUES=("" "Fundamentos del sistema" "Usuarios y grupos" "Almacenamiento" "Systemd y procesos" "Networking" "Servicios de red" "Seguridad" "Contenedores con Podman" "Scripting Bash" "Boot and Recovery")
NIVELES=("Basico" "Intermedio" "Avanzado" "Troubleshooting")
ICONOS=("🟢" "🟡" "🔴" "🔥")

# ── Header Estilizado ───────────────────────────────────────
mostrar_header() {
    clear
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════╗"
    echo -e "║${NC}${BOLD}       🐧  LABORATORIOS LINUX — Rocky Linux 9                ${NC}${BOLD}${BLUE}║"
    echo -e "║${NC}            ${CYAN}Ruta: Sysadmin → LFCS / RHCSA${NC}                    ${BOLD}${BLUE}║"
    echo -e "╚══════════════════════════════════════════════════════════════╝${NC}"
}

# ── Submenú de niveles ───────────────────────────────────────
menu_nivel() {
    local bloque=$1
    local tema="${BLOQUES[$bloque]}"

    while true; do
        mostrar_header
        echo -e "  ${BOLD}📂 BLOQUE $bloque: ${YELLOW}$tema${NC}"
        echo -e "  $SEP"
        
        local contadores=$(obtener_contadores "$bloque")
        declare -A totales; declare -A completados
        
        while IFS='|' read -r nivel total comp; do
            [ -n "$nivel" ] && { totales["$nivel"]=$total; completados["$nivel"]=$comp; }
        done <<< "$contadores"

        for i in 0 1 2 3; do
            local nivel="${NIVELES[$i]}"
            local total=${totales["$nivel"]:-0}
            local comp=${completados["$nivel"]:-0}

            if [ $total -eq 0 ]; then
                printf "  ${BOLD}%d)${NC}  %s  %-14s  ${GRAY}(Vacío)${NC}\n" "$((i+1))" "${ICONOS[$i]}" "$nivel"
            else
                printf "  ${BOLD}%d)${NC}  %s  %-14s  ${GREEN}%d${NC}/${BOLD}%d${NC} completados\n" "$((i+1))" "${ICONOS[$i]}" "$nivel" "$comp" "$total"
            fi
        done

        echo -e "  $SEP"
        echo -e "  ${BOLD}0)${NC} 🔙 Volver"
        echo ""
        read -rp "  Selecciona dificultad [0-4]: " opcion

        case "$opcion" in
            0) return ;;
            [1-4])
                local idx=$((opcion-1))
                local nivel_elegido="${NIVELES[$idx]}"
                [ ${totales["$nivel_elegido"]:-0} -eq 0 ] && continue
                # Llamada al script de ejercicios
                ./ejercicio.sh "$bloque" "$nivel_elegido"
                ;;
        esac
    done
}

# ── Menú principal ───────────────────────────────────────────
menu_principal() {
    while true; do
        mostrar_header
        echo -e "  ${BOLD}📚 TEMARIO DISPONIBLE${NC}"
        echo -e "  $SEP"
        for i in {1..10}; do
            printf "  ${CYAN}${BOLD}%2d)${NC} %s\n" "$i" "${BLOQUES[$i]}"
        done
        echo -e "  $SEP"
        echo -e "  ${RED}${BOLD} 0)${NC} Salir"
        echo ""
        read -rp "  Elige un bloque: " opcion

        if [[ "$opcion" == "0" ]]; then exit 0; fi
        if [[ "$opcion" =~ ^[1-9]$|^10$ ]]; then menu_nivel "$opcion"; fi
    done
}

# ── Pantalla de Inicio ────────────────────────────────────────
mostrar_header
echo -e "  ${BOLD}🛠️  CENTRO DE CONTROL${NC}"
echo -e "  $SEP"
echo -e "  ${BOLD}[A]${NC} ${GREEN}🚀 Entrar a Estudiar${NC}"
echo -e "  ${BOLD}[B]${NC} ${YELLOW}🔄 Sincronizar YAML (Cargar nuevos)${NC}"
echo ""
echo -ne "  ${BOLD}Selecciona una opción:${NC} "
read -n 1 -s inicio_opc

case $inicio_opc in
    b|B)
        echo -e "\n\n  ${CYAN}Buscando nuevos ejercicios en ejercicios.yaml...${NC}"
        python3 cargar_ejercicios.py
        echo -e "  ${GREEN}¡Proceso finalizado! Presiona una tecla...${NC}"
        read -n 1 -s 
        ;;
esac

menu_principal