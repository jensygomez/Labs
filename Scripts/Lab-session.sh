#!/bin/bash
#
# Script: git-auto-sync.sh
# Descripción: Sincroniza archivos de laboratorio con GitHub
# Modos: 
#   - Interactivo (ejecución manual): muestra colores y mensajes
#   - Silencioso (ejecutado por cron): no muestra nada
#

# Variables
REPO_DIR="$HOME/Labs"
REMOTE="origin"
BRANCH="main"

# Detectar si estamos siendo ejecutados por cron
if [ -t 0 ]; then
    # Modo interactivo (terminal) - MOSTRAR TODO
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    NC='\033[0m'
    
    echo -e "\n${GREEN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║       AUTO-SYNC GITHUB - LABORATORIOS        ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
    echo -e "${BLUE}[INFO]${NC} Sincronizando repositorio de laboratorios..."
else
    # Modo silencioso (cron) - REDIRIGIR TODO A /dev/null
    exec >/dev/null 2>&1
fi

# Cambiar al directorio del repositorio
cd "$REPO_DIR" 2>/dev/null || exit 1

# Verificar que es un repo git
if [ ! -d .git ]; then
    [ -t 0 ] && echo -e "${RED}[ERROR]${NC} No es un repositorio Git"
    exit 1
fi

# Pull con rebase
if [ -t 0 ]; then
    echo -e "${BLUE}[INFO]${NC} git pull --rebase $REMOTE $BRANCH"
fi

if git pull --rebase "$REMOTE" "$BRANCH" >/dev/null 2>&1; then
    [ -t 0 ] && echo -e "${GREEN}[✓]${NC} Pull completado"
else
    [ -t 0 ] && echo -e "${RED}[✗]${NC} Error en pull"
    exit 1
fi

# Push
if [ -t 0 ]; then
    echo -e "${BLUE}[INFO]${NC} git push $REMOTE $BRANCH"
fi

if git push "$REMOTE" "$BRANCH" >/dev/null 2>&1; then
    [ -t 0 ] && echo -e "${GREEN}[✓]${NC} Push completado"
    [ -t 0 ] && echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
    [ -t 0 ] && echo -e "${GREEN}║       SINCRONIZACIÓN COMPLETADA ✓             ║${NC}"
    [ -t 0 ] && echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
else
    [ -t 0 ] && echo -e "${RED}[✗]${NC} Error en push"
    exit 1
fi

exit 0
