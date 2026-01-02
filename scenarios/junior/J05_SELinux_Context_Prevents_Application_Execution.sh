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
    printf "\033[1;36m   LAB J05 – JUNIOR – SELINUX CONTEXT BLOCKS EXECUTION\033[0m\n"
    printf "\033[1;36m========================================================\033[0m\n\n"

    printf "\033[1;33mEscenario:\033[0m\n"
    printf "  En Linux, la seguridad no consiste en desactivar controles, sino en\n"
    printf "  permitir exactamente lo que el sistema necesita para operar. SELinux\n"
    printf "  no es un obstáculo para la aplicación, es su guardián. Tras un ajuste\n"
    printf "  reciente —probablemente bien intencionado— el sistema sigue estable,\n"
    printf "  el servicio existe y el binario está presente. Sin embargo, la ejecución\n"
    printf "  falla inmediatamente. SELinux, fiel a su diseño, está aplicando políticas\n"
    printf "  con precisión… aunque ya no reflejen la intención del servicio.\n\n"

    printf "\033[1;33mSíntomas:\033[0m\n"
    printf "  \033[1;31m• El servicio existe y está configurado en systemd.\033[0m\n"
    printf "  \033[1;31m• El binario está presente y tiene permisos de ejecución.\033[0m\n"
    printf "  \033[1;31m• El servicio falla al iniciar o termina inmediatamente.\033[0m\n"
    printf "  \033[1;31m• SELinux se encuentra en modo Enforcing.\033[0m\n\n"

    printf "\033[1;33mTarea:\033[0m\n"
    printf "  Restaurar el equilibrio entre seguridad y operación:\n"
    printf "  - Determinar por qué SELinux impide la ejecución del proceso\n"
    printf "  - Identificar si el contexto del archivo coincide con su función\n"
    printf "  - Corregir el problema alineando el contexto con la intención del servicio\n"
    printf "  La solución correcta no consiste en desactivar SELinux,\n"
    printf "  sino en enseñarle qué debe permitirse.\n\n"

    printf "\033[1;33mRestricciones:\033[0m\n"
    printf "  • Prohibido desactivar SELinux o usar setenforce 0\n"
    printf "  • Prohibido aplicar permisos excesivos como solución\n"
    printf "  • Evitar cambios genéricos que rompan el principio de mínimo privilegio\n"
    printf "  • Los cambios deben persistir tras reiniciar el sistema\n\n"

    printf "\033[1;33mPistas:\033[0m\n"
    printf "  • systemd ejecuta procesos bajo políticas, no suposiciones\n"
    printf "  • SELinux decide antes de que el binario comience a ejecutarse\n"
    printf "  • El shell puede ocultar errores que el journal revela\n"
    printf "  • Cuando la solución es correcta, SELinux deja de ser visible\n\n"

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
