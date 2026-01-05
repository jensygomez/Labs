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
    printf "\033[1;36m   LAB J03 – JUNIOR\033[0m\n"
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
# Función 2: Aplicar fallo para LAB J03 (VARIACIÓN ALEATORIA - CORREGIDA)
# ==============================================================================
apply_lab() {
    local LOG="/var/log/lab_j03.log"
    local SERVICE_FILE="/etc/systemd/system/j03-demo.service"
    local SERVICE_DIR="/opt/j03-demo"
    local READY_DIR="/etc/j03"
    local READY_FLAG="$READY_DIR/ready.flag"
    local CONFLICT_SERVICE="/etc/systemd/system/j03-conflict.service"
    
    # Validación root PRIMERO (antes de cualquier operación)
    if [ "$EUID" -ne 0 ]; then
        echo "ERROR: Ejecutar como root"
        return 1
    fi
    
    # Determinar variación aleatoriamente (1-4) o usar la especificada
    local VARIATION
    if [ -n "${2:-}" ] && [[ "${2:-}" =~ ^[1-4]$ ]]; then
        VARIATION="$2"
    else
        # Generar número aleatorio entre 1 y 4
        VARIATION=$(( RANDOM % 4 + 1 ))
    fi
    
    # AHORA empezamos a escribir en el log (después de definir todo)
    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB J03: Iniciando inyección de fallo"
        echo "Variación seleccionada: $VARIATION"
    } >> "$LOG"

    # Limpiar posibles configuraciones previas
    systemctl stop j03-demo.service j03-conflict.service 2>/dev/null
    systemctl disable j03-demo.service j03-conflict.service 2>/dev/null
    rm -f "$SERVICE_FILE" "$CONFLICT_SERVICE"
    rm -rf "$READY_DIR"

    # ------------------------------------------------------------------
    # 1) Crear script del servicio (simple y estable)
    # ------------------------------------------------------------------
    mkdir -p "$SERVICE_DIR"

    cat > "$SERVICE_DIR/start.sh" << 'EOF'
#!/bin/bash
COUNTER=0
while true; do
    echo "$(date '+%F %T') J03 demo service running (iteration $COUNTER)" >> /var/log/j03-demo.log
    COUNTER=$((COUNTER + 1))
    sleep 5
done
EOF

    chmod +x "$SERVICE_DIR/start.sh"

    # ------------------------------------------------------------------
    # VARIACIÓN 1: Original - Condición con flag que desaparece
    # ------------------------------------------------------------------
    if [ "$VARIATION" = "1" ]; then
        cat > "$SERVICE_FILE" << 'EOF'
[Unit]
Description=J03 Demo Service - Conditional Flag Check
ConditionPathExists=/etc/j03/ready.flag

[Service]
Type=simple
ExecStart=/opt/j03-demo/start.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

        mkdir -p "$READY_DIR"
        echo "ready" > "$READY_FLAG"
        
        systemctl daemon-reload
        systemctl enable j03-demo.service
        systemctl restart j03-demo.service
        
        # Inyectar fallo: eliminar flag tras reinicio
        rm -f "$READY_FLAG"
        
        {
            echo "VARIACIÓN 1: Flag condicional configurado y removido"
            echo "FALLO: ConditionPathExists=/etc/j03/ready.flag"
        } >> "$LOG"

    # ------------------------------------------------------------------
    # VARIACIÓN 2: Conflicto de dependencias cíclicas
    # ------------------------------------------------------------------
    elif [ "$VARIATION" = "2" ]; then
        cat > "$SERVICE_FILE" << 'EOF'
[Unit]
Description=J03 Demo Service - Circular Dependency
After=j03-conflict.service
Requires=j03-conflict.service

[Service]
Type=simple
ExecStart=/opt/j03-demo/start.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

        # Crear servicio conflictivo que depende del principal
        cat > "$CONFLICT_SERVICE" << 'EOF'
[Unit]
Description=J03 Conflict Service - Circular Dependency
After=j03-demo.service
Requires=j03-demo.service

[Service]
Type=oneshot
ExecStart=/bin/true
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

        # Habilitar ambos (creando dependencia circular)
        systemctl daemon-reload
        systemctl enable j03-demo.service
        systemctl enable j03-conflict.service
        
        # Iniciar manualmente funciona (con orden específica)
        systemctl start j03-conflict.service
        systemctl start j03-demo.service
        
        {
            echo "VARIACIÓN 2: Dependencia circular configurada"
            echo "FALLO: Dependencia circular entre j03-demo y j03-conflict"
        } >> "$LOG"

    # ------------------------------------------------------------------
    # VARIACIÓN 3: Target incorrecto en [Install]
    # ------------------------------------------------------------------
    elif [ "$VARIATION" = "3" ]; then
        cat > "$SERVICE_FILE" << 'EOF'
[Unit]
Description=J03 Demo Service - Wrong Target

[Service]
Type=simple
ExecStart=/opt/j03-demo/start.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=graphical.target
EOF

        systemctl daemon-reload
        systemctl enable j03-demo.service
        systemctl start j03-demo.service
        
        {
            echo "VARIACIÓN 3: Target gráfico configurado en servidor sin GUI"
            echo "FALLO: WantedBy=graphical.target (el sistema usa multi-user.target)"
        } >> "$LOG"

    # ------------------------------------------------------------------
    # VARIACIÓN 4: Timeout de inicio demasiado corto
    # ------------------------------------------------------------------
    elif [ "$VARIATION" = "4" ]; then
        cat > "$SERVICE_FILE" << 'EOF'
[Unit]
Description=J03 Demo Service - Startup Timeout

[Service]
Type=forking
ExecStart=/opt/j03-demo/slow-start.sh
TimeoutStartSec=10
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

        # Crear el script lento
        cat > /opt/j03-demo/slow-start.sh << 'EOF'
#!/bin/bash
(sleep 45; /opt/j03-demo/start.sh)&
sleep 1000
EOF
        chmod +x /opt/j03-demo/slow-start.sh
            
        systemctl daemon-reload
        systemctl enable j03-demo.service

        {
            echo "VARIACIÓN 4: Type=forking + slow-start.sh → TIMEOUT 10s"
            echo "FALLO: Servicio tarda >10s, systemd mata y reintenta"
        } >> "$LOG"

    fi

    # ------------------------------------------------------------------
    # Estado final y cierre
    # ------------------------------------------------------------------
    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB J03: Configuración completada"
        echo "Variación aplicada: $VARIATION/4"
        echo "Servicio: j03-demo.service"
        echo "Estado actual: $(systemctl is-active j03-demo.service 2>/dev/null || echo 'inactive')"
        echo "Habilitado: $(systemctl is-enabled j03-demo.service 2>/dev/null || echo 'disabled')"
    } >> "$LOG"
    
    # Solo mostrar mensaje mínimo al usuario
    echo "✅ LAB J03 configurado (Variación $VARIATION)"
    echo "📄 Log: $LOG"
    echo ""
    echo "💡 Ejecuta sin argumentos para ver el ticket del laboratorio"
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