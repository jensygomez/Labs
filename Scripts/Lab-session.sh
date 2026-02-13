#!/bin/bash
#
# Script: lab-session.sh
# Descripción: Gestiona sesiones de laboratorio con numeración automática
# Ubicación labs: Dentro del repositorio en ~/Labs/labs/
# Comportamiento: SIEMPRE crea un nuevo lab (incrementa numeración)
# Captura: Comandos + outputs + errores en archivos lab-XXXX.lab
#

# Variables de configuración
REPO_DIR="$HOME/Labs"                 # ← TU REPO REAL
LABS_DIR="$REPO_DIR/labs"
LAB_PREFIX="lab-"
LAB_SUFFIX=".lab"

# Colores para output (CORREGIDOS)
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Función para imprimir mensajes con color
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Verificar que el repositorio existe
if [ ! -d "$REPO_DIR" ]; then
    print_error "El repositorio $REPO_DIR no existe"
    print_warning "Edita la variable REPO_DIR en el script con el path correcto"
    exit 1
fi

# Crear directorio labs dentro del repo si no existe
if [ ! -d "$LABS_DIR" ]; then
    mkdir -p "$LABS_DIR"
    print_success "Directorio labs/ creado en el repositorio"
    
    # Crear .gitkeep para que Git trackee la carpeta
    touch "$LABS_DIR/.gitkeep"
    print_success ".gitkeep creado para tracking de Git"
fi

# Función para obtener el siguiente número de lab
get_next_lab_number() {
    local last_lab=$(ls -1 "$LABS_DIR"/${LAB_PREFIX}*${LAB_SUFFIX} 2>/dev/null | sort -V | tail -n1)
    
    if [ -z "$last_lab" ]; then
        # No hay labs, empezar en 0001
        echo "0001"
    else
        # Extraer número del último lab
        local last_num=$(basename "$last_lab" | sed "s/${LAB_PREFIX}//;s/${LAB_SUFFIX}//")
        # Incrementar (quitando ceros a la izquierda y luego formateando)
        local next_num=$((10#$last_num + 1))
        printf "%04d" "$next_num"
    fi
}

# Banner
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        SISTEMA DE LABORATORIOS LINUX         ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
echo -e "\n"

# Listar labs existentes (COLORES CORREGIDOS)
print_info "Laboratorios existentes en ${BLUE}$LABS_DIR${NC}:"
echo -e "\n"
if ls -1 "$LABS_DIR"/${LAB_PREFIX}*${LAB_SUFFIX} 2>/dev/null; then
    echo -e "\n"
    LAB_COUNT=$(ls -1 "$LABS_DIR"/${LAB_PREFIX}*${LAB_SUFFIX} 2>/dev/null | wc -l)
    print_info "Total: ${GREEN}$LAB_COUNT${NC} laboratorios"
else
    echo -e "  ${YELLOW}(ninguno aún)${NC}\n"
fi
echo -e "\n"

# Obtener siguiente número
NEXT_NUM=$(get_next_lab_number)
NEW_LAB_FILE="$LABS_DIR/${LAB_PREFIX}${NEXT_NUM}${LAB_SUFFIX}"

print_info "Nuevo laboratorio: ${GREEN}${LAB_PREFIX}${NEXT_NUM}${LAB_SUFFIX}${NC}"
print_info "Ruta completa: ${BLUE}$NEW_LAB_FILE${NC}"
echo -e "\n"

# Confirmar inicio de sesión
read -p "¿Iniciar nueva sesión de laboratorio? [S/n]: " confirm
confirm=${confirm:-S}

if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
    print_warning "Sesión cancelada por el usuario"
    exit 0
fi

echo -e "\n"

# Crear header del archivo lab con información del sistema
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
print_warning "TODO lo que escribas será guardado en: ${GREEN}$NEW_LAB_FILE${NC}"
print_warning "Para finalizar la sesión escribe: ${GREEN}exit${NC} o presiona ${GREEN}Ctrl+D${NC}"
echo -e "\n"
print_info "El archivo se sincronizará automáticamente con GitHub cada 5 minutos"
echo -e "\n"

# Pequeña pausa para que el usuario lea
sleep 3

# Iniciar sesión script que captura TODO
# -a = append al archivo (no sobrescribe)
# -f = flush inmediato (escribe en tiempo real)
# -q = quiet (no muestra mensajes de inicio/fin de script)
script -a -f -q "$NEW_LAB_FILE"

# Cuando el usuario sale (exit o Ctrl+D), agregar footer
echo "" >> "$NEW_LAB_FILE"
cat >> "$NEW_LAB_FILE" << EOF
================================================================================
SESIÓN FINALIZADA
================================================================================
Fecha fin:     $(date '+%Y-%m-%d %H:%M:%S')
Duración:      Sesión completada
Repositorio:   ~/Labs/labs/
================================================================================
EOF

# Mensaje de finalización
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         SESIÓN DE LABORATORIO FINALIZADA      ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
echo -e "\n"

print_success "Laboratorio guardado exitosamente"
print_info "Archivo: ${GREEN}$NEW_LAB_FILE${NC}"
echo -e "\n"

# Mostrar estadísticas del lab (CORREGIDO)
if [ -f "$NEW_LAB_FILE" ]; then
    lines=$(wc -l < "$NEW_LAB_FILE")
    size=$(du -h "$NEW_LAB_FILE" | cut -f1)
    words=$(wc -w < "$NEW_LAB_FILE")
    
    echo -e "${BLUE}Estadísticas del laboratorio:${NC}"
    echo "  • Líneas:   $lines"
    echo "  • Palabras: $words"
    echo "  • Tamaño:   $size"
    echo -e "\n"
fi

# Recordatorio sobre auto-sync
print_info "El archivo será subido a GitHub en el próximo ciclo de sincronización (máx 5 min)"
print_warning "Puedes forzar sincronización inmediata ejecutando: ${GREEN}~/scripts/Git_auto_sync.sh${NC}"
echo -e "\n"

# Agregar al git automáticamente (opcional)
cd "$REPO_DIR" && git add "$NEW_LAB_FILE" 2>/dev/null
print_success "Archivo agregado a Git staging (listo para commit/push)"
echo -e "\n"

exit 0
