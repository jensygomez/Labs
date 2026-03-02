#!/bin/bash
# ============================================================
#  menu.sh — Menú principal + submenú de niveles
#  Ubicación: ~/Labs/data_base_SqLite/menu.sh
#  PASO 2: Submenú de niveles — sin DB aún, contadores en 0
# ============================================================

# ── Colores ─────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SEP="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Cargar funciones de base de datos
source ./db.sh
source ./ejercicio.sh

# Inicializar base de datos si no existe
inicializar_db

# ── Bloques de estudio ───────────────────────────────────────
BLOQUES=(
    ""
    "Fundamentos del sistema"
    "Usuarios y grupos"
    "Almacenamiento"
    "Systemd y procesos"
    "Networking"
    "Servicios de red"
    "Seguridad"
    "Contenedores con Podman"
    "Scripting Bash"
    "Troubleshooting puro"
)

# ── Niveles ──────────────────────────────────────────────────
NIVELES=("Basico" "Intermedio" "Avanzado" "Troubleshooting")
ICONOS=("🟢" "🟡" "🔴" "🔥")

# ── Header ───────────────────────────────────────────────────
mostrar_header() {
    clear
    echo -e "${BOLD}${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║       🐧  LABORATORIOS LINUX — Rocky Linux 9                ║"
    echo "║            Ruta: Sysadmin → LFCS / RHCSA                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ── Submenú de niveles ───────────────────────────────────────
menu_nivel() {
    local bloque=$1
    local tema="${BLOQUES[$bloque]}"

    while true; do
        mostrar_header

        echo -e "  ${BOLD}🔥 BLOQUE $bloque — $tema${NC}"
        echo -e "  $SEP"
        echo -e "  ${BOLD}  Elige el nivel de dificultad:${NC}"
        echo ""

        # Obtener contadores de la base de datos
        local contadores=$(obtener_contadores "$bloque")
        
        # Procesar los contadores (formato: nivel|total|completados)
        declare -A totales
        declare -A completados
        
        while IFS='|' read -r nivel total comp; do
            if [ -n "$nivel" ]; then
                totales["$nivel"]=$total
                completados["$nivel"]=$comp
            fi
        done <<< "$contadores"

        # Mostrar cada nivel con sus contadores reales
        for i in 0 1 2 3; do
            local nivel="${NIVELES[$i]}"
            local icono="${ICONOS[$i]}"
            
            local total=${totales["$nivel"]:-0}
            local comp=${completados["$nivel"]:-0}
            local pendientes=$((total - comp))

            if [ $total -eq 0 ]; then
                printf "  ${BOLD}%d)${NC}  %s  %-16s  ${YELLOW}❌ sin ejercicios${NC}\n" \
                    "$(( i + 1 ))" "$icono" "$nivel"
            else
                printf "  ${BOLD}%d)${NC}  %s  %-16s  %d/%d completados (${pendientes} pendientes)\n" \
                    "$(( i + 1 ))" "$icono" "$nivel" "$comp" "$total"
            fi
        done

        echo ""
        echo -e "  $SEP"
        echo -e "  ${BOLD}0)${NC}  🔙 Volver al menú principal"
        echo ""
        read -rp "$(echo -e "  ${CYAN}Elige un nivel [0-4]: ${NC}")" opcion

        if ! [[ "$opcion" =~ ^[0-4]$ ]]; then
            echo -e "\n  ${RED}❌ Opción inválida — ingresa un número del 0 al 4${NC}"
            sleep 1
            continue
        fi

        case "$opcion" in
            0) return ;;
            1|2|3|4)
                local idx=$(( opcion - 1 ))
                local nivel_elegido="${NIVELES[$idx]}"
                local total=${totales["$nivel_elegido"]:-0}
                
                if [ $total -eq 0 ]; then
                    echo -e "\n  ${YELLOW}⚠️  No hay ejercicios para este nivel${NC}"
                    sleep 1
                    continue
                fi
                
                # 🔥 CAMBIO IMPORTANTE: Llamar a ejercicio.sh en lugar del placeholder
                ./ejercicio.sh "$bloque" "$nivel_elegido"
                # Cuando termine ejercicio.sh, vuelve aquí y se refresca el menú
                ;;
        esac
    done
}





# ── Menú principal ───────────────────────────────────────────
menu_principal() {
    while true; do
        mostrar_header

        echo -e "  ${BOLD}📚 BLOQUES DE ESTUDIO${NC}"
        echo -e "  $SEP"
        echo ""

        for i in 1 2 3 4 5 6 7 8 9 10; do
            printf "  ${BOLD}%2d)${NC}  %s\n" "$i" "${BLOQUES[$i]}"
        done

        echo ""
        echo -e "  $SEP"
        echo -e "  ${BOLD} 0)${NC}  🚪 Salir"
        echo ""
        read -rp "$(echo -e "  ${CYAN}Elige un bloque [0-10]: ${NC}")" opcion

        if ! [[ "$opcion" =~ ^[0-9]+$ ]] || (( opcion < 0 || opcion > 10 )); then
            echo -e "\n  ${RED}❌ Opción inválida — ingresa un número del 0 al 10${NC}"
            sleep 1
            continue
        fi

        case "$opcion" in
            0)
                echo -e "\n  ${GREEN}👋 Hasta la próxima. Sigue practicando.${NC}\n"
                exit 0
                ;;
            *)
                menu_nivel "$opcion"
                ;;
        esac
    done
}

# ── Inicio ───────────────────────────────────────────────────
menu_principal