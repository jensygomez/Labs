#!/bin/bash
# ============================================================
#  menu.sh — Menú principal de laboratorios Linux Sysadmin
#  Ubicación: ~/Labs/data_base_SqLite/menu.sh
#  PASO 1: Solo menú principal — sin DB ni submenús aún
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

# ── Bloques de estudio ───────────────────────────────────────
BLOQUES=(
    ""                             # índice 0 vacío — para que BLOQUES[1] = bloque 1
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

        # Validar que sea número entre 0 y 10
        if ! [[ "$opcion" =~ ^[0-9]+$ ]] || (( opcion < 0 || opcion > 10 )); then
            echo -e "\n  ${RED}❌ Opción inválida — ingresa un número del 0 al 10${NC}"
            sleep 1
            continue
        fi

        if (( opcion == 0 )); then
            echo -e "\n  ${GREEN}👋 Hasta la próxima. Sigue practicando.${NC}\n"
            exit 0
        fi

        # ── Aquí irá el submenú (próximo paso) ──────────────
        echo ""
        echo -e "  ${YELLOW}✅ Seleccionaste: Bloque $opcion — ${BLOQUES[$opcion]}${NC}"
        echo -e "  ${BLUE}   [Submenú de niveles — próximo paso]${NC}"
        echo ""
        read -rp "  Presiona ENTER para volver..." _

    done
}

# ── Inicio ───────────────────────────────────────────────────
menu_principal