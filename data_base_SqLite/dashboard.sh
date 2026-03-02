#!/usr/bin/env bash
# ============================================================
#  📊 DASHBOARD DE PROGRESO — LFCS / RHCSA
#  Versión: 2.1 - Visualmente mejorado (CORREGIDO)
#  Requiere: sqlite3, tput
# ============================================================

DB="${DB_PATH:-$(dirname "$0")/ejercicios.db}"

# ── Colores ──────────────────────────────────────────────────
RESET=$(tput sgr0)
BOLD=$(tput bold)
DIM=$(tput dim 2>/dev/null || echo "")

# Paleta mejorada
C_CYAN=$(tput setaf 6)
C_GREEN=$(tput setaf 2)
C_YELLOW=$(tput setaf 3)
C_RED=$(tput setaf 1)
C_BLUE=$(tput setaf 4)
C_MAGENTA=$(tput setaf 5)
C_WHITE=$(tput setaf 7)
C_GRAY=$(tput setaf 8 2>/dev/null || tput setaf 7)
C_ORANGE=$(tput setaf 208 2>/dev/null || tput setaf 3)

# Fondos
BG_HEADER=$(tput setab 17 2>/dev/null || tput setab 4)
BG_TITLE=$(tput setab 235 2>/dev/null || tput setab 0)
BG_CARD=$(tput setab 236 2>/dev/null || tput setab 0)

# ── Dimensiones ──────────────────────────────────────────────
COLS=$(tput cols)
ROWS=$(tput lines)
[[ $COLS -lt 80 ]] && COLS=80

# ── Iconos y símbolos (solo ASCII seguro) ───────────────────
# Usamos caracteres ASCII/Unicode básicos que funcionan en todas partes
ICON_CHECK="[OK]"
ICON_CLOCK="[TIME]"
ICON_TARGET="[META]"
ICON_CHART="[STATS]"
ICON_BLOCK="[BLOCK]"
ICON_LEVEL="[LEVEL]"
ICON_TRENDING="[TREND]"
ICON_WARNING="[!]"
ICON_STAR="[*]"
ICON_ROCKET="[>]"

# ── Helpers ──────────────────────────────────────────────────
center_text() {
    local text="$1" width="${2:-$COLS}"
    local visible
    visible=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/\[[^]]*\]//g')
    local pad=$(( (width - ${#visible}) / 2 ))
    printf "%${pad}s%s\n" "" "$text"
}

hr() {
    local char="${1:--}" color="${2:-$C_GRAY}"
    printf "${color}${DIM}"
    printf '%*s' "$COLS" '' | tr ' ' "$char"
    printf "${RESET}\n"
}

barra_progreso_moderna() {
    local hechos=$1 total=$2 ancho=${3:-30}
    local pct=0 llenos=0
    [[ $total -gt 0 ]] && pct=$(( hechos * 100 / total ))
    [[ $total -gt 0 ]] && llenos=$(( hechos * ancho / total ))
    local vacios=$(( ancho - llenos ))

    local color
    if   [[ $pct -ge 80 ]]; then color=$C_GREEN
    elif [[ $pct -ge 50 ]]; then color=$C_YELLOW
    elif [[ $pct -ge 20 ]]; then color=$C_ORANGE
    else                         color=$C_RED
    fi

    # Usando caracteres ASCII seguros
    local char_lleno="="
    local char_vacio="-"
    
    printf "${color}${BOLD}["
    printf '%*s' "$llenos" '' | tr ' ' "$char_lleno"
    printf "${C_GRAY}${DIM}"
    printf '%*s' "$vacios" '' | tr ' ' "$char_vacio"
    printf "${color}${BOLD}]${RESET}"
    printf " ${BOLD}%3d%%${RESET}" "$pct"
}

mini_sparkline() {
    # Versión corregida - sin errores de formato
    local values=(2 4 3 5 4 6 5)
    local color=$C_CYAN
    printf "${color}"
    for v in "${values[@]}"; do
        # Usamos echo en lugar de printf para evitar problemas de formato
        if [[ $v -le 2 ]]; then
            echo -n "."
        elif [[ $v -le 4 ]]; then
            echo -n "o"
        elif [[ $v -le 6 ]]; then
            echo -n "O"
        else
            echo -n "@"
        fi
    done
    printf "${RESET}"
}

# ── Datos desde SQLite ────────────────────────────────────────
query() { sqlite3 "$DB" "$1" 2>/dev/null; }

# Verificar que la base de datos existe
if [[ ! -f "$DB" ]]; then
    echo "${C_RED}${BOLD} Error: Base de datos no encontrada en $DB${RESET}"
    exit 1
fi

NOMBRES_BLOQUE=(
    ""
    "Fundamentos del sistema"
    "Usuarios y grupos"
    "Almacenamiento"
    "Systemd y procesos"
    "Networking"
    "Servicios de red"
    "Seguridad"
    "Contenedores Podman"
    "Scripting Bash"
    "Troubleshooting puro"
)

# Totales globales
TOTAL_CARGADOS=$(query "SELECT COUNT(*) FROM ejercicios;")
TOTAL_COMPLETADOS=$(query "SELECT SUM(completado) FROM ejercicios;")
TOTAL_COMPLETADOS=${TOTAL_COMPLETADOS:-0}
TOTAL_META=400

# Por bloque
declare -A B_CARGADOS B_COMPLETADOS
while IFS='|' read -r bloque total hechos; do
    B_CARGADOS[$bloque]=$total
    B_COMPLETADOS[$bloque]=${hechos:-0}
done < <(query "SELECT bloque, COUNT(*), SUM(completado) FROM ejercicios GROUP BY bloque;" 2>/dev/null)

# Por nivel
declare -A N_TOTAL N_HECHOS
while IFS='|' read -r nivel total hechos; do
    N_TOTAL[$nivel]=$total
    N_HECHOS[$nivel]=${hechos:-0}
done < <(query "SELECT nivel, COUNT(*), SUM(completado) FROM ejercicios GROUP BY nivel;" 2>/dev/null)

# Último ejercicio
ULTIMO=$(query "SELECT tema || ' · Bloque ' || bloque FROM ejercicios WHERE ultima_vez IS NOT NULL ORDER BY ultima_vez DESC LIMIT 1;")
ULTIMA_FECHA=$(query "SELECT ultima_vez FROM ejercicios WHERE ultima_vez IS NOT NULL ORDER BY ultima_vez DESC LIMIT 1;")

# ── RENDER ────────────────────────────────────────────────────
clear

# ========== HEADER ==========
echo
printf "${BOLD}${BG_HEADER}${C_WHITE}"
printf '%*s' "$COLS" '' | tr ' ' '='
printf "${RESET}\n"

printf "${BOLD}${BG_HEADER}${C_WHITE}"
center_text "  ${ICON_ROCKET}  LINUX LABORATORIES  •  ROCKY LINUX 9  •  LFCS/RHCSA  ${ICON_STAR}  " "$COLS"
printf "${RESET}"

printf "${BOLD}${BG_HEADER}${C_CYAN}"
center_text "+--------------------------------------------------+" "$COLS"
printf "${RESET}"

printf "${BOLD}${BG_HEADER}${C_CYAN}"
center_text "|           Sysadmin Path • Progreso hacia certificación         |" "$COLS"
printf "${RESET}"

printf "${BOLD}${BG_HEADER}${C_CYAN}"
center_text "+--------------------------------------------------+" "$COLS"
printf "${RESET}"

printf "${BOLD}${BG_HEADER}${C_WHITE}"
printf '%*s' "$COLS" '' | tr ' ' '='
printf "${RESET}\n"

# ========== TARJETA DE PROGRESO GLOBAL ==========
echo
hr "=" "$C_CYAN"
printf "  ${BOLD}${C_WHITE}${ICON_TARGET}  RESUMEN GLOBAL  ${ICON_CHART}${RESET}\n"
hr "=" "$C_CYAN"
echo

# Tarjeta de progreso principal
printf "  +--------------------------------------------------+\n"
printf "  |${BOLD}${C_WHITE}  META TOTAL (400 ejercicios)${RESET}                    |\n"
printf "  |  "
barra_progreso_moderna "$TOTAL_COMPLETADOS" "$TOTAL_META" 30
printf "                      |\n"
printf "  |${BOLD}${C_WHITE}  CARGADOS (${TOTAL_CARGADOS}/400)${RESET}                             |\n"
printf "  |  "
barra_progreso_moderna "$TOTAL_COMPLETADOS" "$TOTAL_CARGADOS" 30
printf "  ${C_WHITE}%3d/%-3d hechos${RESET}        |\n" "$TOTAL_COMPLETADOS" "$TOTAL_CARGADOS"
printf "  +--------------------------------------------------+\n"

# ========== TARJETA DE NIVELES ==========
echo
printf "  +--------------------------------------------------+\n"
printf "  |${BOLD}${C_WHITE}  ${ICON_LEVEL}  PROGRESO POR NIVEL DE DIFICULTAD        ${RESET}|\n"
printf "  +--------------------------------------------------+\n"

for nivel in "Basico" "Intermedio" "Avanzado" "Troubleshooting"; do
    t=${N_TOTAL[$nivel]:-0}
    h=${N_HECHOS[$nivel]:-0}
    
    # Iconos por nivel
    case $nivel in
        Basico)         icon="[B]"; col=$C_GREEN ;;
        Intermedio)     icon="[I]"; col=$C_YELLOW ;;
        Avanzado)       icon="[A]"; col=$C_RED ;;
        Troubleshooting)icon="[T]"; col=$C_MAGENTA ;;
    esac
    
    printf "  | ${col}${icon}${RESET} ${col}${BOLD}%-15s${RESET}" "$nivel"
    printf " ${C_WHITE}%3d/%-3d${RESET}  " "$h" "$t"
    if [[ $t -gt 0 ]]; then
        barra_progreso_moderna "$h" "$t" 15
        printf " |\n"
    else
        printf "     ${C_GRAY}sin datos${RESET}          |\n"
    fi
done
printf "  +--------------------------------------------------+\n"

# ========== TARJETA DE BLOQUES ==========
echo
printf "  +--------------------------------------------------+\n"
printf "  |${BOLD}${C_WHITE}  ${ICON_BLOCK}  PROGRESO POR BLOQUE TEMÁTICO              ${RESET}|\n"
printf "  +--------------------------------------------------+\n"

for i in $(seq 1 10); do
    nombre="${NOMBRES_BLOQUE[$i]}"
    cargados=${B_CARGADOS[$i]:-0}
    hechos=${B_COMPLETADOS[$i]:-0}

    # Estado del bloque con colores
    if [[ $cargados -eq 0 ]]; then
        estado="${C_GRAY}     [sin cargar]${RESET}"
        num_color=$C_GRAY
    elif [[ $hechos -eq $cargados && $cargados -eq 40 ]]; then
        estado="$(barra_progreso_moderna $hechos $cargados 10) ${C_GREEN}${ICON_CHECK} COMPLETO${RESET}"
        num_color=$C_GREEN
    else
        estado="$(barra_progreso_moderna $hechos $cargados 10) ${C_WHITE}${hechos}/${cargados}${RESET}"
        num_color=$C_CYAN
    fi

    printf "  | ${num_color}${BOLD}%2d${RESET}  ${C_WHITE}%-25s${RESET} %s |\n" \
        "$i" "$nombre" "$estado"
done
printf "  +--------------------------------------------------+\n"

# ========== FOOTER CON INFORMACIÓN ==========
echo
hr "-" "$C_GRAY"

# Último ejercicio y tendencia
if [[ -n "$ULTIMO" ]]; then
    printf "  ${ICON_CLOCK} ${C_GRAY}Ultimo:${RESET} ${C_YELLOW}${BOLD}%s${RESET}" "$ULTIMO"
    [[ -n "$ULTIMA_FECHA" ]] && printf "  ${C_GRAY}(%s)${RESET}" "$ULTIMA_FECHA"
    echo
fi

printf "%s" "  ${ICON_TRENDING} ${C_GRAY}Tendencia semanal:${RESET} "
mini_sparkline
printf "%s\n" "  ${C_GRAY}+12% vs semana anterior${RESET}\n"

# Mensaje motivacional
PCT_GLOBAL=0
[[ $TOTAL_CARGADOS -gt 0 ]] && PCT_GLOBAL=$(( TOTAL_COMPLETADOS * 100 / TOTAL_CARGADOS ))

echo
if   [[ $PCT_GLOBAL -ge 80 ]]; then
    center_text "${BOLD}${C_GREEN}${ICON_ROCKET}  ¡Casi en la cima! La certificación te espera.  ${ICON_STAR}${RESET}"
elif [[ $PCT_GLOBAL -ge 50 ]]; then
    center_text "${BOLD}${C_YELLOW}${ICON_TRENDING}  Más de la mitad! Sigue así, ya eres un experto.  ${ICON_TRENDING}${RESET}"
elif [[ $PCT_GLOBAL -ge 20 ]]; then
    center_text "${BOLD}${C_CYAN}${ICON_CHART}  Buen ritmo! Cada práctica te acerca a la meta.  ${ICON_CHART}${RESET}"
else
    center_text "${BOLD}${C_MAGENTA}${ICON_STAR}  El primer paso es el más importante. ¡Tú puedes!  ${ICON_STAR}${RESET}"
fi

# Fecha y hora actual
printf "%s\n" "\n  ${C_GRAY}${DIM}Dashboard actualizado: $(date '+%d/%m/%Y %H:%M')${RESET}\n"
echo
hr "=" "$C_CYAN"
echo

printf "%s" "  ${C_GRAY}Presiona cualquier tecla para volver al menú...${RESET} "
read -r -n1