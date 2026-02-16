#!/bin/bash
#
# Script: Lab-session.sh
# Modelo: script + post-procesamiento inteligente MEJORADO
# Descripción: Captura TODO en tiempo real → Genera .lab + .sh ejecutable BONITO
# Compatible: Ubuntu Server 24.04
# Uso: ./Lab-session.sh
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
echo -e "${GREEN}║     Captura → .lab CRUDO + .sh EJECUTABLE     ║${NC}"
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


print_info "Nuevo laboratorio: ${GREEN}${LAB_PREFIX}${NEXT_NUM}${LAB_SUFFIX}${NC} + .sh"
echo ""


read -p "¿Iniciar nueva sesión? [S/n]: " confirm
confirm=${confirm:-S}

if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
    print_warning "Sesión cancelada"
    exit 0
fi


# ============================================================================
# CREAR HEADER .lab
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
GitHub:        [https://github.com/jensygomez/Labs](https://github.com/jensygomez/Labs)
================================================================================

EOF


print_success "✅ Listo para capturar: $NEW_LAB_FILE"
echo ""
print_info "💡 Trabaja normalmente → 'exit' para finalizar"
echo ""


# ============================================================================
# CAPTURA EN TIEMPO REAL
# ============================================================================
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  SESIÓN ACTIVA - lab-${NEXT_NUM}                              ║"
echo "║  Todo se convierte en script EJECUTABLE automáticamente!      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Captura con prompt limpio
script -f -q -c "PS1='\u@\h:\w\$ ' bash --norc --noprofile" "$TEMP_RAW_FILE"


# ============================================================================
# POST-PROCESAMIENTO INTELIGENTE ✨
# ============================================================================

print_info "🧹 Limpiando y transformando en script profesional..."

# 1. LIMPIEZA EXHAUSTIVA → .lab limpio
sed 's/\x1b\[[0-9;]*m//g' "$TEMP_RAW_FILE" | \
sed 's/\x1b\[[0-9;]*[A-Za-z]//g' | \
sed 's/\[?[0-9]*[hl]//g' | \
sed 's/\][0-9];[^\x07]*\x07//g' | \
sed 's/\r$//g' | \
grep -v '^Script started' | \
grep -v '^Script done' | \
grep -v '^[sudo] password for' | \
grep -v '^$' | \
cat -s >> "$NEW_LAB_FILE"

rm -f "$TEMP_RAW_FILE"


# 2. GENERAR SCRIPT EJECUTABLE BONITO (.sh) 🔥
generate_beautiful_script() {
    local clean_file="$NEW_LAB_FILE"
    local script_file="${NEW_LAB_FILE}.sh"
    local lab_num="${LAB_PREFIX}${NEXT_NUM}"
    
    # Shebang + Headers profesionales
    cat > "$script_file" << EOF
#!/bin/bash

# ================================================================================
# LABORATORIO: $lab_num - NETWORKING AVANZADO
# ================================================================================
# Fecha inicio:  $(grep 'Fecha inicio:' "$clean_file" | awk '{print \$3" "\$4}')
# Hostname:      $(hostname)
# Usuario:       $(whoami)
# Sistema:       $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
# Kernel:        $(uname -r)
# GitHub:        [https://github.com/jensygomez/Labs](https://github.com/jensygomez/Labs)
# ================================================================================

EOF

    # Detectar topología automáticamente
    if grep -qE '(br0|netns|bridge|veth)' "$clean_file"; then
        cat >> "$script_file" << 'EOF'
# ================================================================================
#        TOPOLOGÍA DETECTADA AUTOMÁTICAMENTE
# ================================================================================
#
#                                     Internet
#                                        |
#                               ┌─────────────────┐
#                               │     CORE-GW     │
#                               │   [br0 10.0.0.1]│
#                               └────────┬────────┘
#                                        │
#          ┌─────────────────────────────┼─────────────────────────────┐
#          │                             │                             │
#       [NS-SRV] ← veth ←           [NS-RH] ← veth ←          [NS-SYS]
#       10.0.0.10                   10.0.0.20                 10.0.0.30
#
# ================================================================================
EOF
    fi

    cat >> "$script_file" << 'EOF'
# ================================================================================
# FILOSOFÍA: ARQUITECTURA DE SISTEMAS LINUX
# ================================================================================
#
# 1. NAMESPACES = AISLAMIENTO QUIRÚRGICO
# 2. BRIDGE = SWITCH EN MEMORIA (sin hardware)
# 3. VETH = CABLES VIRTUALES INVISIBLES
# 4. KERNEL = ÚNICA FUENTE DE VERDAD
#
# ================================================================================
EOF

    # Convertir sesión → Comandos ejecutables con EMOJIS
    awk '
    /^[a-zA-Z0-9_-]+@[a-zA-Z0-9_-]+:[^$]*\$ / {
        cmd = substr($0, match($0, /[^ ]+$/))
        
        # Detectar tipo de comando → emoji apropiado
        if (cmd ~ /^sudo ip netns add/) { print "echo \"🏠 PASO: Creando Namespace\""; print cmd; print "" }
        else if (cmd ~ /bridge/) { print "echo \"🌉 PASO: Creando Bridge\""; print cmd; print "" }
        else if (cmd ~ /veth/) { print "echo \"🔌 PASO: Cableado VETH\""; print cmd; print "" }
        else if (cmd ~ /addr add/) { print "echo \"📍 PASO: Config IP\""; print cmd; print "" }
        else if (cmd ~ /ping/) { print "echo \"✅ VERIFICANDO conectividad\""; print cmd; print "" }
        else if (cmd ~ /^#/) { gsub(/^# /, "# --- ", cmd); print cmd }
        else { print "# " cmd; print cmd; print "" }
        next
    }
    /^[a-zA-Z0-9_-]+@[a-zA-Z0-9_-]+:[^$]*# / {
        comment = substr($0, match($0, /[^ ]+$/))
        gsub(/^# /, "# ", comment)
        print comment
        next
    }
    { next }' "$clean_file" >> "$script_file"

    # Footer con verificación automática
    cat >> "$script_file" << 'EOF'

echo ""
echo "🎉 ======================================================"
echo "🎉 LABORATORIO COMPLETADO EXITOSAMENTE!"
echo "✅ Namespaces: $(sudo ip netns list | wc -l)"
echo "✅ Bridges: $(ip link show type bridge | grep -c br)"
echo "🎉 ======================================================"

# ================================================================================
# SESIÓN FINALIZADA ✓
# ================================================================================
EOF

    chmod +x "$script_file"
    print_success "🚀 Script ejecutable: $(basename "$script_file")"
}

# ✨ EJECUTAR MAGIA
generate_beautiful_script


# ============================================================================
# FINALIZAR + GIT AUTOMÁTICO
# ============================================================================
cat >> "$NEW_LAB_FILE" << EOF

================================================================================
SESIÓN FINALIZADA
================================================================================
Fecha fin:     $(date '+%Y-%m-%d %H:%M:%S')
Duración:      Sesión completada
Archivos:      ${LAB_PREFIX}${NEXT_NUM}${LAB_SUFFIX} + .sh
================================================================================
EOF

echo ""
echo -e "${GREEN}🎊 SESIÓN COMPLETADA CON ÉXITO 🎊${NC}"
echo -e "${GREEN}📁${NC} ${BLUE}$NEW_LAB_FILE${NC}  (sesión cruda)"
echo -e "${GREEN}⚡${NC} ${BLUE}${NEW_LAB_FILE}.sh${NC}  (ejecutable BONITO!)"

# Git magic
cd "$REPO_DIR" || exit 1
git add "$NEW_LAB_FILE" "${NEW_LAB_FILE}.sh" 2>/dev/null && \
git commit -m "Lab ${NEXT_NUM}: $(grep 'Kernel:' "$NEW_LAB_FILE")" 2>/dev/null && \
git push origin main 2>/dev/null && \
print_success "✅ Subido a GitHub!" || \
print_warning "Git manual: cd $REPO_DIR && git add . && git commit -m 'Lab ${NEXT_NUM}' && git push"

echo ""
print_info "Ejecutar: cd $LABS_DIR && ./lab-${NEXT_NUM}.lab.sh"
echo -e "${GREEN}¡Tu laboratorio es ahora PROFESIONAL! 💪${NC}"

exit 0
