#!/bin/bash
#
# Script de instalación completa del sistema de labs y auto-sync
# Para Ubuntu 24.04 - Versión: 2.1 REFATORADA
# Autor: Jensy Gomez - Sysadmin Labs System
#

set -euo pipefail  # Strict mode: exit on error/unbound/pipefail

# ============================================================================
# COLORES CORREGIDOS (CRÍTICO)
# ============================================================================
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

# Funciones de UI
print_step() { echo -e "\n${BLUE}==>${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

# Banner profesional
banner() {
    clear
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║   INSTALADOR DE SISTEMA DE LABS Y GIT AUTO-SYNC v2.1      ║"
    echo "║   Ubuntu 24.04 - Sysadmin Production Ready                ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ============================================================================
# MAIN
# ============================================================================
banner

# PASO 1: Verificar Git
print_step "Verificando Git..."
if ! command -v git &> /dev/null; then
    print_error "Git requerido"
    read -rp "¿Instalar ahora? [S/n]: " -n1 install_git
    echo
    [[ "${install_git,,}" != "n" ]] || { print_error "Abortando"; exit 1; }
    sudo apt update && sudo apt install -y git
    print_success "Git $(git --version) instalado"
fi

# PASO 2: Configurar repositorio
print_step "Configuración del repositorio..."
read -rp "URL GitHub (ej: https://github.com/jensygomez/Labs.git): " REPO_URL
[[ -n "$REPO_URL" ]] || { print_error "URL requerida"; exit 1; }

REPO_NAME=$(basename "$REPO_URL" .git)
REPO_PATH="$HOME/$REPO_NAME"
print_warning "Clonando en: $REPO_PATH"

read -rp "¿Correcto? [S/n]: " -n1 confirm; echo
[[ "${confirm,,}" != "n" ]] || read -rp "Path alternativo: " REPO_PATH

# PASO 3: Estructura directorios
print_step "Creando ~/scripts..."
mkdir -p "$HOME/scripts"
print_success "~/scripts creado"

# PASO 4: Git clone/pull inteligente
print_step "Gestionando repositorio..."
if [[ -d "$REPO_PATH/.git" ]]; then
    print_warning "Repo existe, actualizando..."
    cd "$REPO_PATH" && git pull origin "$(git branch --show-current)"
    print_success "Repo actualizado"
else
    git clone "$REPO_URL" "$REPO_PATH"
    print_success "Repo clonado: $REPO_PATH"
fi

mkdir -p "$REPO_PATH/labs" "$REPO_PATH/.gitignore"
echo "labs/*.log" >> "$REPO_PATH/.gitignore"
echo "*.iso" >> "$REPO_PATH/.gitignore"
print_success "labs/ + .gitignore creados"

# PASO 5: GIT-AUTO-SYNC v2.1 (con stash/rebase)
print_step "Instalando git-auto-sync.sh..."
cat > "$HOME/scripts/git-auto-sync.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

readonly REPO_DIR="%s"
readonly LOG_FILE="$HOME/scripts/git-sync.log"
readonly MAX_LOG_LINES=1000

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

rotate_log() {
    [[ -f "$LOG_FILE" && $(wc -l < "$LOG_FILE") -gt $MAX_LOG_LINES ]] &&
    tail -n 500 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
}

cd "$REPO_DIR" || { log "ERROR: No se puede acceder a $REPO_DIR"; exit 1; }
[[ -d .git ]] || { log "ERROR: No es repo Git"; exit 1; }

log "=== INICIANDO AUTO-SYNC ==="
rotate_log

# 1. STASH + PULL REBASE (evita race conditions)
if [[ -n $(git status --porcelain) ]]; then
    git stash push -m "auto-stash-$(date +%s)" && log "Stash creado"
fi

git pull origin "$(git branch --show-current)" --rebase && log "✓ Pull completado"

if [[ -n $(git status --porcelain) ]]; then
    git add -A && git commit -m "Auto-sync: $(date '+%Y-%m-%d %H:%M:%S') ($(hostname))"
    git push origin "$(git branch --show-current)" && log "✓ Push completado"
else
    log "No hay cambios para sincronizar"
fi

log "=== SYNC COMPLETADO ==="
EOF

printf "$s\n" "$REPO_PATH" > "$HOME/scripts/git-auto-sync.sh.tmp"
mv "$HOME/scripts/git-auto-sync.sh.tmp" "$HOME/scripts/git-auto-sync.sh"
chmod +x "$HOME/scripts/git-auto-sync.sh"
print_success "git-auto-sync.sh v2.1 instalado"

# PASO 6: LAB-SESSION v2.1
print_step "Instalando lab-session.sh..."
cat > "$HOME/scripts/lab-session.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

readonly REPO_DIR="%s"
readonly LABS_DIR="$REPO_DIR/labs"
readonly LAB_PREFIX="lab-"
readonly LAB_SUFFIX=".lab"

print_info() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
print_success() { echo -e "\033[0;32m[✓]\033[0m $1"; }

[[ -d "$REPO_DIR" ]] || { echo "ERROR: Repo no existe"; exit 1; }
mkdir -p "$LABS_DIR"

get_next_lab() {
    local last=$(ls -1 "$LABS_DIR"/${LAB_PREFIX}*${LAB_SUFFIX} 2>/dev/null | sort -V | tail -n1)
    [[ -z "$last" ]] && echo "0001" || printf "%04d" $((10#$(basename "$last" | sed "s/${LAB_PREFIX}//;s/${LAB_SUFFIX}//") + 1))
}

NEXT_LAB=$(get_next_lab)
LAB_FILE="$LABS_DIR/${LAB_PREFIX}${NEXT_LAB}${LAB_SUFFIX}"

cat > "$LAB_FILE" << HEADER
================================================================================
LABORATORIO: ${LAB_PREFIX}${NEXT_LAB}  |  $(date '+%Y-%m-%d %H:%M:%S')
================================================================================
Hostname: $(hostname)  |  User: $(whoami)
Sistema: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
================================================================================
HEADER

echo -e "\n\033[0;32m=== LAB ${NEXT_LAB} INICIADO ===\033[0m"
echo "Archivo: \033[1;34m$LAB_FILE\033[0m"
echo "Escribe 'exit' o Ctrl+D para finalizar"
echo -e "\n\033[1;33m⚠️  Se sincronizará automáticamente c/ GitHub\033[0m\n"

script -a -f -q "$LAB_FILE"
echo "
================================================================================
LAB ${NEXT_LAB} FINALIZADO: $(date '+%Y-%m-%d %H:%M:%S')
================================================================================
" >> "$LAB_FILE"

print_success "Lab $NEXT_LAB guardado ($LAB_FILE)"
echo "Líneas: $(wc -l < "$LAB_FILE") | Tamaño: $(du -h "$LAB_FILE" | cut -f1)"
echo "Sincronizará en max 5min o: \033[1;32mgit-sync-now\033[0m"
EOF

printf "$s\n" "$REPO_PATH" > "$HOME/scripts/lab-session.sh.tmp"
mv "$HOME/scripts/lab-session.sh.tmp" "$HOME/scripts/lab-session.sh"
chmod +x "$HOME/scripts/lab-session.sh"
print_success "lab-session.sh v2.1 instalado"

# PASO 7: SYSTEMD USER TIMER
print_step "Configurando systemd timers..."
mkdir -p "$HOME/.config/systemd/user"

cat > "$HOME/.config/systemd/user/git-auto-sync.service" << EOF
[Unit]
Description=Git Auto-Sync Service
After=network-online.target

[Service]
Type=oneshot
ExecStart=$HOME/scripts/git-auto-sync.sh
EOF

cat > "$HOME/.config/systemd/user/git-auto-sync.timer" << EOF
[Unit]
Description=Git Auto-Sync Timer (cada 5min)
Requires=git-auto-sync.service

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
AccuracySec=1s

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now git-auto-sync.timer
sudo loginctl enable-linger "$USER"
print_success "Auto-sync cada 5min ✓ activo"

# PASO 8: ALIASES ESTÁTICOS (CORREGIDO)
print_step "Configurando aliases permanentes..."
[[ -f "$HOME/.bashrc.backup" ]] || cp "$HOME/.bashrc" "$HOME/.bashrc.backup"

cat >> "$HOME/.bashrc" << EOF

# ============================================================================
# SYSADMIN LABS SYSTEM v2.1 - Jensy Gomez
# ============================================================================
alias lab="$HOME/scripts/lab-session.sh"
alias labs="ls -lht $REPO_PATH/labs/ | head -20"
alias labs-all="ls -lh \$REPO_PATH/labs/"
alias git-sync-status='systemctl --user status git-auto-sync.timer'
alias git-sync-now='systemctl --user start git-auto-sync.service'
alias git-sync-log='tail -f ~/scripts/git-sync.log'

# Git config para commits limpios
export GIT_AUTHOR_NAME="Jensy Gomez"
export GIT_AUTHOR_EMAIL="jensygomez@example.com"  # ← Cambia tu email
EOF

print_success "Aliases + Git config agregados"

# RESUMEN FINAL
echo -e "\n${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              ✓ INSTALACIÓN v2.1 OK          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"

cat << SUMMARY

${BLUE}✅ Estructura:${NC}
  ~/scripts/                 → Sistema
  $REPO_PATH/labs/           → Tus labs (Git tracked)

${BLUE}🚀 Comandos:${NC}
  source ~/.bashrc           → Activar aliases
  lab                        → Nuevo lab-0001.lab
  labs                       → Últimos 20 labs
  git-sync-now               → Sync inmediato

${BLUE}⚙️ Auto-sync:${NC}
  Timer: Cada 5 minutos (pull+stash+push)
  Log: ~/scripts/git-sync.log
  Status: git-sync-status

${YELLOW}🎯 Perfecto para RHCSA labs + cloud-init VMs${NC}

SUMMARY

print_success "¡LISTO! Ejecuta: source ~/.bashrc && lab"
