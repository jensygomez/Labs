#!/bin/bash
# ===========================================================================
# LAB J03 – JUNIOR
# Escenario: Servicio no arranca tras reboot (systemd condition)
# ===========================================================================
set -uo pipefail


# ==============================================================================
# Función 1: Mostrar ticket J03
# ==============================================================================
show_ticket() {
    clear
    printf "\033[1;36m========================================================\033[0m\n"
    printf "\033[1;36m   LAB J03 – JUNIOR – SERVICE SKIPPED AFTER REBOOT\033[0m\n"
    printf "\033[1;36m========================================================\033[0m\n\n"

    printf "\033[1;33mEscenario (cuando systemd decide por ti):\033[0m\n"
    printf "  Un sistema Linux arranca correctamente tras un reboot. No hay errores críticos, el kernel carga sin problemas y la mayoría de los servicios están activos. Sin embargo, una aplicación interna que debería levantarse automáticamente simplemente no está corriendo. El servicio está habilitado, nadie lo desinstaló y no aparece como \"failed\". Aun así, systemd tomó una decisión silenciosa: omitir su arranque. Este escenario pone a prueba tu capacidad para leer con atención el estado de un servicio y entender cómo systemd evalúa condiciones antes de ejecutar cualquier proceso.\n\n"

    printf "\033[1;33mSíntomas (el silencio también es una pista):\033[0m\n"
    printf "  \033[1;31m- systemctl status muestra el servicio como \"inactive (dead)\", no como \"failed\".\033[0m\n"
    printf "  \033[1;31m- El servicio está habilitado pero no arranca tras el reboot.\033[0m\n"
    printf "  \033[1;31m- No hay errores evidentes en journalctl relacionados con crashes.\033[0m\n"
    printf "  \033[1;31m- El estado del servicio menciona una condición que no se cumple.\033[0m\n\n"

    printf "\033[1;33mTarea (piensa como systemd):\033[0m\n"
    printf "  Investiga por qué systemd decidió no iniciar el servicio. Identifica qué condición bloquea su ejecución y restaura el estado esperado del sistema. La solución correcta no consiste en forzar el arranque ni eliminar protecciones, sino en devolver al sistema aquello que systemd espera encontrar antes de iniciar el servicio. El servicio debe arrancar automáticamente y de forma limpia después de un reboot.\n\n"

    printf "\033[1;33mRestricciones (no luches contra el diseño):\033[0m\n"
    printf "  • No elimines ni comentes directivas del unit file sin entender su propósito.\n"
    printf "  • No conviertas el servicio en uno sin condiciones solo para que arranque.\n"
    printf "  • La solución debe persistir tras reiniciar el sistema.\n"
    printf "  • No está permitido reemplazar el servicio por otro distinto.\n\n"

    printf "\033[1;33mPistas (systemd siempre deja huellas):\033[0m\n"
    printf "  • Observa cuidadosamente la sección \"Condition\" en systemctl status.\n"
    printf "  • Revisa qué espera encontrar systemd antes de ejecutar el servicio.\n"
    printf "  • Piensa en archivos o flags que pueden existir antes del reboot y desaparecer después.\n"
    printf "  • Una vez corregido el problema, valida reiniciando el sistema.\n\n"

    printf "\033[1;36m========================================================\033[0m\n"
    printf "\nEjecutar con --apply para inyectar el fallo del servicio...\n"
}


# ==============================================================================
# Función 2: Aplicar fallo para LAB J03
# ==============================================================================
apply_lab() {
    local LOG="/var/log/lab_j03.log"
    local SERVICE_FILE="/etc/systemd/system/j03-demo.service"
    local SERVICE_DIR="/opt/j03-demo"
    local READY_DIR="/etc/j03"
    local READY_FLAG="$READY_DIR/ready.flag"

    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB J03: Iniciando inyección de fallo"
    } >> "$LOG"

    # Validación root
    if [ "$EUID" -ne 0 ]; then
        echo "ERROR: Ejecutar como root" | tee -a "$LOG"
        return 1
    fi

    # ------------------------------------------------------------------
    # 1) Crear script del servicio (simple y estable)
    # ------------------------------------------------------------------
    mkdir -p "$SERVICE_DIR"

    cat > "$SERVICE_DIR/start.sh" << 'EOF'
#!/bin/bash
while true; do
    echo "$(date '+%F %T') J03 demo service running" >> /var/log/j03-demo.log
    sleep 5
done
EOF

    chmod +x "$SERVICE_DIR/start.sh"

    # ------------------------------------------------------------------
    # 2) Crear unidad systemd con ConditionPathExists
    # ------------------------------------------------------------------
    cat > "$SERVICE_FILE" << 'EOF'
[Unit]
Description=J03 Demo Internal Service
ConditionPathExists=/etc/j03/ready.flag

[Service]
Type=simple
ExecStart=/opt/j03-demo/start.sh

[Install]
WantedBy=multi-user.target
EOF

    # ------------------------------------------------------------------
    # 3) Preparar condición (flag presente ANTES del reboot)
    # ------------------------------------------------------------------
    mkdir -p "$READY_DIR"
    echo "ready" > "$READY_FLAG"

    # ------------------------------------------------------------------
    # 4) Activar servicio
    # ------------------------------------------------------------------
    systemctl daemon-reexec
    systemctl daemon-reload
    systemctl enable j03-demo.service

    # Arranque inicial exitoso
    systemctl restart j03-demo.service

    # ------------------------------------------------------------------
    # 5) Inyectar el fallo real
    #    El flag se elimina → tras reboot el servicio será omitido
    # ------------------------------------------------------------------
    rm -f "$READY_FLAG"

    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Flag eliminado: $READY_FLAG"
        echo "Servicio arrancará ahora, pero será omitido tras reboot"
        echo "Pruebas sugeridas:"
        echo "  - systemctl status j03-demo"
        echo "  - reboot"
        echo "  - systemctl status j03-demo"
    } >> "$LOG"

    echo "Lab J03 inyectado. Reboot el sistema para observar el fallo."
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
