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
    printf "\033[1;36m==================================================\033[0m\n"
    printf "\033[1;36m     LABORATORIO 4 – CONTRASEÑA DE ROOT OLVIDADA\033[0m\n"
    printf "\033[1;36m==================================================\033[0m\n\n"

    printf "\033[1;33mEscenario:\033[0m\n"
    printf "  Un compañero cambió la contraseña de root hace semanas\n"
    printf "  y nadie la recuerda. El acceso sudo también falla.\n\n"

    printf "\033[1;33mSíntomas:\033[0m\n"
    printf "  \033[1;31m- Login como root: denegado\033[0m\n"
    printf "  \033[1;31m- sudo: Authentication failure\033[0m\n"
    printf "  \033[1;31m- Sistema arranca normal hasta login\033[0m\n\n"

    printf "\033[1;33mTarea:\033[0m\n"
    printf "  Recuperar acceso root usando rd.break en GRUB.\n\n"

    printf "\033[1;33mPistas útiles:\033[0m\n"
    printf "  • En GRUB: edita línea → añade rd.break → Ctrl+X\n"
    printf "  • mount -o remount,rw /sysroot\n"
    printf "  • chroot /sysroot\n"
    printf "  • passwd\n"
    printf "  • touch /.autorelabel (si SELinux enabled)\n"
    printf "  • exit → exit → reboot\n\n"

    printf "\033[1;36m==================================================\033[0m\n"
}

# ==============================================================================
# Función 2: Aplicar el laboratorio en la VM (silencioso + log)
# ==============================================================================
apply_lab() {
    local LOG="/var/log/lab_boot.log"
    local BAD_PASS="bad_$(openssl rand -hex 16)"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Laboratorio 4: iniciando" >> "$LOG"
    echo "root:$BAD_PASS" | chpasswd
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Laboratorio 4: contraseña root corrompida" >> "$LOG"
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