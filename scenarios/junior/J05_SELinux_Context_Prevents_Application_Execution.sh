#!/bin/bash
# ===========================================================================
# LAB J05 – JUNIOR
# Escenario: Servicio no inicia por bloqueo de SELinux
# ===========================================================================
set -uo pipefail


# ==============================================================================
# Función 1: Mostrar ticket J05
# ==============================================================================
show_ticket() {
    clear
    printf "\033[1;36m========================================================\033[0m\n"
    printf "\033[1;36m   LAB J05 – JUNIOR – APPLICATION FAILS TO START\033[0m\n"
    printf "\033[1;36m========================================================\033[0m\n\n"

    printf "\033[1;33mEscenario:\033[0m\n"
    printf "  En Linux, la seguridad no consiste en desactivar controles, sino en\n"
    printf "  permitir exactamente lo que el sistema necesita para operar.\n"
    printf "  Tras un ajuste reciente —probablemente bien intencionado—\n"
    printf "  el sistema sigue estable. El servicio existe, el binario está presente\n"
    printf "  y los permisos parecen correctos. Sin embargo, la aplicación\n"
    printf "  falla inmediatamente al intentar iniciarse.\n\n"
    printf "  No hay reinicios del sistema, no hay errores visibles en el shell\n"
    printf "  y el servicio parece correctamente definido.\n"
    printf "  Aun así, la ejecución no ocurre.\n\n"

    printf "\033[1;33mSíntomas:\033[0m\n"
    printf "  \033[1;31m• El servicio está definido y gestionado por systemd.\033[0m\n"
    printf "  \033[1;31m• El binario existe y tiene permisos de ejecución.\033[0m\n"
    printf "  \033[1;31m• El servicio falla al iniciar o termina inmediatamente.\033[0m\n"
    printf "  \033[1;31m• No se observan errores claros al ejecutar el binario manualmente.\033[0m\n"
    printf "  \033[1;31m• El sistema opera con sus mecanismos de seguridad habilitados.\033[0m\n\n"

    printf "\033[1;33mTarea:\033[0m\n"
    printf "  Restaurar el equilibrio entre seguridad y operación:\n"
    printf "  - Identificar por qué el proceso no llega a ejecutarse\n"
    printf "  - Determinar si el sistema permite la ejecución del binario\n"
    printf "  - Corregir el problema alineando la intención del servicio\n"
    printf "    con las políticas activas del sistema\n\n"
    printf "  La solución correcta no consiste en desactivar mecanismos\n"
    printf "  de seguridad, sino en comprenderlos y ajustarlos correctamente.\n\n"

    printf "\033[1;33mRestricciones:\033[0m\n"
    printf "  • Prohibido desactivar mecanismos de seguridad del sistema\n"
    printf "  • Prohibido aplicar permisos excesivos como solución\n"
    printf "  • Evitar cambios genéricos que rompan el principio de mínimo privilegio\n"
    printf "  • Los cambios deben persistir tras reiniciar el sistema\n\n"

    printf "\033[1;33mPistas:\033[0m\n"
    printf "  • systemd ejecuta procesos bajo políticas, no suposiciones\n"
    printf "  • El sistema puede bloquear la ejecución antes de que comience\n"
    printf "  • El shell no siempre refleja los errores reales\n"
    printf "  • El journal suele saber más de lo que muestra la consola\n"
    printf "  • Cuando la solución es correcta, la seguridad deja de ser visible\n\n"

    printf "\033[1;36m========================================================\033[0m\n"
    printf "\nEjecutar con --apply para inyectar el fallo...\n"
}



# ==============================================================================
# Función 2: Aplicar fallo para LAB J05
# ==============================================================================
apply_lab() {
    local LOG="/var/log/lab_j05.log"
    local APP_DIR="/opt/acme/bin"
    local APP="$APP_DIR/acme-app.sh"
    local SERVICE="/etc/systemd/system/acme-app.service"

    # Validación root
    if [ "$EUID" -ne 0 ]; then
        echo "ERROR: Ejecutar como root" | tee -a "$LOG"
        return 1
    fi

    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB J05: Iniciando inyección de fallo"
    } >> "$LOG"

    # ------------------------------------------------------------------
    # 1) Crear aplicación
    # ------------------------------------------------------------------
    mkdir -p "$APP_DIR"

    cat << 'EOF' > "$APP"
#!/bin/bash
echo "ACME application running" >> /var/log/acme-app.log
sleep infinity
EOF

    chmod 755 "$APP"

    # ------------------------------------------------------------------
    # 2) Crear servicio systemd
    # ------------------------------------------------------------------
    cat << EOF > "$SERVICE"
[Unit]
Description=ACME Internal Application
After=network.target

[Service]
ExecStart=$APP
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reexec
    systemctl enable acme-app >> "$LOG" 2>&1

    # ------------------------------------------------------------------
    # 3) Inyectar fallo SELinux (contexto incorrecto)
    # ------------------------------------------------------------------
    chcon -t default_t "$APP" >> "$LOG" 2>&1

    # ------------------------------------------------------------------
    # 4) Intentar iniciar servicio (fallará)
    # ------------------------------------------------------------------
    systemctl restart acme-app >> "$LOG" 2>&1 || true

    {
        echo "Contexto actual del binario:"
        ls -Z "$APP"
        echo "Estado del servicio:"
        systemctl status acme-app
        echo "Pruebas sugeridas:"
        echo "  - getenforce"
        echo "  - journalctl -xeu acme-app"
        echo "  - ls -Z /opt/acme/bin/acme-app.sh"
        echo "  - restorecon -v /opt/acme/bin/acme-app.sh"
    } >> "$LOG"

    echo "Lab J05 inyectado. El servicio existe, pero SELinux impide su ejecución."
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
