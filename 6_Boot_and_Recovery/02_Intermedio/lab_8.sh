#!/bin/bash
# ==============================================================================
# RHCSA EX200 – Boot & Recovery
# Lab 8 - Avanzado SUPERIOR
# Escenario: Initramfs corrupto + GRUB env malo + Tuned conflictivo → Kernel panic
# ==============================================================================

set -uo pipefail

# ==============================================================================
# Función 1: Mostrar ticket
# ==============================================================================
show_ticket() {
    clear
    printf "\033[1;36m========================================================\033[0m\n"
    printf "\033[1;36m   RHCSA EX200 – LAB 8 – BOOT MULTIFALLO (AVANZADO+)\033[0m\n"
    printf "\033[1;36m========================================================\033[0m\n\n"

    printf "\033[1;33mEscenario:\033[0m\n"
    printf "  Post-actualización kernel fallida: initramfs corrupto + GRUB env malo\n"
    printf "  + tuned profile conflictivo bloqueando servicios críticos.\n\n"

    printf "\033[1;33mSíntomas:\033[0m\n"
    printf "  \033[1;31m- Kernel panic o emergency mode en boot\033[0m\n"
    printf "  \033[1;31m- journalctl -k muestra initramfs errors\033[0m\n"
    printf "  \033[1;31m- tuned denials bloquean httpd/network post-boot\033[0m\n"
    printf "  \033[1;31m- GRUB env fuerza kernel fallido\033[0m\n\n"

    printf "\033[1;33mTarea:\033[0m\n"
    printf "  Recovery completo: dracut rebuild + tuned fix + GRUB env clean.\n\n"

    printf "\033[1;33mRestricciones:\033[0m\n"
    printf "  • NO mkinitrd (usa dracut oficial)\n"
    printf "  • NO tuned off (cambia profile)\n"
    printf "  • Persistir fixes post-reboot\n\n"

    printf "\033[1;33mPistas:\033[0m\n"
    printf "  • GRUB → e → rd.break → Ctrl+X\n"
    printf "  • chroot /sysroot\n"
    printf "  • dracut -f /boot/initramfs-5.14.0-611.16.1.el9_7.x86_64.img 5.14...\n"
    printf "  • tuned-adm profile throughput-performance\n"
    printf "  • grub2-editenv unset kernel_failed\n"
    printf "  • grub2-mkconfig -o /boot/grub2/grub.cfg\n\n"

    printf "\033[1;36m========================================================\033[0m\n"
    printf "\nEl sistema se reiniciará para activar el MULTIFALLO...\n"
}

# ==============================================================================
# Función 2: Aplicar laboratorio
# ==============================================================================
apply_lab() {
    local LOG="/var/log/lab_boot.log"
    local KERNEL="5.14.0-611.16.1.el9_7.x86_64"
    local INITRAMFS="/boot/initramfs-${KERNEL}.img"
    local BACKUP="/root/boot_lab8.bak"
    local GRUBENV="/boot/grub2/grubenv"

    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB 8: Iniciando MULTIFALLO"
        echo "   → Kernel: $KERNEL"
    } >> "$LOG"

    # Validación root
    if [ "$EUID" -ne 0 ]; then
        echo "ERROR: Ejecutar como root" >> "$LOG"
        exit 1
    fi

    # Instala tuned si falta
    if ! rpm -q tuned >/dev/null 2>&1; then
        dnf install -y tuned >/dev/null 2>&1
        systemctl enable --now tuned >/dev/null 2>&1
    fi

    # Backup
    cp -r /boot "$BACKUP"
    cp "$GRUBENV" "${BACKUP}/grubenv.bak" 2>/dev/null || true

    # 1. CORROMPE INITRAMFS
    truncate -s 100K "$INITRAMFS"
    
    # 2. GRUB ENV malo
    grub2-editenv "$GRUBENV" set kernel_failed=1 2>/dev/null || true
    
    # 3. TUNED conflictivo
    tuned-adm profile virtual-guest 2>/dev/null || true

    {
        echo "   → Initramfs truncado: $INITRAMFS ($(ls -lh "$INITRAMFS" 2>/dev/null))"
        echo "   → GRUB env: kernel_failed=1 ($(grub2-editenv list "$GRUBENV" 2>/dev/null))"
        echo "   → Tuned: $(tuned-adm active 2>/dev/null)"
        echo "   → Backup: $BACKUP"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB 8: MULTIFALLO COMPLETADO"
        echo "   → Reboot: kernel panic + tuned denials"
    } >> "$LOG"

    echo "MULTIFALLO inyectado. Reiniciando..."
    sync; sleep 2
    set +e
    systemctl reboot -i --force --no-wall 2>/dev/null || reboot -f 2>/dev/null || shutdown -r now 2>/dev/null
    sleep 5
}

# ==============================================================================
# Ejecución
# ==============================================================================
case "${1:-}" in
    --apply)
        apply_lab
        ;;
    *)
        show_ticket
        ;;
esac
