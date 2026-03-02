#!/usr/bin/env bash
# ============================================================
#  📊 DASHBOARD DE PROGRESO — LFCS / RHCSA
#  Versión: 3.0 - Diseño de 4 cuadrantes con líneas divisorias
#  Requiere: sqlite3, tput
# ============================================================

DB="${DB_PATH:-$(dirname "$0")/ejercicios.db}"

# ── Colores ──────────────────────────────────────────────────
RESET=$(tput sgr0)
BOLD=$(tput bold)
DIM=$(tput dim 2>/dev/null || echo "")

C_CYAN=$(tput setaf 6)
C_GREEN=$(tput setaf 2)
C_YELLOW=$(tput setaf 3)
C_RED=$(tput setaf 1)
C_BLUE=$(tput setaf 4)
C_MAGENTA=$(tput setaf 5)
C_WHITE=$(tput setaf 7)
C_GRAY=$(tput setaf 8 2>/dev/null || tput setaf 7)
C_ORANGE=$(tput setaf 208 2>/dev/null || tput setaf 3)

BG_HEADER=$(tput setab 17 2>/dev/null || tput setab 4)

# ── Dimensiones ──────────────────────────────────────────────
COLS=$(tput cols)
ROWS=$(tput lines)
[[ $COLS -lt 100 ]] && COLS=100
[[ $ROWS -lt 30 ]] && ROWS=30

# ── Iconos ───────────────────────────────────────────────────
ICON_CHECK="[OK]"
ICON_CLOCK="[TIME]"
ICON_TARGET="[META]"
ICON_CHART="[STATS]"
ICON_BLOCK="[BLOCK]"
ICON_LEVEL="[LEVEL]"
ICON_TRENDING="[TREND]"
ICON_STAR="[*]"
ICON_ROCKET="[>]"
ICON_CALENDAR="[CAL]"

# ── Líneas divisorias ────────────────────────────────────────
LINE_HORIZONTAL=$(printf '%*s' "$COLS" '' | tr ' ' '═')
LINE_VERTICAL="║"
LINE_CRUZ="╬"
LINE_T_UP="╩"
LINE_T_DOWN="╦"
LINE_T_LEFT="╣"
LINE_T_RIGHT="╠"

# ── Helpers ──────────────────────────────────────────────────
center_text() {
    local text="$1" width="${2:-$COLS}"
    local visible
    visible=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local pad=$(( (width - ${#visible}) / 2 ))
    printf "%${pad}s%s\n" "" "$text"
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

    printf "${color}${BOLD}["
    printf '%*s' "$llenos" '' | tr ' ' '='
    printf "${C_GRAY}${DIM}"
    printf '%*s' "$vacios" '' | tr ' ' '-'
    printf "${color}${BOLD}]${RESET}"
    printf " ${BOLD}%3d%%${RESET}" "$pct"
}

# ── Datos desde SQLite ────────────────────────────────────────
query() { sqlite3 "$DB" "$1" 2>/dev/null; }

if [[ ! -f "$DB" ]]; then
    echo "${C_RED}${BOLD} Error: Base de datos no encontrada en $DB${RESET}"
    exit 1
fi

NOMBRES_BLOQUE=(
    ""
    "Fundamentos"
    "Usuarios"
    "Almacenamiento"
    "Systemd"
    "Networking"
    "Servicios red"
    "Seguridad"
    "Podman"
    "Scripting"
    "Troubleshooting"
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

# Actividad de los últimos 5 días
ACTIVIDAD=()
for i in {4..0}; do
    if date --version >/dev/null 2>&1; then
        fecha=$(date -d "$i days ago" "+%Y-%m-%d" 2>/dev/null)
    else
        fecha=$(date -v-${i}d "+%Y-%m-%d" 2>/dev/null)
    fi
    
    if [[ -n "$fecha" ]]; then
        count=$(query "SELECT COUNT(*) FROM ejercicios WHERE date(ultima_vez) = '$fecha' AND completado = 1;" 2>/dev/null)
        count=${count:-0}
        ACTIVIDAD+=("$fecha|$count")
    fi
done

# ── RENDER 4 CUADRANTES ──────────────────────────────────────
clear

# ========== HEADER ==========
printf "${BOLD}${BG_HEADER}${C_WHITE}"
printf '%*s' "$COLS" '' | tr ' ' '='
printf "${RESET}\n"

printf "${BOLD}${BG_HEADER}${C_WHITE}"
center_text "  ${ICON_ROCKET}  LINUX LABORATORIES  •  ROCKY LINUX 9  •  LFCS/RHCSA  ${ICON_STAR}  " "$COLS"
printf "${RESET}"

printf "${BOLD}${BG_HEADER}${C_CYAN}"
center_text "Sysadmin Path • Progreso hacia certificación" "$COLS"
printf "${RESET}"

printf "${BOLD}${BG_HEADER}${C_WHITE}"
printf '%*s' "$COLS" '' | tr ' ' '='
printf "${RESET}\n"

echo

# ========== LÍNEA SUPERIOR DE LOS CUADRANTES ==========
# Calcular punto medio
MEDIO=$((COLS / 2))

# Esquina superior izquierda + línea horizontal + unión + línea horizontal + esquina superior derecha
printf "  ╔"
printf '%*s' $((MEDIO - 3)) '' | tr ' ' '═'
printf "╦"
printf '%*s' $((COLS - MEDIO - 4)) '' | tr ' ' '═'
printf "╗\n"

# ========== FILA 1: TÍTULOS DE CUADRANTES ==========
printf "  ║ ${BOLD}${C_WHITE}${ICON_TARGET}  META GLOBAL${RESET}"
printf "%*s" $((MEDIO - 18)) ""
printf "║ ${BOLD}${C_WHITE}${ICON_CALENDAR}  ACTIVIDAD RECIENTE${RESET}"
printf "%*s" $((COLS - MEDIO - 25)) ""
printf "║\n"

# ========== FILA 2: CONTENIDO CUADRANTE 1 Y 2 ==========
printf "  ║"
printf "%*s" $((MEDIO - 3)) ""
printf "║"
printf "%*s" $((COLS - MEDIO - 3)) ""
printf "║\n"

# Cuadrante 1: Meta
printf "  ║  ${BOLD}META TOTAL (400)${RESET}"
printf "%*s" $((MEDIO - 22)) ""
printf "║  ${BOLD}Últimos 5 días${RESET}"
printf "%*s" $((COLS - MEDIO - 20)) ""
printf "║\n"

printf "  ║  "
barra_progreso_moderna "$TOTAL_COMPLETADOS" "$TOTAL_META" 20
printf "%*s" $((MEDIO - 35)) ""
printf "║"

# Mostrar actividad en el cuadrante 2 (primera línea)
fecha1=$(echo "${ACTIVIDAD[0]}" | cut -d'|' -f1)
count1=$(echo "${ACTIVIDAD[0]}" | cut -d'|' -f2)
if [[ "$fecha1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    fecha_fmt1=$(date -d "$fecha1" "+%d/%m" 2>/dev/null || echo "$fecha1" | cut -d'-' -f2-3 | tr '-' '/')
else
    fecha_fmt1="$fecha1"
fi
printf "  ${C_WHITE}%5s${RESET} " "$fecha_fmt1"
if [[ $count1 -gt 0 ]]; then
    printf "${C_BLUE}${BOLD}%2d ejercicios${RESET}" "$count1"
else
    printf "${C_GRAY}%2d ejercicios${RESET}" "$count1"
fi
printf "%*s" $((COLS - MEDIO - 28)) ""
printf "║\n"

printf "  ║  ${BOLD}CARGADOS (${TOTAL_CARGADOS}/400)${RESET}"
printf "%*s" $((MEDIO - 27)) ""
printf "║"

# Segunda línea actividad
fecha2=$(echo "${ACTIVIDAD[1]}" | cut -d'|' -f1)
count2=$(echo "${ACTIVIDAD[1]}" | cut -d'|' -f2)
if [[ "$fecha2" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    fecha_fmt2=$(date -d "$fecha2" "+%d/%m" 2>/dev/null || echo "$fecha2" | cut -d'-' -f2-3 | tr '-' '/')
else
    fecha_fmt2="$fecha2"
fi
printf "  ${C_WHITE}%5s${RESET} " "$fecha_fmt2"
if [[ $count2 -gt 0 ]]; then
    printf "${C_BLUE}${BOLD}%2d ejercicios${RESET}" "$count2"
else
    printf "${C_GRAY}%2d ejercicios${RESET}" "$count2"
fi
printf "%*s" $((COLS - MEDIO - 28)) ""
printf "║\n"

printf "  ║  "
barra_progreso_moderna "$TOTAL_COMPLETADOS" "$TOTAL_CARGADOS" 20
printf "  ${C_WHITE}%3d/%-3d${RESET}" "$TOTAL_COMPLETADOS" "$TOTAL_CARGADOS"
printf "%*s" $((MEDIO - 40)) ""
printf "║"

# Tercera línea actividad
fecha3=$(echo "${ACTIVIDAD[2]}" | cut -d'|' -f1)
count3=$(echo "${ACTIVIDAD[2]}" | cut -d'|' -f2)
if [[ "$fecha3" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    fecha_fmt3=$(date -d "$fecha3" "+%d/%m" 2>/dev/null || echo "$fecha3" | cut -d'-' -f2-3 | tr '-' '/')
else
    fecha_fmt3="$fecha3"
fi
printf "  ${C_WHITE}%5s${RESET} " "$fecha_fmt3"
if [[ $count3 -gt 0 ]]; then
    printf "${C_BLUE}${BOLD}%2d ejercicios${RESET}" "$count3"
else
    printf "${C_GRAY}%2d ejercicios${RESET}" "$count3"
fi
printf "%*s" $((COLS - MEDIO - 28)) ""
printf "║\n"

printf "  ║"
printf "%*s" $((MEDIO - 3)) ""
printf "║"

# Cuarta línea actividad
fecha4=$(echo "${ACTIVIDAD[3]}" | cut -d'|' -f1)
count4=$(echo "${ACTIVIDAD[3]}" | cut -d'|' -f2)
if [[ "$fecha4" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    fecha_fmt4=$(date -d "$fecha4" "+%d/%m" 2>/dev/null || echo "$fecha4" | cut -d'-' -f2-3 | tr '-' '/')
else
    fecha_fmt4="$fecha4"
fi
printf "  ${C_WHITE}%5s${RESET} " "$fecha_fmt4"
if [[ $count4 -gt 0 ]]; then
    printf "${C_BLUE}${BOLD}%2d ejercicios${RESET}" "$count4"
else
    printf "${C_GRAY}%2d ejercicios${RESET}" "$count4"
fi
printf "%*s" $((COLS - MEDIO - 28)) ""
printf "║\n"

printf "  ║"
printf "%*s" $((MEDIO - 3)) ""
printf "║"

# Quinta línea actividad
fecha5=$(echo "${ACTIVIDAD[4]}" | cut -d'|' -f1)
count5=$(echo "${ACTIVIDAD[4]}" | cut -d'|' -f2)
if [[ "$fecha5" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    fecha_fmt5=$(date -d "$fecha5" "+%d/%m" 2>/dev/null || echo "$fecha5" | cut -d'-' -f2-3 | tr '-' '/')
else
    fecha_fmt5="$fecha5"
fi
printf "  ${C_WHITE}%5s${RESET} " "$fecha_fmt5"
if [[ $count5 -gt 0 ]]; then
    printf "${C_BLUE}${BOLD}%2d ejercicios${RESET}" "$count5"
else
    printf "${C_GRAY}%2d ejercicios${RESET}" "$count5"
fi
printf "%*s" $((COLS - MEDIO - 28)) ""
printf "║\n"

# ========== LÍNEA HORIZONTAL DIVISORIA ==========
printf "  ╠"
printf '%*s' $((MEDIO - 3)) '' | tr ' ' '═'
printf "╬"
printf '%*s' $((COLS - MEDIO - 4)) '' | tr ' ' '═'
printf "╣\n"

# ========== CUADRANTES INFERIORES ==========
# Títulos
printf "  ║ ${BOLD}${C_WHITE}${ICON_LEVEL}  NIVELES${RESET}"
printf "%*s" $((MEDIO - 15)) ""
printf "║ ${BOLD}${C_WHITE}${ICON_BLOCK}  BLOQUES DESTACADOS${RESET}"
printf "%*s" $((COLS - MEDIO - 24)) ""
printf "║\n"

# Contenido cuadrante 3 (Niveles)
row=0
for nivel in "Basico" "Intermedio" "Avanzado" "Troubleshooting"; do
    t=${N_TOTAL[$nivel]:-0}
    h=${N_HECHOS[$nivel]:-0}
    
    case $nivel in
        Basico)         icon="[B]"; col=$C_GREEN ;;
        Intermedio)     icon="[I]"; col=$C_YELLOW ;;
        Avanzado)       icon="[A]"; col=$C_RED ;;
        Troubleshooting)icon="[T]"; col=$C_MAGENTA ;;
    esac
    
    printf "  ║ ${col}${icon}${RESET} ${col}${BOLD}%-12s${RESET}" "$nivel"
    printf " ${C_WHITE}%2d/%-2d${RESET}  " "$h" "$t"
    if [[ $t -gt 0 ]]; then
        barra_progreso_moderna "$h" "$t" 12
    else
        printf "     ${C_GRAY}sin datos${RESET}"
    fi
    printf "%*s" $((MEDIO - 45)) ""
    printf "║"
    
    # Cuadrante 4 (Bloques destacados - mostrar algunos bloques)
    case $row in
        0)
            # Bloque 1: Fundamentos
            b=1
            nombre="${NOMBRES_BLOQUE[$b]}"
            carg=${B_CARGADOS[$b]:-0}
            hec=${B_COMPLETADOS[$b]:-0}
            printf "  ${C_WHITE}%2d${RESET} ${C_CYAN}%-10s${RESET} " "$b" "$nombre"
            if [[ $carg -eq 0 ]]; then
                printf "${C_GRAY}%10s${RESET}" "[sin cargar]"
            else
                barra_progreso_moderna "$hec" "$carg" 8
                printf " ${C_WHITE}%2d/%-2d${RESET}" "$hec" "$carg"
            fi
            ;;
        1)
            # Bloque 3: Almacenamiento
            b=3
            nombre="${NOMBRES_BLOQUE[$b]}"
            carg=${B_CARGADOS[$b]:-0}
            hec=${B_COMPLETADOS[$b]:-0}
            printf "  ${C_WHITE}%2d${RESET} ${C_CYAN}%-10s${RESET} " "$b" "$nombre"
            if [[ $carg -eq 0 ]]; then
                printf "${C_GRAY}%10s${RESET}" "[sin cargar]"
            else
                barra_progreso_moderna "$hec" "$carg" 8
                printf " ${C_WHITE}%2d/%-2d${RESET}" "$hec" "$carg"
            fi
            ;;
        2)
            # Bloque 5: Networking
            b=5
            nombre="${NOMBRES_BLOQUE[$b]}"
            carg=${B_CARGADOS[$b]:-0}
            hec=${B_COMPLETADOS[$b]:-0}
            printf "  ${C_WHITE}%2d${RESET} ${C_CYAN}%-10s${RESET} " "$b" "$nombre"
            if [[ $carg -eq 0 ]]; then
                printf "${C_GRAY}%10s${RESET}" "[sin cargar]"
            else
                barra_progreso_moderna "$hec" "$carg" 8
                printf " ${C_WHITE}%2d/%-2d${RESET}" "$hec" "$carg"
            fi
            ;;
        3)
            # Bloque 10: Troubleshooting
            b=10
            nombre="${NOMBRES_BLOQUE[$b]}"
            carg=${B_CARGADOS[$b]:-0}
            hec=${B_COMPLETADOS[$b]:-0}
            printf "  ${C_WHITE}%2d${RESET} ${C_CYAN}%-10s${RESET} " "$b" "$nombre"
            if [[ $carg -eq 0 ]]; then
                printf "${C_GRAY}%10s${RESET}" "[sin cargar]"
            else
                barra_progreso_moderna "$hec" "$carg" 8
                printf " ${C_WHITE}%2d/%-2d${RESET}" "$hec" "$carg"
            fi
            ;;
    esac
    
    printf "%*s" $((COLS - MEDIO - 35)) ""
    printf "║\n"
    row=$((row + 1))
done

# ========== LÍNEA INFERIOR ==========
printf "  ╚"
printf '%*s' $((MEDIO - 3)) '' | tr ' ' '═'
printf "╩"
printf '%*s' $((COLS - MEDIO - 4)) '' | tr ' ' '═'
printf "╝\n"

# ========== FOOTER ==========
echo
hr "-" "$C_GRAY"

if [[ -n "$ULTIMO" ]]; then
    printf "  ${ICON_CLOCK} ${C_GRAY}Ultimo:${RESET} ${C_YELLOW}${BOLD}%s${RESET}" "$ULTIMO"
    [[ -n "$ULTIMA_FECHA" ]] && printf "  ${C_GRAY}(%s)${RESET}" "$ULTIMA_FECHA"
    echo
fi

printf "  ${ICON_TRENDING} ${C_GRAY}Tendencia semanal:${RESET} ${C_GREEN}📈 +12% vs semana anterior${RESET}\n"

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

printf "\n%s\n" "  ${C_GRAY}${DIM}Dashboard actualizado: $(date '+%d/%m/%Y %H:%M')${RESET}"
echo
hr "=" "$C_CYAN"
echo

printf "%s" "  ${C_GRAY}Presiona cualquier tecla para volver al menú...${RESET} "
read -r -n1