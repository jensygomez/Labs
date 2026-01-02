#!/bin/bash
# ===========================================================================
# LAB J04 – JUNIOR
# Escenario: Firewall bloquea tráfico legítimo tras cambios de seguridad
# ===========================================================================
set -uo pipefail


# ==============================================================================
# Función 1: Mostrar ticket J04
# ==============================================================================
show_ticket() {
    clear
    printf "\033[1;36m========================================================\033[0m\n"
    printf "\033[1;36m   LAB J04 – JUNIOR – FIREWALL BLOCKS LEGITIMATE TRAFFIC\033[0m\n"
    printf "\033[1;36m========================================================\033[0m\n\n"

    printf "\033[1;33mEscenario:\033[0m\n"
    printf "  En Linux, la seguridad no consiste en bloquearlo todo, sino en permitir\n"
    printf "  exactamente lo necesario. El firewall no es un enemigo del servicio,\n"
    printf "  es su guardián. Tras un ajuste reciente —probablemente bien intencionado—\n"
    printf "  el sistema sigue estable, el servicio está vivo y el puerto escucha.\n"
    printf "  Sin embargo, el acceso ha desaparecido. El firewall, fiel a su diseño,\n"
    printf "  está cumpliendo órdenes con precisión… aunque ya no coincidan con la realidad.\n\n"

    printf "\033[1;33mSíntomas:\033[0m\n"
    printf "  \033[1;31m• El servicio está activo y ejecutándose sin errores.\033[0m\n"
    printf "  \033[1;31m• El puerto correspondiente aparece en estado LISTEN.\033[0m\n"
    printf "  \033[1;31m• El sistema responde a ping y no muestra fallos evidentes.\033[0m\n"
    printf "  \033[1;31m• Las conexiones al servicio son rechazadas o hacen timeout.\033[0m\n\n"

    printf "\033[1;33mTarea:\033[0m\n"
    printf "  Restaurar el equilibrio entre seguridad y operación:\n"
    printf "  - Identificar qué zona protege la interfaz de red\n"
    printf "  - Comprender qué servicios están realmente permitidos\n"
    printf "  - Autorizar solo el tráfico legítimo que el sistema espera\n"
    printf "  La solución correcta no consiste en desactivar el firewall,\n"
    printf "  sino en alinearlo nuevamente con la intención del servicio.\n\n"

    printf "\033[1;33mRestricciones:\033[0m\n"
    printf "  • Prohibido detener o deshabilitar firewalld\n"
    printf "  • Prohibido mover la interfaz a zonas totalmente confiables\n"
    printf "  • Evitar reglas genéricas que rompan el principio de mínimo acceso\n"
    printf "  • Los cambios deben persistir tras reiniciar el sistema\n\n"

    printf "\033[1;33mPistas:\033[0m\n"
    printf "  • El firewall decide en función de zonas, no de suposiciones\n"
    printf "  • Un servicio permitido comunica más intención que un puerto abierto\n"
    printf "  • Revisa qué ve firewalld, no solo lo que escucha el sistema\n"
    printf "  • Cuando la solución es correcta, el firewall no se nota\n\n"

    printf "\033[1;36m========================================================\033[0m\n"
    printf "\nEjecutar con --apply para inyectar el fallo...\n"
}


# ==============================================================================
# Función 2: Aplicar fallo para LAB J04
# ==============================================================================
apply_lab() {
    local LOG="/var/log/lab_j04.log"
    local IFACE
    IFACE=$(ip route | awk '/default/ {print $5; exit}')

    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB J04: Iniciando inyección de fallo"
        echo "Interfaz detectada: $IFACE"
    } >> "$LOG"

    # Validación root
    if [ "$EUID" -ne 0 ]; then
        echo "ERROR: Ejecutar como root" | tee -a "$LOG"
        return 1
    fi

    # ------------------------------------------------------------------
    # 1) Asegurar servicios base
    # ------------------------------------------------------------------
    systemctl enable --now firewalld >> "$LOG" 2>&1
    systemctl enable --now httpd >> "$LOG" 2>&1

    # ------------------------------------------------------------------
    # 2) Forzar zona pública en la interfaz
    # ------------------------------------------------------------------
    firewall-cmd --zone=public --change-interface="$IFACE" >> "$LOG" 2>&1

    # ------------------------------------------------------------------
    # 3) Remover servicio http de la zona pública
    # ------------------------------------------------------------------
    firewall-cmd --zone=public --remove-service=http >> "$LOG" 2>&1
    firewall-cmd --zone=public --remove-service=http --permanent >> "$LOG" 2>&1
    firewall-cmd --reload >> "$LOG" 2>&1

    {
        echo "Servicio http removido de la zona public"
        echo "Estado actual de la zona public:"
        firewall-cmd --zone=public --list-all
        echo "Pruebas sugeridas:"
        echo "  - systemctl status httpd"
        echo "  - ss -tulnp | grep :80"
        echo "  - firewall-cmd --get-active-zones"
        echo "  - curl http://localhost"
    } >> "$LOG"

    echo "Lab J04 inyectado. El servicio funciona, pero el firewall bloquea el acceso."
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
