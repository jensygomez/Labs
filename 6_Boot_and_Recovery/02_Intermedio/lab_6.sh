#!/bin/bash
# ==============================================================================
# Laboratorio 6 - RHCSA Boot & Recovery (Nivel Intermedio)
# Scenario: Kernel por defecto no funcional tras actualización
# ==============================================================================

set -euo pipefail

# ==============================================================================
# Función 1: Mostrar ticket (HOST)
# ==============================================================================
show_ticket() {
    clear
    printf "\033[1;36m==================================================\033[0m\n"
    printf "\033[1;36m   LABORATORIO 6 – FALLA TRAS ACTUALIZACIÓN\033[0m\n"
    printf "\033[1;36m==================================================\033[0m\n\n"

    printf "\033[1;33mContexto:\033[0m\n"
    printf "  El servidor recibió una actualización automática del sistema.\n"
    printf "  Tras reiniciar, el arranque dejó de completarse correctamente.\n"
    printf "  No se reportaron cambios manuales recientes.\n\n"

    printf "\033[1;33mSíntomas:\033[0m\n"
    printf "  \033[1;31m- El sistema no arranca con normalidad\033[0m\n"
    printf "  \033[1;31m- El fallo ocurre poco después de iniciar el kernel\033[0m\n"
    printf "  \033[1;31m- No hay acceso al sistema operativo\033[0m\n\n"

    printf "\033[1;33mObjetivo:\033[0m\n"
    printf "  Recuperar el sistema para que arranque correctamente\n"
    printf "  y asegurar un arranque estable en reinicios futuros.\n\n"

    printf "\033[1;33mPistas útiles:\033[0m\n"
    printf "  • Revisa las opciones disponibles en el menú de arranque\n"
    printf "  • Considera el impacto de actualizaciones recientes\n"
    printf "  • El sistema podría tener alternativas funcionales instaladas\n\n"

    printf "\033[1;36m==================================================\033[0m\n"
}

# ==============================================================================
# Función 2: Aplicar laboratorio en la VM (inyección)
# ==============================================================================
apply_lab() {
    local LOG="/var/log/lab_boot.log"
    local BACKUP="/root/grubby.bak.v6"

    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Laboratorio 6: iniciando inyección"
        echo "   → Contexto: kernel reciente defectuoso tras actualización"
    } >> "$LOG"

    # Obtener lista de kernels
    mapfile -t KERNELS < <(grubby --info=ALL | awk -F= '/^kernel=/{print $2}')

    if [ "${#KERNELS[@]}" -lt 2 ]; then
        echo "ERROR: Se requieren al menos dos kernels instalados" >> "$LOG"
        exit 1
    fi

    # Asumimos:
    # KERNELS[0] = kernel más reciente (defectuoso)
    # KERNELS[1] = kernel anterior (funcional)
    local BAD_KERNEL="${KERNELS[0]}"
    local GOOD_KERNEL="${KERNELS[1]}"

    # Backup del estado actual
    grubby --default-kernel > "$BACKUP"
    grubby --info=ALL >> "$BACKUP"

    # Forzar kernel defectuoso como default
    grubby --set-default "$BAD_KERNEL"

    {
        echo "   → Kernel defectuoso establecido como default:"
        echo "     $BAD_KERNEL"
        echo "   → Kernel funcional disponible:"
        echo "     $GOOD_KERNEL"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Inyección completada"
        echo "   → Próximo boot fallará"
    } >> "$LOG"
}

# ==============================================================================
# Ejecución según argumento
# ==============================================================================
case "${1:-}" in
    --ticket)
        show_ticket
        ;;
    --apply)
        apply_lab
        ;;
    *)
        ;;
esac
