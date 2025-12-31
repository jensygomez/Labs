#!/bin/bash
# ============================================================
# RHCSA EX200 – Boot & Recovery
# Slot: 04 (Intermedio)
# Scenario: Contraseña de root olvidada / bloqueada
# Archivo: inject_V4.sh
# ============================================================

set -euo pipefail

# ============================================================
# Función: Mostrar el ticket (bonito, con colores y clear)
# ============================================================
show_ticket() {
    clear
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
}

# ============================================================
# Función: Inyectar el fallo (silenciosa, solo cambios + log)
# ============================================================
inject_fault() {
    local LOG_FILE="/var/log/inject_boot.log"
    local NEW_BAD_PASS="wrong_$(openssl rand -hex 12)"

    {
        echo "============================================================"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - inject_V4: inyectando fallo"
        echo "   → Escenario: Contraseña de root olvidada/bloqueada"
        echo "   → Cambiando contraseña de root a valor inválido"
        echo "============================================================"
    } >> "$LOG_FILE" 2>/dev/null || true

    # Cambiar contraseña de root
    echo "root:$NEW_BAD_PASS" | chpasswd

    echo "$(date '+%Y-%m-%d %H:%M:%S') - Contraseña de root corrompida exitosamente" >> "$LOG_FILE" 2>/dev/null || true
}

# ============================================================
# Lógica principal: ¿qué queremos hacer?
# ============================================================

case "${1:-}" in
    --show-ticket)
        show_ticket
        ;;
    --inject)
        inject_fault
        ;;
    "")
        echo "Error: Debe especificar --show-ticket o --inject" >&2
        exit 1
        ;;
    *)
        echo "Opción desconocida: $1" >&2
        echo "Uso: $0 [--show-ticket | --inject]" >&2
        exit 1
        ;;
esac

exit 0