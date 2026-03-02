#!/usr/bin/env bash
# ============================================================
#  DASHBOARD DE PROGRESO — LFCS / RHCSA
#  Requiere: sqlite3, tput
# ============================================================

DB="${DB_PATH:-$(dirname "$0")/ejercicios.db}"

# ── Colores ──────────────────────────────────────────────────
RESET=$(tput sgr0)
BOLD=$(tput bold)
DIM=$(tput dim 2>/dev/null || echo "")

# Paleta
C_CYAN=$(tput setaf 6)
C_GREEN=$(tput setaf 2)
C_YELLOW=$(tput setaf 3)
C_RED=$(tput setaf 1)
C_BLUE=$(tput setaf 4)
C_MAGENTA=$(tput setaf 5)
C_WHITE=$(tput setaf 7)
C_GRAY=$(tput setaf 8 2>/dev/null || tput setaf 7)

BG_HEADER=$(tput setab 4)   # fondo azul para cabecera
BG_ROW1=$(tput setab 0)     # negro
BG_ROW2=$(tput setab 235 2>/dev/null || tput setab 0)

# ── Dimensiones ──────────────────────────────────────────────
COLS=$(tput cols)
ROWS=$(tput lines)
[[ $COLS -lt 60 ]] && COLS=80

# ── Helpers ──────────────────────────────────────────────────
center_text() {
    local text="$1" width="${2:-$COLS}"
    local visible
    # strip escape codes para calcular longitud visible
    visible=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local pad=$(( (width - ${#visible}) / 2 ))
    printf "%${pad}s%s\n" "" "$text"
}

hr() {
    local char="${1:-─}" color="${2:-$C_CYAN}"
    printf "${color}"
    printf '%*s' "$COLS" '' | tr ' ' "$char"
    printf "${RESET}\n"
}

barra_progreso() {
    local hechos=$1 total=$2 ancho=${3:-30}
    local pct=0 llenos=0
    [[ $total -gt 0 ]] && pct=$(( hechos * 100 / total ))
    [[ $total -gt 0 ]] && llenos=$(( hechos * ancho / total ))
    local vacios=$(( ancho - llenos ))

    local color
    if   [[ $pct -ge 80 ]]; then color=$C_GREEN
    elif [[ $pct -ge 40 ]]; then color=$C_YELLOW
    elif [[ $pct -gt 0  ]]; then color=$C_CYAN
    else                         color=$C_GRAY
    fi

    printf "${color}["
    printf '%*s' "$llenos" '' | tr ' ' '█'
    printf "${C_GRAY}"
    printf '%*s' "$vacios" '' | tr ' ' '░'
    printf "${color}]${RESET}"
    printf " ${BOLD}%3d%%${RESET}" "$pct"
}

# ── Datos desde SQLite ────────────────────────────────────────
query() { sqlite3 "$DB" "$1" 2>/dev/null; }

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

# Por bloque: "bloque|total_cargados|completados"
declare -A B_CARGADOS B_COMPLETADOS
while IFS='|' read -r bloque total hechos; do
    B_CARGADOS[$bloque]=$total
    B_COMPLETADOS[$bloque]=${hechos:-0}
done < <(query "SELECT bloque, COUNT(*), SUM(completado) FROM ejercicios GROUP BY bloque;")

# Por nivel global
declare -A N_TOTAL N_HECHOS
while IFS='|' read -r nivel total hechos; do
    N_TOTAL[$nivel]=$total
    N_HECHOS[$nivel]=${hechos:-0}
done < <(query "SELECT nivel, COUNT(*), SUM(completado) FROM ejercicios GROUP BY nivel;")

# Último ejercicio trabajado
ULTIMO=$(query "SELECT tema || ' · Bloque ' || bloque FROM ejercicios WHERE ultima_vez IS NOT NULL ORDER BY ultima_vez DESC LIMIT 1;")
ULTIMA_FECHA=$(query "SELECT ultima_vez FROM ejercicios WHERE ultima_vez IS NOT NULL ORDER BY ultima_vez DESC LIMIT 1;")

# ── RENDER ────────────────────────────────────────────────────
clear

# — Cabecera ——————————————————————————————————————————————————
echo
printf "${BOLD}${BG_HEADER}${C_WHITE}"
printf '%*s' "$COLS" '' | tr ' ' ' '    # línea rellena
printf "${RESET}\n"

printf "${BOLD}${BG_HEADER}${C_WHITE}"
center_text "  🐧  LABORATORIOS LINUX — Rocky Linux 9  " "$COLS"
printf "${RESET}"

printf "${BOLD}${BG_HEADER}${C_CYAN}"
center_text "Ruta: Sysadmin → LFCS / RHCSA" "$COLS"
printf "${RESET}"

printf "${BOLD}${BG_HEADER}${C_WHITE}"
printf '%*s' "$COLS" '' | tr ' ' ' '
printf "${RESET}\n"

# — Resumen global ————————————————————————————————————————————
echo
hr "═" "$C_CYAN"
center_text "${BOLD}${C_WHITE}📊  PROGRESO GLOBAL${RESET}"
hr "═" "$C_CYAN"
echo

# Barra global sobre los 400 ejercicios meta
printf "  ${C_WHITE}${BOLD}Meta total  (400 ejercicios)${RESET}  "
barra_progreso "$TOTAL_COMPLETADOS" "$TOTAL_META" 35
echo

# Barra sobre lo cargado
printf "  ${C_WHITE}${BOLD}Cargados    (${TOTAL_CARGADOS}/400)       ${RESET}  "
barra_progreso "$TOTAL_COMPLETADOS" "$TOTAL_CARGADOS" 35
printf "  ${C_GRAY}%d / %d hechos${RESET}\n" "$TOTAL_COMPLETADOS" "$TOTAL_CARGADOS"

echo

# — Desglose por nivel ————————————————————————————————————————
hr "─" "$C_CYAN"
printf "  ${BOLD}${C_CYAN}NIVEL            HECHOS   BARRA${RESET}\n"
hr "─" "$C_CYAN"

for nivel in "Basico" "Intermedio" "Avanzado" "Troubleshooting"; do
    t=${N_TOTAL[$nivel]:-0}
    h=${N_HECHOS[$nivel]:-0}
    icon="○"
    col=$C_GRAY
    case $nivel in
        Basico)         icon="🟢"; col=$C_GREEN ;;
        Intermedio)     icon="🟡"; col=$C_YELLOW ;;
        Avanzado)       icon="🔴"; col=$C_RED ;;
        Troubleshooting)icon="⚡"; col=$C_MAGENTA ;;
    esac
    printf "  ${col}${BOLD}%-18s${RESET}" "$nivel"
    printf " ${C_WHITE}%3d/%-3d${RESET}  " "$h" "$t"
    if [[ $t -gt 0 ]]; then
        barra_progreso "$h" "$t" 20
    else
        printf "${C_GRAY}[sin datos aún]${RESET}"
    fi
    echo
done

echo

# — Progreso por bloque ———————————————————————————————————————
hr "─" "$C_CYAN"
printf "  ${BOLD}${C_CYAN}#   BLOQUE                        PROGRESO${RESET}\n"
hr "─" "$C_CYAN"

for i in $(seq 1 10); do
    nombre="${NOMBRES_BLOQUE[$i]}"
    cargados=${B_CARGADOS[$i]:-0}
    hechos=${B_COMPLETADOS[$i]:-0}

    # Estado del bloque
    if [[ $cargados -eq 0 ]]; then
        estado="${C_GRAY}  ··· sin cargar ···${RESET}"
        num_color=$C_GRAY
    elif [[ $hechos -eq $cargados && $cargados -eq 40 ]]; then
        estado="$(barra_progreso $hechos $cargados 20) ${C_GREEN}${BOLD}✔ COMPLETO${RESET}"
        num_color=$C_GREEN
    else
        estado="$(barra_progreso $hechos $cargados 20) ${C_WHITE}${hechos}/${cargados}${RESET}"
        num_color=$C_CYAN
    fi

    printf "  ${num_color}${BOLD}%2d)${RESET}  ${C_WHITE}%-30s${RESET}  %s\n" \
        "$i" "$nombre" "$estado"
done

echo
hr "─" "$C_CYAN"

# — Último ejercicio ——————————————————————————————————————————
if [[ -n "$ULTIMO" ]]; then
    printf "  ${C_GRAY}Último trabajado:${RESET} ${C_YELLOW}${BOLD}%s${RESET}" "$ULTIMO"
    [[ -n "$ULTIMA_FECHA" ]] && printf "  ${C_GRAY}(%s)${RESET}" "$ULTIMA_FECHA"
    echo
fi

# — Motivación ————————————————————————————————————————————————
PCT_GLOBAL=0
[[ $TOTAL_CARGADOS -gt 0 ]] && PCT_GLOBAL=$(( TOTAL_COMPLETADOS * 100 / TOTAL_CARGADOS ))

echo
if   [[ $PCT_GLOBAL -ge 80 ]]; then
    center_text "${BOLD}${C_GREEN}🔥  Casi en la cima. No pares ahora.${RESET}"
elif [[ $PCT_GLOBAL -ge 50 ]]; then
    center_text "${BOLD}${C_YELLOW}⚡  Más de la mitad. El camino está hecho.${RESET}"
elif [[ $PCT_GLOBAL -ge 20 ]]; then
    center_text "${BOLD}${C_CYAN}🚀  Buen ritmo. Cada lab cuenta.${RESET}"
else
    center_text "${BOLD}${C_MAGENTA}🌱  El inicio es el paso más difícil. Ya lo diste.${RESET}"
fi
echo
hr "═" "$C_CYAN"
echo

printf "  ${C_GRAY}Presiona cualquier tecla para volver al menú...${RESET} "
read -r -n1