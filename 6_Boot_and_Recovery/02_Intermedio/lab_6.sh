#!/bin/bash
# ==============================================================================
# LABORATORIO 6 – RHCSA EX200 – Boot & Recovery (Intermedio)
# Scenario: Kernel defectuoso tras actualización
# ==============================================================================

set -uo pipefail

# ==============================================================================
# Función 1: Mostrar ticket (HOST)
# ==============================================================================
show_ticket() {
    clear
    printf "\033[1;36m==================================================\033[0m\n"
    printf "\033[1;36m     LABORATORIO 6 – FALLA DE ARRANQUE POR KERNEL\033[0m\n"
    printf "\033[1;36m==================================================\033[0m\n\n"

    printf "\033[1;33mContexto:\033[0m\n"
    printf "  Durante una actualización del sistema se instaló\n"
    printf "  un kernel nuevo. Posteriormente se aplicaron cambios\n"
    printf "  automáticos (Ansible / tuning) sobre los parámetros\n"
    printf "  de arranque.\n\n"

    printf "\033[1;33mProblema:\033[0m\n"
    printf "  El kernel más reciente no logra montar el root filesystem\n"
    printf "  debido a un parámetro rd.lvm.lv incorrecto.\n\n"

    printf "\033[1;33mSíntomas:\033[0m\n"
    printf "  \033[1;31m- El sistema no completa el arranque\033[0m\n"
    printf "  \033[1;31m- dracut-initqueue timeout\033[0m\n"
    printf "  \033[1;31m- Emergency mode / dracut shell\033[0m\n\n"

    printf "\033[1;33mTarea:\033[0m\n"
    printf "  Recuperar el sistema arrancando con un kernel funcional\n"
    printf "  o corrigiendo los parámetros de arranque.\n\n"

    printf "\033[1;33mPistas útiles:\033[0m\n"
    printf "  • En GRUB: presiona 'e'\n"
    printf "  • Revisa rd.lvm.lv y root=\n"
    printf "  • Corrige o elimina el parámetro incorrecto\n"
    printf "  • Arranca con Ctrl+X\n"
    printf "  • Persiste el cambio tras recuperar el sistema\n\n"

    printf "\033[1;36m==================================================\033[0m\n"
    printf "\nEl sistema se reiniciará para aplicar el laboratorio...\n"
}

# ==============================================================================
# Función 2: Aplicar laboratorio en la VM
# ==============================================================================
apply_lab() {
    local LOG="/var/log/lab_boot.log"
    local BACKUP="/root/grubby.bak.v6"

    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB 6: Iniciando inyección"
        echo "   → Contexto: kernel reciente defectuoso tras actualización"
    } >> "$LOG"

    # Obtener kernels reales (excluyendo rescue)
    mapfile -t KERNELS < <(
        grubby --info=ALL | awk -F= '/^kernel=/{print $2}' | grep -v rescue
    )

    if [ "${#KERNELS[@]}" -lt 2 ]; then
        echo "ERROR: Se requieren al menos dos kernels instalados" >> "$LOG"
        exit 1
    fi

    local BAD_KERNEL="${KERNELS[0]}"
    local GOOD_KERNEL="${KERNELS[1]}"

    # Backup completo
    {
        grubby --default-kernel
        grubby --info=ALL
    } > "$BACKUP"

    # Inyectar parámetro inválido SOLO en el kernel más reciente
    grubby --update-kernel="$BAD_KERNEL" \
           --args="rd.lvm.lv=rhel/roooot" \
           --remove-args="rd.lvm.lv=rhel/root"

    # Forzar kernel defectuoso como default
    grubby --set-default "$BAD_KERNEL"

    {
        echo "   → Kernel defectuoso:"
        echo "     $BAD_KERNEL"
        echo "   → Kernel funcional disponible:"
        echo "     $GOOD_KERNEL"
        echo "   → Parámetro inválido inyectado: rd.lvm.lv=rhel/roooot"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB 6: Inyección completada"
        echo "   → Próximo arranque caerá en dracut"
    } >> "$LOG"

# ==============================================================================
# REINICIO FORZADO (ROBUSTO)
# ==============================================================================
echo
echo "Reiniciando el sistema para activar el laboratorio..."

set +e

systemctl reboot --force --no-wall 2>/dev/null || \
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
        ;;
esac
