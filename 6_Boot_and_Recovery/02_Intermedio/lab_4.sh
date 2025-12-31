#!/bin/bash
# ==============================================================================
# Laboratorio 4 - RHCSA Boot & Recovery
# Escenario: Contraseña de root olvidada / bloqueada
# ==============================================================================

set -euo pipefail

# ==============================================================================
# Función 1: Mostrar ticket (solo para ejecutarse en el HOST)
# ==============================================================================
show_ticket() {
    clear
    cat << 'EOF'

\033[1;36m==================================================\033[0m
\033[1;36m     LABORATORIO 4 – CONTRASEÑA DE ROOT OLVIDADA\033[0m
\033[1;36m==================================================\033[0m

\033[1;33mEscenario:\033[0m
  Un compañero cambió la contraseña de root hace semanas
  y nadie la recuerda. El acceso sudo también falla porque
  depende de autenticación de root.

\033[1;33mSíntomas:\033[0m
  \033[1;31m- Login directo como root: denegado\033[0m
  \033[1;31m- sudo desde usuarios: Authentication failure\033[0m
  \033[1;31m- El sistema arranca normalmente hasta el login\033[0m
  \033[1;31m- Solo acceso por SSH como usuario normal\033[0m

\033[1;33mTarea:\033[0m
  Recuperar acceso administrativo completo usando técnicas
  de recuperación de GRUB (rd.break).

\033[1;33mPistas útiles:\033[0m
  • Edita la línea de GRUB y añade rd.break
  • Monta /sysroot, chroot, cambia passwd
  • touch /.autorelabel si usas SELinux
  • exit y reboot

\033[1;36m==================================================\033[0m

EOF
}

# ==============================================================================
# Función 2: Aplicar el laboratorio en la VM (silencioso + log)
# ==============================================================================
apply_lab() {
    local LOG="/var/log/lab_4.log"
    local BAD_PASS="bad_$(openssl rand -hex 12)"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Laboratorio 4 iniciado" >> "$LOG"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Cambiando contraseña de root a valor inválido..." >> "$LOG"
    echo "root:$BAD_PASS" | chpasswd

    echo "[$(ddate '+%Y-%m-%d %H:%M:%S')] Contraseña de root corrompida exitosamente" >> "$LOG"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Laboratorio 4 aplicado correctamente" >> "$LOG"
}

# ==============================================================================
# Ejecución según argumento (para uso remoto)
# ==============================================================================
case "${1:-}" in
    --apply)
        apply_lab
        ;;
    *)
        # Si no hay argumento, no hace nada (seguridad)
        ;;
esac