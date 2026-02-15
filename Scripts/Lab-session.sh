#!/bin/bash
#
# Script: Lab-session.sh
# Modelo: script + post-procesamiento inteligente MEJORADO
# Descripción: Captura TODO en tiempo real con prompts visibles y limpieza perfecta
# Compatible: Ubuntu Server 24.04
# Uso: lab
#

# ============================================================================
# CONFIGURACIÓN
# ============================================================================
REPO_DIR="$HOME/Labs"
LABS_DIR="$REPO_DIR/labs"
LAB_PREFIX="lab-"
LAB_SUFFIX=".lab"

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ============================================================================
# FUNCIONES AUXILIARES
# ============================================================================
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

# ============================================================================
# VALIDACIONES
# ============================================================================
if [ ! -d "$REPO_DIR" ]; then
    print_error "El repositorio $REPO_DIR no existe"
    exit 1
fi

if [ ! -d "$LABS_DIR" ]; then
    mkdir -p "$LABS_DIR"
    touch "$LABS_DIR/.gitkeep"
    print_success "Directorio labs/ creado"
fi

# ============================================================================
# OBTENER SIGUIENTE NÚMERO DE LAB
# ============================================================================
get_next_lab_number() {
    local last_lab=$(ls -1 "$LABS_DIR"/${LAB_PREFIX}*${LAB_SUFFIX} 2>/dev/null | sort -V | tail -n1)
    
    if [ -z "$last_lab" ]; then
        echo "0001"
    else
        local last_num=$(basename "$last_lab" | tr -dc '0-9')
        local next_num=$((10#$last_num + 1))
        printf "%04d" "$next_num"
    fi
}

# ============================================================================
# BANNER INICIAL
# ============================================================================
echo -e "\n${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        SISTEMA DE LABORATORIOS LINUX          ║${NC}"
echo -e "${GREEN}║          Captura en Tiempo Real               ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}\n"

# Listar labs existentes
print_info "Laboratorios en ${BLUE}$LABS_DIR${NC}:"
if ls -1 "$LABS_DIR"/${LAB_PREFIX}*${LAB_SUFFIX} 2>/dev/null | head -5; then
    LAB_COUNT=$(ls -1 "$LABS_DIR"/${LAB_PREFIX}*${LAB_SUFFIX} 2>/dev/null | wc -l)
    print_info "Total: ${GREEN}$LAB_COUNT${NC} laboratorios"
    if [ $LAB_COUNT -gt 5 ]; then
        echo -e "  ${YELLOW}... y $((LAB_COUNT - 5)) más${NC}"
    fi
else
    echo -e "  ${YELLOW}(ninguno aún)${NC}"
fi
echo ""

# ============================================================================
# PREPARAR NUEVO LAB
# ============================================================================
NEXT_NUM=$(get_next_lab_number)
NEW_LAB_FILE="$LABS_DIR/${LAB_PREFIX}${NEXT_NUM}${LAB_SUFFIX}"
TEMP_RAW_FILE=$(mktemp)

print_info "Nuevo laboratorio: ${GREEN}${LAB_PREFIX}${NEXT_NUM}${LAB_SUFFIX}${NC}"
echo ""

read -p "¿Iniciar nueva sesión de laboratorio? [S/n]: " confirm
confirm=${confirm:-S}

if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
    print_warning "Sesión cancelada"
    exit 0
fi

# ============================================================================
# CREAR HEADER
# ============================================================================
cat > "$NEW_LAB_FILE" << EOF
================================================================================
LABORATORIO: ${LAB_PREFIX}${NEXT_NUM}
================================================================================
Fecha inicio:  $(date '+%Y-%m-%d %H:%M:%S')
Hostname:      $(hostname)
Usuario:       $(whoami)
Sistema:       $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2 2>/dev/null || echo "Linux")
Kernel:        $(uname -r)
Working Dir:   $(pwd)
GitHub:        https://github.com/jensygomez/Labs
================================================================================

EOF

print_success "Archivo creado: $NEW_LAB_FILE"
echo ""
print_info "Iniciando captura en tiempo real..."
print_warning "Para finalizar escribe: ${GREEN}exit${NC}"
echo ""

sleep 1

# ============================================================================
# INICIAR CAPTURA CON SCRIPT
# ============================================================================
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  SESIÓN DE LABORATORIO ACTIVA - lab-${NEXT_NUM}"
echo "║  Trabajas NORMALMENTE - Todo se guarda automáticamente       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Ejecutar script con captura
# Usamos un prompt simple sin colores para evitar secuencias ANSI
script -f -q -c "PS1='\u@\h:\w\$ ' bash --norc --noprofile" "$TEMP_RAW_FILE"

# ============================================================================
# POST-PROCESAMIENTO: LIMPIEZA EXHAUSTIVA
# ============================================================================
# Pipeline de limpieza:
# 1. Eliminar secuencias de escape ANSI de colores: \x1b[...m
# 2. Eliminar secuencias de control de cursor: \x1b[...
# 3. Eliminar bracketed paste mode: [?2004h y [?2004l
# 4. Eliminar secuencias de título de ventana: ]0;...
# 5. Eliminar retornos de carro \r
# 6. Eliminar líneas de Script started/done
# 7. Reducir múltiples líneas vacías a una sola

sed 's/\x1b\[[0-9;]*m//g' "$TEMP_RAW_FILE" | \
sed 's/\x1b\[[0-9;]*[A-Za-z]//g' | \
sed 's/\[?[0-9]*[hl]//g' | \
sed 's/\][0-9];[^\x07]*\x07//g' | \
sed 's/\][0-9];[^	]*	//g' | \
sed 's/\r$//g' | \
grep -v '^Script started' | \
grep -v '^Script done' | \
cat -s >> "$NEW_LAB_FILE"

# Limpiar archivo temporal
rm -f "$TEMP_RAW_FILE"

# ============================================================================
# FINALIZAR SESIÓN
# ============================================================================
sync

# Agregar footer
cat >> "$NEW_LAB_FILE" << EOF

================================================================================
SESIÓN FINALIZADA
================================================================================
Fecha fin:     $(date '+%Y-%m-%d %H:%M:%S')
Duración:      Sesión completada
Repositorio:   ~/Labs/labs/
================================================================================
EOF

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          SESIÓN FINALIZADA CON ÉXITO          ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# ESTADÍSTICAS
# ============================================================================
if [ -f "$NEW_LAB_FILE" ]; then
    lines=$(wc -l < "$NEW_LAB_FILE")
    size=$(du -h "$NEW_LAB_FILE" | cut -f1)
    # Contar líneas que tienen el prompt (indica comandos ejecutados)
    commands=$(grep -cE '^[a-zA-Z0-9_-]+@[a-zA-Z0-9_-]+:.*\$ ' "$NEW_LAB_FILE" 2>/dev/null || echo "0")
    
    echo -e "${BLUE}Resumen:${NC}"
    echo -e "  • Archivo: ${GREEN}${LAB_PREFIX}${NEXT_NUM}${LAB_SUFFIX}${NC}"
    echo "  • Líneas guardadas: $lines"
    echo "  • Comandos ejecutados: $commands"
    echo "  • Tamaño: $size"
    echo ""
fi

# ============================================================================
# SINCRONIZACIÓN AUTOMÁTICA CON GITHUB
# ============================================================================
print_info "Sincronizando con GitHub..."

cd "$REPO_DIR" || exit 1

# Git add
if git add "$NEW_LAB_FILE" 2>/dev/null; then
    print_success "Archivo agregado al stage"
else
    print_warning "No se pudo agregar al stage (¿no es un repo git?)"
fi

# Git commit
if git commit -m "Lab ${NEXT_NUM} - $(date '+%Y-%m-%d %H:%M')" 2>/dev/null; then
    print_success "Commit creado"
    
    # Git push
    if git push origin main 2>/dev/null; then
        print_success "Subido a GitHub exitosamente"
        echo ""
        print_info "Ver en: ${GREEN}https://github.com/jensygomez/Labs/blob/main/labs/${LAB_PREFIX}${NEXT_NUM}${LAB_SUFFIX}${NC}"
    else
        print_warning "No se pudo hacer push (verifica conexión)"
        print_info "Puedes hacerlo manualmente: ${YELLOW}cd $REPO_DIR && git push${NC}"
    fi
else
    print_warning "No hay cambios para commitear"
fi

echo ""
print_success "¡Laboratorio completado y guardado!"

exit 0
