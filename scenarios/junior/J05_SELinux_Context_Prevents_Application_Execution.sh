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
# Función 2: Aplicar fallo para LAB J05 (4 VARIACIONES SELinux)
# ==============================================================================
apply_lab() {
    local LOG="/var/log/lab_j05.log"
    local APP_DIR="/opt/acme/bin"
    local APP="$APP_DIR/acme-app.sh"
    local SERVICE="/etc/systemd/system/acme-app.service"
    local SELINUX_BASE="/etc/selinux/local"
    local SELINUX_BIN="$SELINUX_BASE/bin"

    # Validación root
    if [ "$EUID" -ne 0 ]; then
        echo "ERROR: Ejecutar como root" | tee -a "$LOG"
        return 1
    fi

    # VARIACIÓN ALEATORIA (1-4)
    local VARIATION=$(( RANDOM % 4 + 1 ))

    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB J05: Iniciando variación $VARIATION"
    } >> "$LOG"

    # LIMPIAR configuraciones previas
    systemctl stop acme-app 2>/dev/null || true
    systemctl disable acme-app 2>/dev/null || true
    rm -f "$SERVICE"
    rm -rf "$APP_DIR"

    # LIMPIAR políticas SELinux previas (si existen)
    semodule -r acme-fail 2>/dev/null || true
    rm -rf "$SELINUX_BASE"

    # Crear aplicación base
    mkdir -p "$APP_DIR"
    cat > "$APP" << 'EOF'
#!/bin/bash
echo "ACME application running (PID $$)" >> /var/log/acme-app.log
exec sleep infinity
EOF
    chmod 755 "$APP"

    # ------------------------------------------------------------------
    # VARIACIÓN 1: Contexto SELinux incorrecto (restorecon)
    # ------------------------------------------------------------------
    if [ "$VARIATION" = "1" ]; then
        chcon -t default_t "$APP"
        cat > "$SERVICE" << EOF
[Unit]
Description=ACME Internal Application
After=network.target

[Service]
ExecStart=$APP
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
        echo "VARIACIÓN 1: Contexto SELinux 'default_t'" >> "$LOG"

    # ------------------------------------------------------------------
    # VARIACIÓN 2: SELinux deniega escritura de logs
    # ------------------------------------------------------------------
    elif [ "$VARIATION" = "2" ]; then
        chcon -t bin_t "$APP"
        touch /var/log/acme-app.log
        chcon -t user_tmp_t /var/log/acme-app.log
        cat > "$SERVICE" << EOF
[Unit]
Description=ACME Internal Application
After=network.target

[Service]
ExecStart=$APP
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
        echo "VARIACIÓN 2: Log con contexto user_tmp_t" >> "$LOG"

    # ------------------------------------------------------------------
    # VARIACIÓN 3: Contexto incorrecto en directorio
    # ------------------------------------------------------------------
    elif [ "$VARIATION" = "3" ]; then
        chcon -R -t bin_t "$APP_DIR"
        chcon -t user_home_t "$APP_DIR"
        cat > "$SERVICE" << EOF
[Unit]
Description=ACME Internal Application
After=network.target

[Service]
ExecStart=$APP
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
        echo "VARIACIÓN 3: Directorio con contexto user_home_t" >> "$LOG"

    # ------------------------------------------------------------------
    # VARIACIÓN 4: Política SELinux personalizada (robusta)
    # ------------------------------------------------------------------
    elif [ "$VARIATION" = "4" ]; then
        # Garantizar estructura SELinux
        mkdir -p "$SELINUX_BIN"

        cat > "$SELINUX_BIN/acme-fail.te" << EOF
policy_module(acme-fail, 1.0)

require {
    type unconfined_service_t;
    type bin_t;
    class file execute;
}

dontaudit unconfined_service_t bin_t:file execute;
EOF

        checkmodule -M -m \
            -o "$SELINUX_BIN/acme-fail.mod" \
            "$SELINUX_BIN/acme-fail.te"

        semodule_package \
            -o "$SELINUX_BIN/acme-fail.pp" \
            -m "$SELINUX_BIN/acme-fail.mod"

        semodule -i "$SELINUX_BIN/acme-fail.pp"

        chcon -t bin_t "$APP"

        cat > "$SERVICE" << EOF
[Unit]
Description=ACME Internal Application
After=network.target

[Service]
ExecStart=$APP
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
        echo "VARIACIÓN 4: Política SELinux dontaudit instalada" >> "$LOG"
    fi

    # ------------------------------------------------------------------
    # CONFIGURAR Y PROBAR SERVICIO
    # ------------------------------------------------------------------
    systemctl daemon-reload
    systemctl enable acme-app.service >> "$LOG" 2>&1
    systemctl start acme-app.service >> "$LOG" 2>&1 || true

    {
        echo "=== DIAGNÓSTICO ==="
        echo "getenforce: $(getenforce)"
        echo "Contexto app: $(ls -Z "$APP")"
        echo "Estado servicio: $(systemctl is-active acme-app.service)"
        echo "Variación aplicada: $VARIATION"
    } >> "$LOG"

    echo "✅ LAB J05-$VARIATION inyectado (SELinux bloqueando acme-app.service)"
    echo "📄 Detalles: $LOG"
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
