#!/bin/bash
# ==============================================================================
# RHCSA EX200 – Boot & Recovery
# Lab 5 - Intermediario
# Scenario: Parámetro de kernel incorrecto en GRUB
# ==============================================================================

set -euo pipefail

# ==============================================================================
# Función 1: Mostrar ticket (HOST)
# ==============================================================================
# ==============================================================================
# Función 1: Mostrar ticket (HOST)
# ==============================================================================
show_ticket() {
    clear
    printf "\033[1;36m==================================================\033[0m\n"
    printf "\033[1;36m   LABORATORIO 5 – FALLA DE ARRANQUE (ROOT FS)\033[0m\n"
    printf "\033[1;36m==================================================\033[0m\n\n"

    printf "\033[1;33mContexto:\033[0m\n"
    printf "  Durante una automatización reciente, se aplicaron cambios\n"
    printf "  incorrectos en los parámetros de arranque del sistema.\n"
    printf "  El servidor utiliza LVM para el filesystem raíz.\n\n"

    printf "\033[1;33mSíntomas:\033[0m\n"
    printf "  \033[1;31m- El sistema no completa el proceso de arranque\033[0m\n"
    printf "  \033[1;31m- Error relacionado con el root filesystem durante initramfs\033[0m\n"
    printf "  \033[1;31m- Acceso a shell de emergencia (dracut)\033[0m\n\n"

    printf "\033[1;33mObjetivo:\033[0m\n"
    printf "  Recuperar el arranque del sistema asegurando que el\n"
    printf "  filesystem raíz sea localizado correctamente.\n\n"

    printf "\033[1;33mPistas útiles:\033[0m\n"
    printf "  • Analiza los mensajes mostrados durante el arranque\n"
    printf "  • Verifica cómo se identifica el volumen lógico raíz\n"
    printf "  • Activa LVM manualmente si es necesario\n"
    printf "  • Corrige la causa raíz del problema de forma persistente\n\n"

    printf "\033[1;36m==================================================\033[0m\n"
}


# ==============================================================================
# Función 2: Inyección del laboratorio (VM)
# ==============================================================================


apply_lab() {
    local LOG="/var/log/lab_boot.log"
    local BACKUP="/root/grubby.bak.v5"

    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Laboratorio 5: iniciando inyección"
        echo "   → Contexto: error en automatización (kernel args)"
        echo "   → Acción: rompiendo parámetro rd.lvm.lv del root filesystem"
    } >> "$LOG"

    # Backup del estado actual de grubby
    grubby --info=ALL > "$BACKUP"

    # Verificar que el argumento correcto exista antes de modificar
    if grubby --info=ALL | grep -q "rd.lvm.lv=rhel/root"; then
        grubby --update-kernel=ALL \
            --args="rd.lvm.lv=rhel/roooot" \
            --remove-args="rd.lvm.lv=rhel/root"
    else
        {
            echo "   → ERROR: rd.lvm.lv=rhel/root no encontrado"
            echo "   → Inyección abortada"
        } >> "$LOG"
        exit 1
    fi

    # Verificación post-inyección
    grubby --info=ALL | grep args >> "$LOG"

    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Laboratorio 5: inyección completada"
        echo "   → Root LV inválido configurado"
        echo "   → Próximo boot fallará en dracut"
    } >> "$LOG"
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
