#!/bin/bash
# ==============================================================================
# Laboratorio 5 - RHCSA Boot & Recovery
# Scenario: Parámetro de kernel incorrecto en GRUB
# ==============================================================================

set -euo pipefail

# ==============================================================================
# Función 1: Mostrar ticket (HOST)
# ==============================================================================
show_ticket() {
    clear
    printf "\033[1;36m==================================================\033[0m\n"
    printf "\033[1;36m     LABORATORIO 5 – FALLA DE ARRANQUE (GRUB)\033[0m\n"
    printf "\033[1;36m==================================================\033[0m\n\n"

    printf "\033[1;33mEscenario:\033[0m\n"
    printf "  Se realizaron cambios en la configuración de GRUB\n"
    printf "  y ahora el sistema no logra montar el root filesystem.\n\n"

    printf "\033[1;33mSíntomas:\033[0m\n"
    printf "  \033[1;31m- El sistema no arranca normalmente\033[0m\n"
    printf "  \033[1;31m- Error de root filesystem durante boot\033[0m\n"
    printf "  \033[1;31m- Emergency shell (dracut)\033[0m\n\n"

    printf "\033[1;33mTarea:\033[0m\n"
    printf "  Recuperar el arranque corrigiendo los parámetros de kernel en GRUB.\n\n"

    printf "\033[1;33mPistas útiles:\033[0m\n"
    printf "  • En GRUB: presiona 'e'\n"
    printf "  • Revisa parámetros rd.lvm.lv / root=\n"
    printf "  • Corrige el valor incorrecto\n"
    printf "  • Arranca con Ctrl+X\n"
    printf "  • Persiste el cambio si es necesario\n\n"

    printf "\033[1;36m==================================================\033[0m\n"
}

# ==============================================================================
# Función 2: Inyección del laboratorio (VM)
# ==============================================================================
apply_lab() {
    local LOG="/var/log/lab_boot.log"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB_V5: Iniciando inyección" >> "$LOG"

    # Backup defensivo
    cp /etc/default/grub /etc/default/grub.bak.lab5

    # Corromper parámetro rd.lvm.lv
    sed -i 's/rd.lvm.lv=\([^ ]*\/\)root/rd.lvm.lv=\1rooot/' /etc/default/grub

    # Regenerar grub.cfg
    grub2-mkconfig -o /boot/grub2/grub.cfg &>> "$LOG"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB_V5: Parámetro rd.lvm.lv corrompido" >> "$LOG"
    echo "   → El sistema no podrá montar root filesystem" >> "$LOG"
}

# ==============================================================================
# Ejecución
# ==============================================================================
case "${1:-}" in
    --apply)
        apply_lab
        ;;
    *)
        ;;
esac
