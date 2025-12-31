#!/bin/bash
# ============================================================
# RHCSA EX200 – Boot & Recovery - inject_V4
# Contraseña de root olvidada / bloqueada
# ============================================================

set -euo pipefail

# Colores (solo para cuando se muestre algo visible)
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
RESET='\033[0m'

LOG_FILE="/var/log/inject_boot.log"

# ============================================================
# Función de progreso (con timestamp)
# ============================================================
log_step() {
    echo -e "${CYAN}[$(date '+%H:%M:%S')] → $1${RESET}"
}

log_success() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] ✓ $1${RESET}"
}

log_error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ✗ $1${RESET}"
}

# ============================================================
# 1. Mostrar ticket bonito (solo salida visible)
# ============================================================
show_ticket() {
    clear
    log_step "Mostrando ticket del laboratorio inject_V4"

    cat << 'EOF'

\033[1;36m==================================================\033[0m
\033[1;36m     INCIDENTE – CONTRASEÑA DE ROOT OLVIDADA\033[0m
\033[1;36m==================================================\033[0m

\033[1;33mEscenario:\033[0m
  Un compañero de equipo cambió la contraseña de root
  hace unas semanas y nadie la recuerda. El acceso sudo
  de usuarios normales también falla porque requiere
  autenticación de root o está bloqueado.

\033[1;33mSíntomas observados:\033[0m
  \033[1;31m- No se puede hacer sudo (Authentication failure)\033[0m
  \033[1;31m- No se puede entrar como root directamente\033[0m
  \033[1;31m- El sistema arranca normalmente hasta login\033[0m
  \033[1;31m- No hay acceso físico al servidor (solo SSH)\033[0m

\033[1;33mTarea:\033[0m
  1. Recuperar acceso administrativo completo.
  2. Establecer una nueva contraseña segura para root.
  3. Verificar que sudo vuelve a funcionar para usuarios autorizados.
  4. Asegurar que el cambio persiste tras reinicio.

\033[1;33mRestricciones:\033[0m
  - No reinstalar el sistema
  - No usar medios externos si no es necesario
  - Mantener toda la configuración y datos existentes

\033[1;33mCriterios de validación:\033[0m
  \033[1;32m✓\033[0m Se puede hacer login como root con nueva contraseña
  \033[1;32m✓\033[0m Usuarios con permiso pueden usar sudo
  \033[1;32m✓\033[0m No hay mensajes de autenticación fallida
  \033[1;32m✓\033[0m El sistema mantiene integridad SELinux (si aplica)

\033[1;36m==================================================\033[0m

EOF

    log_success "Ticket mostrado correctamente"
}

# ============================================================
# 2. Inyectar fallo (con progreso visible y log)
# ============================================================
inject_fault() {
    log_step "Iniciando inyección del fallo: contraseña root corrupta"

    local NEW_BAD_PASS="wrong_$(openssl rand -hex 12)"

    {
        echo "============================================================"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] inject_V4 - Inyección iniciada"
        echo "   → Contraseña de root será cambiada a valor inválido"
        echo "============================================================"
    } >> "$LOG_FILE"

    log_step "Cambiando contraseña de root..."
    echo "root:$NEW_BAD_PASS" | chpasswd

    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Contraseña de root modificada exitosamente"
        echo "   → Nuevo hash inválido aplicado"
        echo "============================================================"
    } >> "$LOG_FILE"

    log_success "Fallo inyectado correctamente: acceso root bloqueado"
}

# ============================================================
# Ejecución según argumento
# ============================================================

case "${1:-}" in
    --show-ticket)
        show_ticket
        ;;
    --inject)
        inject_fault
        ;;
    *)
        echo "Uso interno: --show-ticket o --inject"
        exit 1
        ;;
esac

exit 0