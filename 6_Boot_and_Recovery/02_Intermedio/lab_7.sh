#!/bin/bash
# ==============================================================================
# RHCSA EX200 – Boot & Recovery
# Lab 7 - Avanzado
# Escenario: Etiquetas SELinux corruptas → login loop
# ==============================================================================

set -uo pipefail

# ==============================================================================
# Función 1: Mostrar ticket
# ==============================================================================
show_ticket() {
    clear
    printf "\033[1;36m========================================================\033[0m\n"
    printf "\033[1;36m   RHCSA EX200 – LAB 7 – SELINUX RECOVERY (AVANZADO)\033[0m\n"
    printf "\033[1;36m========================================================\033[0m\n\n"

    printf "\033[1;33mEscenario:\033[0m\n"
    printf "  Tras una restauración de backup o copia sin preservar xattrs,\n"
    printf "  las etiquetas SELinux de archivos críticos están corruptas.\n\n"

    printf "\033[1;33mSíntomas:\033[0m\n"
    printf "  \033[1;31m- Boot llega a pantalla de login\033[0m\n"
    printf "  \033[1;31m- Login loop (no acepta credenciales válidas)\033[0m\n"
    printf "  \033[1;31m- Muchos AVC denials en journal\033[0m\n\n"

    printf "\033[1;33mTarea:\033[0m\n"
    printf "  Recuperar usando procedimiento oficial Red Hat (rd.break + .autorelabel).\n\n"

    printf "\033[1;33mRestricciones:\033[0m\n"
    printf "  • NO desactivar SELinux permanentemente\n"
    printf "  • NO usar enforcing=0\n\n"

    printf "\033[1;33mPistas:\033[0m\n"
    printf "  • GRUB → e → rd.break enforcing=1 → Ctrl+X\n"
    printf "  • mount -o remount,rw /sysroot\n"
    printf "  • chroot /sysroot\n"
    printf "  • touch /.autorelabel\n"
    printf "  • exit; exit\n\n"

    printf "\033[1;36m========================================================\033[0m\n"
    printf "\nEl sistema se reiniciará para aplicar el laboratorio...\n"
}

# ==============================================================================
# Función 2: Aplicar laboratorio
# ==============================================================================
apply_lab() {
    local LOG="/var/log/lab_boot.log"
    local BACKUP="/root/selinux_contexts.bak.v7"

    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB 7: Iniciando inyección"
        echo "   → Escenario: etiquetas SELinux corruptas"
    } >> "$LOG"

    # Validación root (igual que V6)
    if [ "$EUID" -ne 0 ]; then
        echo "ERROR: Este laboratorio debe ejecutarse como root" >> "$LOG"
        exit 1
    fi

    # Archivos críticos (siempre existen)
    local FILES=(
        /etc/passwd
        /etc/shadow
        /bin/bash
        /usr/bin/passwd
        /lib64/libpam.so.0
    )

    # Añadir /etc/selinux/config si existe y es accesible
    if [ -f /etc/selinux/config ] && ls -Z /etc/selinux/config >/dev/null 2>&1; then
        FILES+=(/etc/selinux/config)
    fi

    # Backup completo de contextos (igual que V6)
    {
        echo "=== CONTEXTOS ORIGINALES ANTES DE INYECCIÓN ==="
        ls -Z "${FILES[@]}"
        echo
    } > "$BACKUP"

    # Inyección: corromper contextos
    /usr/bin/chcon -t default_t "${FILES[@]}"  # ruta absoluta para evitar problemas de PATH

    {
        echo "   → Backup guardado en: $BACKUP"
        echo "   → Archivos corruptos (default_t):"
        for f in "${FILES[@]}"; do echo "     $f"; done
        echo "   → Verificación post-inyección:"
        ls -Z "${FILES[@]}"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB 7: Inyección completada"
        echo "   → Próximo arranque: login loop por SELinux"
    } >> "$LOG"

    echo
    echo "Reiniciando el sistema para activar el laboratorio..."

    sync
    sleep 2

    # Reinicio robusto idéntico al V6
    set +e
    systemctl reboot -i --force --no-wall 2>/dev/null || \
    reboot -f 2>/dev/null || \
    shutdown -r now 2>/dev/null

    sleep 5
}

# ==============================================================================
# Ejecución (idéntica al V6)
# ==============================================================================
case "${1:-}" in
    --apply)
        apply_lab
        ;;
    *)
        show_ticket
        ;;
esac