#!/bin/bash
# ==============================================================================
# RHCSA EX200 – Boot & Recovery
# Lab 7 - Avanzado
# Escenario: Etiquetas SELinux corruptas → falla de autenticación (login loop)
# ==============================================================================

set -uo pipefail

# ==============================================================================
# Función 1: Mostrar ticket (HOST)
# ==============================================================================
show_ticket() {
    clear
    printf "\033[1;36m========================================================\033[0m\n"
    printf "\033[1;36m   RHCSA EX200 – LAB 7 – SELINUX RECOVERY (AVANZADO)\033[0m\n"
    printf "\033[1;36m========================================================\033[0m\n\n"

    printf "\033[1;33mEscenario:\033[0m\n"
    printf "  Tras una restauración de backup o copia de archivos sin preservar\n"
    printf "  atributos extendidos, las etiquetas SELinux de archivos críticos\n"
    printf "  se han corrompido.\n\n"

    printf "\033[1;33mSíntomas:\033[0m\n"
    printf "  \033[1;31m- El sistema arranca hasta la pantalla de login\033[0m\n"
    printf "  \033[1;31m- Login loop: no acepta credenciales válidas\033[0m\n"
    printf "  \033[1;31m- Muchos AVC denials en el journal\033[0m\n\n"

    printf "\033[1;33mTarea:\033[0m\n"
    printf "  Recuperar el sistema manteniendo SELinux habilitado.\n\n"

    printf "\033[1;33mRestricciones:\033[0m\n"
    printf "  • NO desactivar SELinux permanentemente\n"
    printf "  • NO usar enforcing=0 ni SELINUX=disabled\n"
    printf "  • Usar el procedimiento oficial de Red Hat\033[0m\n\n"

    printf "\033[1;33mPistas:\033[0m\n"
    printf "  • Edita GRUB → rd.break enforcing=1\n"
    printf "  • Crea /.autorelabel desde initramfs\n"
    printf "  • Permite relabel completo\n\n"

    printf "\033[1;36m========================================================\033[0m\n"
}

# ==============================================================================
# Función 2: Aplicar laboratorio
# ==============================================================================
apply_lab() {
    local LOG="/var/log/lab_boot.log"
    local BACKUP_DIR="/root/lab7_backup"
    local CONTEXT_BACKUP="$BACKUP_DIR/selinux_contexts.bak"

    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB 7: Iniciando inyección"
        echo "   → Escenario: etiquetas SELinux corruptas en archivos críticos"
    } >> "$LOG"

    # Validación root
    if [ "$EUID" -ne 0 ]; then
        echo "ERROR: Ejecutar como root" >> "$LOG"
        exit 1
    fi

    # Archivos críticos a corromper
    local FILES=(
        /etc/passwd
        /etc/shadow
        /etc/selinux/config
        /bin/bash
        /usr/bin/passwd
        /lib64/libpam.so.0
    )

    # Crear backup
    mkdir -p "$BACKUP_DIR"
    ls -Z "${FILES[@]}" > "$CONTEXT_BACKUP"

    # Inyección: cambiar a tipo incorrecto
    chcon -t default_t "${FILES[@]}"

    {
        echo "   → Contextos originales guardados en: $CONTEXT_BACKUP"
        echo "   → Archivos corruptos:"
        for f in "${FILES[@]}"; do echo "     $f → default_t"; done
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB 7: Inyección completada"
        echo "   → Próximo arranque: login loop por denegaciones SELinux"
    } >> "$LOG"

    echo
    echo "Reiniciando el sistema para activar el laboratorio..."
    sync
    sleep 2

    # Reinicio robusto (igual que V6)
    set +e
    systemctl reboot -i --force --no-wall 2>/dev/null || \
    reboot -f 2>/dev/null || \
    shutdown -r now 2>/dev/null

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
        read -rp "Presiona ENTER para inyectar el laboratorio y reiniciar... "
        apply_lab
        ;;
esac