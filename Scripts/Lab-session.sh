#!/bin/bash
#
# Script: Lab-session.sh
# Descripción: Gestiona sesiones de laboratorio con numeración automática
# Ubicación labs: Dentro del repositorio en ~/Labs/labs/
# Comportamiento: SIEMPRE crea un nuevo lab (incrementa numeración)
# Captura: SOLO comandos y prompts (limpio de ruidos ANSI) en archivos lab-XXXX.lab
#

# Variables de configuración
REPO_DIR="$HOME/Labs"
LABS_DIR="$REPO_DIR/labs"
LAB_PREFIX="lab-"
LAB_SUFFIX=".lab"

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Función para imprimir mensajes con color
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

# Verificar que el repositorio existe
if [ ! -d "$REPO_DIR" ]; then
    print_error "El repositorio $REPO_DIR no existe"
    exit 1
fi

# Crear directorio labs si no existe
if [ ! -d "$LABS_DIR" ]; then
    mkdir -p "$LABS_DIR"
    touch "$LABS_DIR/.gitkeep"
    print_success "Directorio labs/ preparado"
fi

# Función para obtener el siguiente número de lab
get_next_lab_number() {
    local last_lab=$(ls -1 "$LABS_DIR"/${LAB_PREFIX}*${LAB_SUFFIX} 2>/dev/null | sort -V | tail -n1)
    
    if [ -z "$last_lab" ]; then
        echo "0001"
    else
        # Extraer solo los dígitos numéricos del nombre del archivo
        local last_num=$(basename "$last_lab" | tr -dc '0-9')
        local next_num=$((10#$last_num + 1))
        printf "%04d" "$next_num"
    fi
}

# Banner inicial
echo -e "\n${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        SISTEMA DE LABORATORIOS LINUX          ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}\n"

# Listar labs existentes
print_info "Laboratorios en ${BLUE}$LABS_DIR${NC}:"
if ls -1 "$LABS_DIR"/${LAB_PREFIX}*${LAB_SUFFIX} 2>/dev/null; then
    LAB_COUNT=$(ls -1 "$LABS_DIR"/${LAB_PREFIX}*${LAB_SUFFIX} 2>/dev/null | wc -l)
    print_info "Total: ${GREEN}$LAB_COUNT${NC} laboratorios\n"
else
    echo -e "  ${YELLOW}(ninguno aún)${NC}\n"
fi

# Preparar nuevo archivo
NEXT_NUM=$(get_next_lab_number)
NEW_LAB_FILE="$LABS_DIR/${LAB_PREFIX}${NEXT_NUM}${LAB_SUFFIX}"

print_info "Nuevo laboratorio: ${GREEN}${LAB_PREFIX}${NEXT_NUM}${LAB_SUFFIX}${NC}"
echo -e "\n"

read -p "¿Iniciar nueva sesión de laboratorio? [S/n]: " confirm
confirm=${confirm:-S}

if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
    print_warning "Sesión cancelada"
    exit 0
fi

# Crear el Header limpio
cat > "$NEW_LAB_FILE" << EOF
================================================================================
LABORATORIO: ${LAB_PREFIX}${NEXT_NUM}
================================================================================
Fecha inicio:  $(date '+%Y-%m-%d %H:%M:%S')
Hostname:      $(hostname)
Usuario:       $(whoami)
Sistema:       $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
Kernel:        $(uname -r)
Working Dir:   $(pwd)
GitHub:        https://github.com/jensygomez/Labs
================================================================================

EOF

print_success "Archivo de laboratorio creado"
echo -e "\n"
print_info "Iniciando captura de sesión..."
print_warning "Para finalizar escribe: ${GREEN}exit${NC}"
echo -e "\n"

sleep 2

# --- LA CLAVE DE LA LIMPIEZA ---
# TERM=dumb desactiva colores y secuencias de escape ANSI durante la grabación
# sed al final elimina posibles restos de caracteres de control (^M o retornos)
TERM=dumb script -a -f -q -c "$SHELL" "$NEW_LAB_FILE"

# Limpieza post-sesión de caracteres de control invisibles (opcional pero recomendado)
sed -i 's/\r//g' "$NEW_LAB_FILE"

# Agregar Footer
cat >> "$NEW_LAB_FILE" << EOF

================================================================================
SESIÓN FINALIZADA
================================================================================
Fecha fin:     $(date '+%Y-%m-%d %H:%M:%S')
Duración:      Sesión completada
Repositorio:   ~/Labs/labs/
================================================================================
EOF

echo -e "\n${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          SESIÓN FINALIZADA CON ÉXITO          ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}\n"

# Estadísticas
if [ -f "$NEW_LAB_FILE" ]; then
    lines=$(wc -l < "$NEW_LAB_FILE")
    size=$(du -h "$NEW_LAB_FILE" | cut -f1)
    echo -e "${BLUE}Resumen:${NC}"
    echo "  • Líneas guardadas: $lines"
    echo "  • Tamaño de archivo: $size"
fi

# Auto-Git
cd "$REPO_DIR" && git add "$NEW_LAB_FILE" 2>/dev/null
print_success "Archivo listo para sincronización automática."

exit 0