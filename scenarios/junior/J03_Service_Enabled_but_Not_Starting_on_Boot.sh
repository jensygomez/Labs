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

    printf "\033[1;33mEscenario:\033[0m\n"
    printf "  En Linux, arrancar un servicio no es una orden, es una negociación.\n"
    printf "  systemd no ejecuta procesos a ciegas: primero evalúa si el sistema\n"
    printf "  cumple las condiciones que garantizan un arranque seguro y coherente.\n"
    printf "  Tras un reboot, el sistema parece sano, estable y funcional. Sin embargo,\n"
    printf "  un servicio interno —habilitado y correctamente instalado— simplemente\n"
    printf "  no está corriendo. No falló. No se estrelló. Fue omitido.\n"
    printf "  systemd decidió que el entorno ya no era el que el servicio esperaba.\n\n"

    printf "\033[1;33mSíntomas:\033[0m\n"
    printf "  \033[1;31m• El servicio no aparece como \"failed\", sino como inactivo.\033[0m\n"
    printf "  \033[1;31m• systemctl status indica que el arranque fue saltado.\033[0m\n"
    printf "  \033[1;31m• journalctl no muestra errores de ejecución ni crashes.\033[0m\n"
    printf "  \033[1;31m• El propio estado del servicio sugiere una condición no satisfecha.\033[0m\n\n"

    printf "\033[1;33mTarea:\033[0m\n"
    printf "  Restaurar el acuerdo entre el servicio y el sistema:\n"
    printf "  - Identificar qué condición evalúa systemd antes de ejecutar el servicio\n"
    printf "  - Comprender por qué esa condición deja de cumplirse tras el reboot\n"
    printf "  - Devolver al sistema exactamente lo que el servicio espera encontrar\n"
    printf "  La solución correcta no consiste en forzar el arranque,\n"
    printf "  sino en respetar la lógica declarativa del sistema.\n\n"

    printf "\033[1;33mRestricciones:\033[0m\n"
    printf "  • Prohibido eliminar condiciones solo para que el servicio arranque\n"
    printf "  • No modificar el diseño del unit file sin entender su intención\n"
    printf "  • No convertir un problema de estado en un problema de fuerza bruta\n"
    printf "  • La solución debe sobrevivir a un reinicio completo del sistema\n\n"

    printf "\033[1;33mPistas:\033[0m\n"
    printf "  • systemd siempre explica por qué decide no ejecutar algo\n"
    printf "  • Observa con atención la sección \"Condition\" del servicio\n"
    printf "  • Piensa qué existe antes del reboot y qué desaparece después\n"
    printf "  • Cuando la condición se cumple, el servicio arranca sin protestar\n\n"

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
