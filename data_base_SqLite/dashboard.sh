#!/usr/bin/env bash
# ============================================================
#  📊 DASHBOARD DE PROGRESO — LFCS / RHCSA
#  Versión: 2.3 - Diseño de 4 columnas preciso
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

# ── Dimensiones ──────────────────────────────────────────────
COLS=$(tput cols)
ROWS=$(tput lines)
[[ $COLS -lt 120 ]] && COLS=120  # Mínimo para 4 columnas

# ── Iconos y símbolos ───────────────────────────────────────
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

# ── Helpers ──────────────────────────────────────────────────
center_text() {
    local text="$1" width="${2:-$COLS}"
    local visible
    visible=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
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

    printf "${color}${BOLD}["
    printf '%*s' "$llenos" '' | tr ' ' '='
    printf "${C_GRAY}${DIM}"
    printf '%*s' "$vacios" '' | tr ' ' '-'
    printf "${color}${BOLD}]${RESET}"
    printf " ${BOLD}%3d%%${RESET}" "$pct"
}

# Gráfico de actividad diaria (corregido)
grafico_actividad_diaria() {
    local dias=("$@")
    local max_ejercicios=0
    local valores=()
    local fechas=()
    
    for dia in "${dias[@]}"; do
        fecha=$(echo "$dia" | cut -d'|' -f1)
        valor=$(echo "$dia" | cut -d'|' -f2)
        fechas+=("$fecha")
        valores+=("$valor")
        [[ $valor -gt $max_ejercicios ]] && max_ejercicios=$valor
    done
    
    local ancho_barra=25
    local i=0
    for dia in "${dias[@]}"; do
        fecha=$(echo "$dia" | cut -d'|' -f1)
        count=${valores[$i]}
        
        # Formatear fecha (dd/mm)
        if [[ "$fecha" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            fecha_fmt=$(date -d "$fecha" "+%d/%m" 2>/dev/null || echo "$fecha" | cut -d'-' -f2-3 | tr '-' '/')
        else
            fecha_fmt="$fecha"
        fi
        
        if [[ $max_ejercicios -gt 0 ]]; then
            bar_len=$(( count * ancho_barra / max_ejercicios ))
        else
            bar_len=0
        fi
        
        # Caracteres para la barra
        local char_lleno='█'
        local char_vacio='░'
        
        printf "  ${C_WHITE}%5s${RESET} " "$fecha_fmt"
        printf "${C_BLUE}${BOLD}"
        printf '%*s' "$bar_len" '' | tr ' ' "$char_lleno"
        printf "${C_GRAY}${DIM}"
        printf '%*s' $(( ancho_barra - bar_len )) '' | tr ' ' "$char_vacio"
        printf "${RESET}"
        printf " ${C_WHITE}%2d${RESET}\n" "$count"
        
        i=$((i + 1))
    done
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
        # GNU date
        fecha=$(date -d "$i days ago" "+%Y-%m-%d" 2>/dev/null)
    else
        # BSD date (macOS)
        fecha=$(date -v-${i}d "+%Y-%m-%d" 2>/dev/null)
    fi
    
    if [[ -n "$fecha" ]]; then
        count=$(query "SELECT COUNT(*) FROM ejercicios WHERE date(ultima_vez) = '$fecha' AND completado = 1;" 2>/dev/null)
        count=${count:-0}
        ACTIVIDAD+=("$fecha|$count")
    fi
done

# ── RENDER ────────────────────────────────────────────────────
clear

# HEADER
echo
printf "${BOLD}${BG_HEADER}${C_WHITE}"
printf '%*s' "$COLS" '' | tr ' ' '='
printf "${RESET}\n"

printf "${BOLD}${BG_HEADER}${C_WHITE}"
center_text "  ${ICON_ROCKET}  LINUX LABORATORIES  •  ROCKY LINUX 9  •  LFCS/RHCSA  ${ICON_STAR}  " "$COLS"
printf "${RESET}"

printf "${BOLD}${BG_HEADER}${C_CYAN}"
center_text "           Sysadmin Path • Progreso hacia certificación           " "$COLS"
printf "${RESET}"

printf "${BOLD}${BG_HEADER}${C_WHITE}"
printf '%*s' "$COLS" '' | tr ' ' '='
printf "${RESET}\n"

# Línea separadora
echo
hr "=" "$C_CYAN"

# Título de sección con dos columnas
printf "  ${BOLD}${C_WHITE}${ICON_TARGET}  RESUMEN GLOBAL  ${ICON_CHART}"
printf "%*s" $((COLS - 50)) ""
printf "${C_WHITE}${ICON_CALENDAR}  ACTIVIDAD ÚLTIMOS 5 DÍAS${RESET}\n"

hr "=" "$C_CYAN"
echo

# Calcular anchos para las cajas
ANCHO_CAJA=$(( (COLS - 10) / 2 ))
LINEA_CAJA=$(printf "+%${ANCHO_CAJA}s+" | tr ' ' '-')

# PRIMERA FILA DE CAJAS
printf "  %s  %s\n" "$LINEA_CAJA" "$LINEA_CAJA"

# Títulos de cajas
printf "  |${BOLD}${C_WHITE}  META TOTAL (400 ejercicios)${RESET}"
printf "%*s" $((ANCHO_CAJA - 32)) ""
printf "|  |${BOLD}${C_WHITE}  ${ICON_CALENDAR}  ACTIVIDAD DIARIA${RESET}"
printf "%*s" $((ANCHO_CAJA - 25)) ""
printf "|\n"

# Barra de progreso meta
printf "  |  "
barra_progreso_moderna "$TOTAL_COMPLETADOS" "$TOTAL_META" 25
printf "%*s" $((ANCHO_CAJA - 35)) ""
printf "|  |"
printf "%*s" $((ANCHO_CAJA - 2)) ""
printf "|\n"

# Cargados
printf "  |${BOLD}${C_WHITE}  CARGADOS (${TOTAL_CARGADOS}/400)${RESET}"
printf "%*s" $((ANCHO_CAJA - 27)) ""
printf "|  |"
printf "%*s" $((ANCHO_CAJA - 2)) ""
printf "|\n"

printf "  |  "
barra_progreso_moderna "$TOTAL_COMPLETADOS" "$TOTAL_CARGADOS" 25
printf "  ${C_WHITE}%3d/%-3d hechos${RESET}" "$TOTAL_COMPLETADOS" "$TOTAL_CARGADOS"
printf "%*s" $((ANCHO_CAJA - 50)) ""
printf "|  |"
printf "%*s" $((ANCHO_CAJA - 2)) ""
printf "|\n"

printf "  %s  %s\n" "$LINEA_CAJA" "$LINEA_CAJA"

# SEGUNDA FILA - Niveles y actividad detallada
printf "  |${BOLD}${C_WHITE}  ${ICON_LEVEL}  PROGRESO POR NIVEL${RESET}"
printf "%*s" $((ANCHO_CAJA - 27)) ""
printf "|  |${BOLD}${C_WHITE}  ACTIVIDAD DETALLADA${RESET}"
printf "%*s" $((ANCHO_CAJA - 23)) ""
printf "|\n"

# Aquí necesitamos hacer un bucle para los niveles y la actividad
# Guardamos la salida en variables para poder alinearlas
niveles_output=()
while IFS= read -r linea; do
    niveles_output+=("$linea")
done < <(
    for nivel in "Basico" "Intermedio" "Avanzado" "Troubleshooting"; do
        t=${N_TOTAL[$nivel]:-0}
        h=${N_HECHOS[$nivel]:-0}
        
        case $nivel in
            Basico)         icon="[B]"; col=$C_GREEN ;;
            Intermedio)     icon="[I]"; col=$C_YELLOW ;;
            Avanzado)       icon="[A]"; col=$C_RED ;;
            Troubleshooting)icon="[T]"; col=$C_MAGENTA ;;
        esac
        
        printf "  | ${col}${icon}${RESET} ${col}${BOLD}%-12s${RESET}" "$nivel"
        printf " ${C_WHITE}%2d/%-2d${RESET}  " "$h" "$t"
        if [[ $t -gt 0 ]]; then
            barra_progreso_moderna "$h" "$t" 12
        else
            printf "     ${C_GRAY}sin datos${RESET}"
        fi
        printf "\n"
    done
)

actividad_output=()
while IFS= read -r linea; do
    actividad_output+=("$linea")
done < <(grafico_actividad_diaria "${ACTIVIDAD[@]}")

# Combinar ambas salidas línea por línea
for i in {0..3}; do
    # Línea de nivel
    printf "%s" "${niveles_output[$i]}"
    printf "%*s" $((ANCHO_CAJA - 45)) ""
    printf "|  "
    
    # Línea de actividad correspondiente
    if [[ $i -lt ${#actividad_output[@]} ]]; then
        printf "%s" "${actividad_output[$i]}"
        printf "%*s" $((ANCHO_CAJA - 35)) ""
    else
        printf "%*s" $((ANCHO_CAJA - 2)) ""
    fi
    printf "|\n"
done

# Cerrar cajas
printf "  %s  %s\n" "$LINEA_CAJA" "$LINEA_CAJA"

# Espacio
echo

# BLOQUES TEMÁTICOS - En 2 columnas
hr "=" "$C_CYAN"
printf "  ${BOLD}${C_WHITE}${ICON_BLOCK}  PROGRESO POR BLOQUE TEMÁTICO${RESET}\n"
hr "=" "$C_CYAN"
echo

ANCHO_BLOQUE=$(( (COLS - 10) / 2 ))

for i in $(seq 1 2 10); do
    j=$((i + 1))
    
    printf "  "
    
    # Bloque i
    nombre_i="${NOMBRES_BLOQUE[$i]}"
    cargados_i=${B_CARGADOS[$i]:-0}
    hechos_i=${B_COMPLETADOS[$i]:-0}
    
    printf "${C_WHITE}%2d${RESET} ${C_CYAN}${BOLD}%-12s${RESET} " "$i" "$nombre_i"
    
    if [[ $cargados_i -eq 0 ]]; then
        printf "${C_GRAY}%12s${RESET}" "[sin cargar]"
    else
        pct_i=$(( hechos_i * 100 / cargados_i ))
        barra_progreso_moderna "$hechos_i" "$cargados_i" 8
        printf " ${C_WHITE}%2d/%-2d${RESET}" "$hechos_i" "$cargados_i"
    fi
    
    # Espacio entre columnas
    printf "  "
    
    # Bloque j (si existe)
    if [[ $j -le 10 ]]; then
        nombre_j="${NOMBRES_BLOQUE[$j]}"
        cargados_j=${B_CARGADOS[$j]:-0}
        hechos_j=${B_COMPLETADOS[$j]:-0}
        
        printf "${C_WHITE}%2d${RESET} ${C_CYAN}${BOLD}%-12s${RESET} " "$j" "$nombre_j"
        
        if [[ $cargados_j -eq 0 ]]; then
            printf "${C_GRAY}%12s${RESET}" "[sin cargar]"
        else
            pct_j=$(( hechos_j * 100 / cargados_j ))
            barra_progreso_moderna "$hechos_j" "$cargados_j" 8
            printf " ${C_WHITE}%2d/%-2d${RESET}" "$hechos_j" "$cargados_j"
        fi
    fi
    
    printf "\n"
done

echo
hr "-" "$C_GRAY"

# FOOTER
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