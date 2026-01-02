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
    printf "\033[1;36m   LAB J05 – JUNIOR – SERVICE BLOCKED BY SELINUX\033[0m\n"
    printf "\033[1;36m========================================================\033[0m\n\n"

    printf "\033[1;33mEscenario:\033[0m\n"
    printf "  El servicio fue desplegado correctamente y el binario existe.\n"
    printf "  Los permisos son correctos, systemd reconoce la unidad y el\n"
    printf "  administrador anterior asegura que 'todo funcionaba ayer'.\n"
    printf "  Sin embargo, el servicio ahora falla inmediatamente al iniciar.\n"
    printf "  No hay mensajes claros en pantalla y reiniciarlo no cambia nada.\n"
    printf "  El sistema está en modo enforcing y la seguridad no ha sido desactivada.\n\n"

    printf "\033[1;33mSíntomas:\033[0m\n"
    printf "  \033[1;31m• systemctl start falla de forma inmediata.\033[0m\n"
    printf "  \033[1;31m• El binario existe y tiene permisos de ejecución.\033[0m\n"
    printf "  \033[1;31m• Ejecutado manualmente, el script parece funcionar.\033[0m\n"
    printf "  \033[1;31m• No hay errores evidentes en el código.\033[0m\n\n"

    printf "\033[1;33mTarea:\033[0m\n"
    printf "  Restaurar la capacidad de ejecución del servicio sin comprometer\n"
    printf "  la política de seguridad del sistema:\n"
    printf "  - Identificar por qué systemd no puede ejecutar el binario\n"
    printf "  - Validar el estado real de SELinux\n"
    printf "  - Corregir el problema de forma persistente\n"
    printf "  La solución correcta no implica desactivar SELinux.\n\n"

    printf "\033[1;33mRestricciones:\033[0m\n"
    printf "  • Prohibido desactivar SELinux (setenforce 0)\n"
    printf "  • Prohibido modificar el código del script\n"
    printf "  • No reinstalar el servicio\n"
    printf "  • La corrección debe sobrevivir reinicios\n\n"

    printf "\033[1;33mPistas:\033[0m\n"
    printf "  • systemd ejecuta binarios bajo políticas estrictas\n"
    printf "  • Un permiso POSIX correcto no garantiza ejecución\n"
    printf "  • SELinux decide antes que el kernel ejecute el binario\n"
    printf "  • journalctl ve cosas que systemctl no muestra\n\n"

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
