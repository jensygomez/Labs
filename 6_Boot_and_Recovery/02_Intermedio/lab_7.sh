#!/bin/bash
# ==============================================================================
# RHCSA EX200 – Boot & Recovery
# Lab 7 – Avanzado
# Escenario: Falla de arranque por contexto SELinux inconsistente
# Requiere recuperación usando rd.break
# ==============================================================================

# ==============================================================================
# Función: Mostrar ticket
# ==============================================================================
show_ticket() {
    clear
    printf "\033[1;36m========================================================\033[0m\n"
    printf "\033[1;36m   RHCSA EX200 – LAB 7 – SELinux Recovery (Avanzado)\033[0m\n"
    printf "\033[1;36m========================================================\033[0m\n\n"

    printf "\033[1;33mEscenario:\033[0m\n"
    printf "  El sistema no completa el arranque después de una\n"
    printf "  modificación administrativa reciente.\n\n"

    printf "\033[1;33mSíntomas:\033[0m\n"
    printf "  \033[1;31m- El sistema se detiene durante el boot\033[0m\n"
    printf "  \033[1;31m- No aparece el login prompt\033[0m\n"
    printf "  \033[1;31m- Se requiere intervención manual\033[0m\n\n"

    printf "\033[1;33mTarea:\033[0m\n"
    printf "  Recuperar el sistema manteniendo SELinux habilitado.\n\n"

    printf "\033[1;33mRestricciones:\033[0m\n"
    printf "  • NO deshabilitar SELinux\n"
    printf "  • NO cambiar a permissive\n"
    printf "  • Usar el método soportado por Red Hat\n\n"

    printf "\033[1;33mPistas:\033[0m\n"
    printf "  • Interrumpe el arranque desde GRUB\n"
    printf "  • Considera rd.break\n"
    printf "  • Trabaja desde initramfs\n\n"

    printf "\033[1;36m========================================================\033[0m\n"
}

# ==============================================================================
# Función: Inyectar laboratorio
# ==============================================================================
apply_lab() {
    local LOG="/var/log/lab_boot.log"
    local BACKUP="/root/grubby.bak.v7"

    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB 7: Iniciando inyección"
        echo "   → Contexto: inconsistencia SELinux tras cambio administrativo"
    } >> "$LOG"

    # Backup completo de GRUB
    {
        grubby --default-kernel
        grubby --info=ALL
    } > "$BACKUP"

    # Obtener kernel activo real (no rescue)
    ACTIVE_KERNEL=$(grubby --default-kernel)

    # Inyectar rd.break SOLO para el próximo arranque
    grubby --update-kernel="$ACTIVE_KERNEL" \
           --args="rd.break enforcing=1"

    {
        echo "   → Kernel afectado:"
        echo "     $ACTIVE_KERNEL"
        echo "   → Parámetro inyectado: rd.break enforcing=1"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB 7: Inyección completada"
        echo "   → Próximo arranque caerá en initramfs (switch_root)"
    } >> "$LOG"

    echo
    echo "El sistema se reiniciará para iniciar el laboratorio..."
    sleep 3

    # Reinicio forzado y robusto
    systemctl reboot --force --no-wall 2>/dev/null || \
    reboot -f 2>/dev/null || \
    shutdown -r now
}

# ==============================================================================
# MAIN
# ==============================================================================
show_ticket
read -rp "Presiona ENTER para inyectar el laboratorio y reiniciar... "
apply_lab
