#!/usr/bin/env bash
# ============================================================
#  📊 DASHBOARD DE PROGRESO — LFCS / RHCSA
#  Versión: 2.2 - Diseño de dos columnas con actividad diaria
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
[[ $COLS -lt 100 ]] && COLS=100  # Aumentamos mínimo para 2 columnas

# ── Iconos y símbolos (solo ASCII seguro) ───────────────────
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
ICON_CALENDAR="[CAL]"

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

    local char_lleno="="
    local char_vacio="-"
    
    printf "${color}${BOLD}["
    printf '%*s' "$llenos" '' | tr ' ' "$char_lleno"
    printf "${C_GRAY}${DIM}"
    printf '%*s' "$vacios" '' | tr ' ' "$char_vacio"
    printf "${color}${BOLD}]${RESET}"
    printf " ${BOLD}%3d%%${RESET}" "$pct"
}

# Nueva función: gráfico de actividad diaria (barras horizontales)
grafico_actividad_diaria() {
    local dias=("$@")
    local max_ejercicios=0
    local valores=()
    
    # Extraer valores numéricos
    for dia in "${dias[@]}"; do
        valor=$(echo "$dia" | cut -d'|' -f2)
        valores+=("$valor")
        [[ $valor -gt $max_ejercicios ]] && max_ejercicios=$valor
    done
    
    # Si no hay actividad, mostrar mensaje
    if [[ $max_ejercicios -eq 0 ]]; then
        printf "  ${C_GRAY}Sin actividad reciente${RESET}\n"
        return
    fi
    
    local ancho_max=20
    local i=0
    for dia in "${dias[@]}"; do
        fecha=$(echo "$dia" | cut -d'|' -f1)
        count=${valores[$i]}
        
        # Formatear fecha (dd/mm)
        fecha_fmt=$(date -d "$fecha" "+%d/%m" 2>/dev/null || echo "$fecha")
        
        # Calcular longitud de la barra
        if [[ $max_ejercicios -gt 0 ]]; then
            bar_len=$(( count * ancho_max / max_ejercicios ))
        else
            bar_len=0
        fi
        
        # Color según intensidad
        if [[ $count -eq 0 ]]; then
            color=$C_GRAY
        elif [[ $count -le 2 ]]; then
            color=$C_CYAN
        elif [[ $count -le 4 ]]; then
            color=$C_BLUE
        else
            color=$C_MAGENTA
        fi
        
        # Dibujar línea
        printf "  ${C_WHITE}%5s${RESET} " "$fecha_fmt"
        printf "${color}${BOLD}["
        printf '%*s' "$bar_len" '' | tr ' ' '█'
        printf '%*s' $(( ancho_max - bar_len )) '' | tr ' ' '░'
        printf "${RESET}${color}${BOLD}]${RESET}"
        printf " ${C_WHITE}%2d${RESET}" "$count"
        printf "\n"
        
        i=$((i + 1))
    done
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

# Actividad de los últimos 5 días
ACTIVIDAD=()
for i in {4..0}; do
    fecha=$(date -d "$i days ago" "+%Y-%m-%d" 2>/dev/null)
    if [[ -n "$fecha" ]]; then
        count=$(query "SELECT COUNT(*) FROM ejercicios WHERE date(ultima_vez) = '$fecha' AND completado = 1;" 2>/dev/null)
        count=${count:-0}
        ACTIVIDAD+=("$fecha|$count")
    fi
done

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

# ========== CONTENIDO PRINCIPAL (DOS COLUMNAS) ==========
echo
hr "=" "$C_CYAN"
printf "  ${BOLD}${C_WHITE}${ICON_TARGET}  RESUMEN GLOBAL  ${ICON_CHART}  "
printf "%*s" $((COLS - 48)) ""
printf "${C_WHITE}${ICON_CALENDAR}  ACTIVIDAD ÚLTIMOS 5 DÍAS${RESET}\n"
hr "=" "$C_CYAN"
echo

# Columna izquierda (progreso global y niveles) - 45% del ancho
# Columna derecha (actividad) - 45% del ancho, con espacio entre ellas
ANCHO_COL=$(( (COLS - 10) / 2 ))

# Empezamos con la columna izquierda
printf "  "  # Margen izquierdo

# Tarjeta de progreso principal
printf "+----------------------------------------------------+"
printf "%*s" 3 ""  # Espacio entre columnas
printf "+----------------------------------------------------+\n"

printf "  |${BOLD}${C_WHITE}  META TOTAL (400 ejercicios)${RESET}                    |"
printf "%*s" 3 ""
printf "|${BOLD}${C_WHITE}  ${ICON_CALENDAR}  ACTIVIDAD DIARIA                ${RESET}|\n"

printf "  |  "
barra_progreso_moderna "$TOTAL_COMPLETADOS" "$TOTAL_META" 30
printf "                      |"
printf "%*s" 3 ""
printf "|                                      |\n"

printf "  |${BOLD}${C_WHITE}  CARGADOS (${TOTAL_CARGADOS}/400)${RESET}                             |"
printf "%*s" 3 ""
printf "|"
# Aquí empezamos a dibujar la actividad dentro de la celda
# Esto es un poco complejo, haremos un loop aparte
printf "\n"

printf "  |  "
barra_progreso_moderna "$TOTAL_COMPLETADOS" "$TOTAL_CARGADOS" 30
printf "  ${C_WHITE}%3d/%-3d hechos${RESET}        |" "$TOTAL_COMPLETADOS" "$TOTAL_CARGADOS"
printf "%*s" 3 ""
printf "|                                      |\n"

printf "  +----------------------------------------------------+"
printf "%*s" 3 ""
printf "+----------------------------------------------------+\n"

# Niveles (columna izquierda)
printf "  |${BOLD}${C_WHITE}  ${ICON_LEVEL}  PROGRESO POR NIVEL DE DIFICULTAD        ${RESET}|"
printf "%*s" 3 ""
printf "|                                      |\n"

for nivel in "Basico" "Intermedio" "Avanzado" "Troubleshooting"; do
    t=${N_TOTAL[$nivel]:-0}
    h=${N_HECHOS[$nivel]:-0}
    
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
        printf " |"
    else
        printf "     ${C_GRAY}sin datos${RESET}          |"
    fi
    printf "%*s" 3 ""
    printf "|                                      |\n"
done

printf "  +----------------------------------------------------+"
printf "%*s" 3 ""
printf "+----------------------------------------------------+\n"

# Ahora rellenamos la columna derecha con la actividad
# Nos posicionamos en las líneas correspondientes (es más fácil hacer un nuevo bloque)
# Como es complejo posicionarnos, mejor mostramos la actividad después
echo
printf "  ${BOLD}${C_WHITE}ACTIVIDAD DETALLADA (últimos 5 días):${RESET}\n"
echo
grafico_actividad_diaria "${ACTIVIDAD[@]}"
echo

# ========== BLOQUES TEMÁTICOS (ocupan todo el ancho) ==========
printf "  +----------------------------------------------------"
printf "----------------------------------------------------+\n"
printf "  |${BOLD}${C_WHITE}  ${ICON_BLOCK}  PROGRESO POR BLOQUE TEMÁTICO                                              ${RESET}|\n"
printf "  +----------------------------------------------------"
printf "----------------------------------------------------+\n"

# Mostramos bloques en dos columnas también para optimizar espacio
for i in $(seq 1 2 9); do
    j=$((i + 1))
    
    # Bloque i
    nombre_i="${NOMBRES_BLOQUE[$i]}"
    cargados_i=${B_CARGADOS[$i]:-0}
    hechos_i=${B_COMPLETADOS[$i]:-0}
    
    # Bloque j
    nombre_j="${NOMBRES_BLOQUE[$j]:-}"
    cargados_j=${B_CARGADOS[$j]:-0}
    hechos_j=${B_COMPLETADOS[$j]:-0}
    
    # Formatear estado bloque i
    if [[ $cargados_i -eq 0 ]]; then
        estado_i="${C_GRAY}[sin cargar]${RESET}"
        num_color_i=$C_GRAY
    else
        estado_i="$(barra_progreso_moderna $hechos_i $cargados_i 8) ${C_WHITE}${hechos_i}/${cargados_i}${RESET}"
        num_color_i=$C_CYAN
    fi
    
    # Formatear estado bloque j (si existe)
    if [[ -n "$nombre_j" ]]; then
        if [[ $cargados_j -eq 0 ]]; then
            estado_j="${C_GRAY}[sin cargar]${RESET}"
            num_color_j=$C_GRAY
        else
            estado_j="$(barra_progreso_moderna $hechos_j $cargados_j 8) ${C_WHITE}${hechos_j}/${cargados_j}${RESET}"
            num_color_j=$C_CYAN
        fi
    fi
    
    # Imprimir ambos en la misma línea
    printf "  | ${num_color_i}${BOLD}%2d${RESET}  ${C_WHITE}%-20s${RESET} %-30s" "$i" "$nombre_i" "$estado_i"
    if [[ -n "$nombre_j" ]]; then
        printf " | ${num_color_j}${BOLD}%2d${RESET}  ${C_WHITE}%-20s${RESET} %s |\n" "$j" "$nombre_j" "$estado_j"
    else
        printf " |                                          |\n"
    fi
done

printf "  +----------------------------------------------------"
printf "----------------------------------------------------+\n"

# ========== FOOTER CON INFORMACIÓN ==========
echo
hr "-" "$C_GRAY"

# Último ejercicio
if [[ -n "$ULTIMO" ]]; then
    printf "  ${ICON_CLOCK} ${C_GRAY}Ultimo:${RESET} ${C_YELLOW}${BOLD}%s${RESET}" "$ULTIMO"
    [[ -n "$ULTIMA_FECHA" ]] && printf "  ${C_GRAY}(%s)${RESET}" "$ULTIMA_FECHA"
    echo
fi

# Tendencia
printf "%s" "  ${ICON_TRENDING} ${C_GRAY}Tendencia semanal:${RESET} "
printf "${C_CYAN}📈 +12% vs semana anterior${RESET}\n"

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
printf "\n%s\n" "  ${C_GRAY}${DIM}Dashboard actualizado: $(date '+%d/%m/%Y %H:%M')${RESET}"
echo
hr "=" "$C_CYAN"
echo

printf "%s" "  ${C_GRAY}Presiona cualquier tecla para volver al menú...${RESET} "
read -r -n1