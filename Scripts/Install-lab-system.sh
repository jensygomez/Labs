#!/bin/bash
#
# Script: install-lab-system.sh
# Descripción: Instala el sistema de laboratorios en tu VM Rocky Linux
#

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   INSTALADOR - SISTEMA DE LABORATORIOS        ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}\n"

# Verificar que estamos en el directorio correcto
if [ ! -d "$HOME/Labs" ]; then
    echo -e "${YELLOW}[!] No se encontró el directorio ~/Labs${NC}"
    echo -e "${BLUE}[?] ¿Deseas clonarlo desde GitHub? [S/n]:${NC} "
    read -r response
    response=${response:-S}
    
    if [[ "$response" =~ ^[Ss]$ ]]; then
        cd "$HOME" || exit 1
        git clone https://github.com/jensygomez/Labs.git
        echo -e "${GREEN}[✓] Repositorio clonado${NC}\n"
    else
        echo -e "${YELLOW}[!] Instalación cancelada${NC}"
        exit 1
    fi
fi

# Crear directorio de Scripts si no existe
SCRIPTS_DIR="$HOME/Labs/Scripts"
mkdir -p "$SCRIPTS_DIR"

# Copiar el script Lab-session.sh
echo -e "${BLUE}[INFO] Instalando Lab-session.sh...${NC}"
cp Lab-session.sh "$SCRIPTS_DIR/Lab-session.sh"
chmod +x "$SCRIPTS_DIR/Lab-session.sh"

echo -e "${GREEN}[✓] Script instalado en $SCRIPTS_DIR${NC}\n"

# Crear alias en .bashrc
echo -e "${BLUE}[INFO] Configurando alias 'lab'...${NC}"

# Verificar si el alias ya existe
if grep -q "alias lab=" "$HOME/.bashrc" 2>/dev/null; then
    echo -e "${YELLOW}[!] El alias 'lab' ya existe en .bashrc${NC}"
    echo -e "${BLUE}[?] ¿Deseas reemplazarlo? [S/n]:${NC} "
    read -r response
    response=${response:-S}
    
    if [[ "$response" =~ ^[Ss]$ ]]; then
        sed -i '/alias lab=/d' "$HOME/.bashrc"
        echo "alias lab='$SCRIPTS_DIR/Lab-session.sh'" >> "$HOME/.bashrc"
        echo -e "${GREEN}[✓] Alias actualizado${NC}"
    fi
else
    echo "alias lab='$SCRIPTS_DIR/Lab-session.sh'" >> "$HOME/.bashrc"
    echo -e "${GREEN}[✓] Alias creado${NC}"
fi

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            INSTALACIÓN COMPLETADA             ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}\n"

echo -e "${BLUE}Para usar el sistema:${NC}"
echo -e "  1. Recarga tu .bashrc: ${YELLOW}source ~/.bashrc${NC}"
echo -e "  2. Inicia un laboratorio: ${YELLOW}lab${NC}"
echo -e "  3. Trabaja normalmente"
echo -e "  4. Finaliza con: ${YELLOW}exit${NC}"
echo ""
echo -e "${BLUE}El sistema:${NC}"
echo -e "  ✓ Captura cada comando en tiempo real"
echo -e "  ✓ Guarda todo el output inmediatamente"
echo -e "  ✓ Sube automáticamente a GitHub al finalizar"
echo ""
echo -e "${GREEN}¡Listo para usar!${NC}\n"