#!/bin/bash
# ===========================================================================
# LAB J03 – JUNIOR
# Escenario: Servicio no arranca tras reboot (systemd condition)
# ===========================================================================
set -uo pipefail

# ==============================================================================
# Función: Mostrar ticket J03
# ==============================================================================
show_ticket() {
    clear
    printf "\033[1;36m========================================================\033[0m\n"
    printf "\033[1;36m   LAB J03 – JUNIOR – SERVICE SKIPPED AFTER REBOOT\033[0m\n"
    printf "\033[1;36m========================================================\033[0m\n\n"

    printf "\033[1;33mEscenario (cuando systemd decide no intervenir):\033[0m\n"
    printf "  En entornos modernos, systemd no se limita a arrancar servicios:\n"
    printf "  primero valida que el sistema se encuentre en un estado coherente.\n"
    printf "  Tras un reinicio planificado, el host vuelve a estar operativo,\n"
    printf "  pero un servicio interno —habilitado y sin errores aparentes—\n"
    printf "  no está en ejecución. No falló, no se detuvo, no registró crashes.\n"
    printf "  Simplemente fue omitido porque una condición declarada no se cumplió.\n"
    printf "  El sistema hizo exactamente lo que se le pidió.\n\n"

    printf "\033[1;33mSíntomas (no todo lo que no corre está roto):\033[0m\n"
    printf "  \033[1;31m• systemctl status muestra el servicio como inactivo, no failed.\033[0m\n"
    printf "  \033[1;31m• El log indica que el arranque fue \"skipped\" por una condición.\033[0m\n"
    printf "  \033[1;31m• journalctl no presenta errores de ejecución ni permisos.\033[0m\n"
    printf "  \033[1;31m• El servicio puede arrancar manualmente si el entorno es correcto.\033[0m\n\n"

    printf "\033[1;33mTarea (diagnóstico basado en intención, no en fuerza):\033[0m\n"
    printf "  Analiza el acuerdo implícito entre el servicio y el sistema:\n"
    printf "  - Identificar qué Condition= o Assert= evalúa systemd\n"
    printf "  - Determinar por qué esa condición no se cumple tras el reboot\n"
    printf "  - Restaurar el estado esperado (archivo, path, mount, variable, etc.)\n"
    printf "  El objetivo no es forzar el servicio a arrancar,\n"
    printf "  sino devolverle el contexto que necesita para hacerlo.\n\n"

    printf "\033[1;33mRestricciones (respetar el diseño del sistema):\033[0m\n"
    printf "  • No eliminar condiciones solo para evitar el análisis\n"
    printf "  • No modificar units sin comprender su propósito original\n"
    printf "  • No usar overrides como solución por defecto\n"
    printf "  • La corrección debe persistir tras un reboot completo\n\n"

    printf "\033[1;33mPistas (systemd siempre explica su decisión):\033[0m\n"
    printf "  • systemctl status detalla por qué una condición no se cumplió\n"
    printf "  • systemctl cat <servicio> revela Condition* y Assert*\n"
    printf "  • Compara el estado del sistema antes y después del reboot\n"
    printf "  • Cuando la condición vuelve a ser verdadera, el servicio arranca solo\n\n"

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
