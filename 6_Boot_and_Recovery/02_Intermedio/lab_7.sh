#!/bin/bash
# ==============================================================================
# RHCSA EX200 – Boot & Recovery
# Lab 7 - Avanzado
# Escenario: Etiquetas SELinux corruptas → login loop
# ==============================================================================

set -uo pipefail

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
    printf "  \033[1;31m- AVC denials en journal\033[0m\n\n"

    printf "\033[1;33mTarea:\033[0m\n"
    printf "  Recuperar usando procedimiento oficial Red Hat.\n\n"

    printf "\033[1;33mPistas:\033[0m\n"
    printf "  • GRUB → rd.break enforcing=1\n"
    printf "  • chroot /sysroot → touch /.autorelabel\n"
    printf "  • Relabel completo\n\n"

    printf "\033[1;36m========================================================\033[0m\n"
}

apply_lab() {
    local LOG="/var/log/lab_boot.log"
    local BACKUP_DIR="/root/lab7_backup"
    local CONTEXT_BACKUP="$BACKUP_DIR/selinux_contexts.bak"

    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB 7: Iniciando inyección"
    } >> "$LOG"

    if [ "$EUID" -ne 0 ]; then
        echo "ERROR: Debe ejecutarse como root" >> "$LOG"
        exit 1
    fi

    # Archivos siempre presentes
    local FILES=(
        /etc/passwd
        /etc/shadow
        /bin/bash
        /usr/bin/passwd
        /lib64/libpam.so.0
    )

    # Añadir /etc/selinux/config solo si existe y es accesible
    if ls -Zd /etc/selinux/config >/dev/null 2>&1; then
        FILES+=(/etc/selinux/config)
    else
        echo "   → /etc/selinux/config no accesible o inexistente, omitido" >> "$LOG"
    fi

    mkdir -p "$BACKUP_DIR"

    # Backup tolerante a errores
    ls -Z "${FILES[@]}" > "$CONTEXT_BACKUP" 2>/dev/null || true

    # Aplicar contexto corrupto
    chcon -t default_t "${FILES[@]}"

    {
        echo "   → Backup contextos: $CONTEXT_BACKUP"
        echo "   → Archivos afectados:"
        for f in "${FILES[@]}"; do echo "     $f → default_t"; done
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB 7: Completado"
        echo "   → Próximo boot: login loop"
    } >> "$LOG"

    echo "Reiniciando para activar laboratorio..."
    sync; sleep 2

    set +e
    systemctl reboot -i --force --no-wall 2>/dev/null || \
    reboot -f 2>/dev/null || \
    shutdown -r now 2>/dev/null
}

case "${1:-}" in
    --apply) apply_lab ;;
    *) show_ticket; read -rp "Presiona ENTER para inyectar y reiniciar... "; apply_lab ;;
esac