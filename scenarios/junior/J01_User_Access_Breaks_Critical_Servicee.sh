#!/bin/bash
# ==============================================================================
# LAB J01 – JUNIOR
# Escenario: Application fails due to execution identity mismatch
# ==============================================================================
set -uo pipefail

# ==============================================================================
# Función 1: Mostrar ticket
# ==============================================================================
show_ticket() {
    clear
    printf "\033[1;36m========================================================\033[0m\n"
    printf "\033[1;36m   LAB J01 – JUNIOR – APPLICATION FAILS TO START\033[0m\n"
    printf "\033[1;36m========================================================\033[0m\n\n"

    printf "\033[1;33mEscenario:\033[0m\n"
    printf "  En Linux, los servicios no solo dependen de binarios y configuraciones,\n"
    printf "  sino también de la identidad bajo la cual se ejecutan.\n"
    printf "  Tras un cambio administrativo reciente —probablemente orientado a mejorar\n"
    printf "  la seguridad— una aplicación interna crítica dejó de iniciar.\n\n"
    printf "  El sistema sigue estable, el servicio existe y no hay errores aparentes\n"
    printf "  en la configuración general. Sin embargo, la aplicación no logra arrancar.\n"
    printf "  Algo en la relación entre el servicio y su identidad ya no encaja.\n\n"

    printf "\033[1;33mSíntomas:\033[0m\n"
    printf "  \033[1;31m• El servicio existe y está definido en systemd.\033[0m\n"
    printf "  \033[1;31m• El servicio falla al iniciar o termina inmediatamente.\033[0m\n"
    printf "  \033[1;31m• Reiniciar el servicio no resuelve el problema.\033[0m\n"
    printf "  \033[1;31m• El sistema no muestra fallos generales ni errores de arranque.\033[0m\n\n"

    printf "\033[1;33mTarea:\033[0m\n"
    printf "  Restaurar el equilibrio entre seguridad y operación:\n"
    printf "  - Identificar bajo qué usuario y grupo intenta ejecutarse el servicio\n"
    printf "  - Verificar si esa identidad tiene acceso real a los recursos necesarios\n"
    printf "  - Corregir la desalineación sin comprometer el principio de mínimo privilegio\n\n"
    printf "  La solución correcta no consiste en ejecutar todo como root,\n"
    printf "  sino en asegurar que cada proceso tenga exactamente los permisos que necesita.\n\n"

    printf "\033[1;33mRestricciones:\033[0m\n"
    printf "  • Prohibido relajar permisos de forma global (chmod 777)\n"
    printf "  • Prohibido ejecutar el servicio como root sin justificación\n"
    printf "  • Las correcciones deben persistir tras reiniciar el sistema\n\n"

    printf "\033[1;33mPistas:\033[0m\n"
    printf "  • systemd no ejecuta servicios como el usuario del shell\n"
    printf "  • La identidad del proceso es tan importante como el binario\n"
    printf "  • El journal suele revelar errores de permisos u ownership\n"
    printf "  • Un ajuste preciso suele ser más seguro que una solución amplia\n\n"

    printf "\033[1;36m========================================================\033[0m\n"
    printf "\nEjecutar con --apply para inyectar el fallo...\n"
}


# ==============================================================================
# Función 2: Aplicar laboratorio
# ==============================================================================

# ==============================================================================
# Función: Aplicar fallo para LAB J02 (versión rápida)
# ==============================================================================

aapply_lab() {
    local LOG="/var/log/lab_j01.log"
    local SERVICE="internal-api"
    local SERVICE_USER="apiuser"
    local SERVICE_DIR="/opt/internal-api"
    local BACKUP="/root/lab_j01_backup"

    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB J01: Iniciando inyección de fallo"
    } >> "$LOG"

    # Validación root
    if [ "$EUID" -ne 0 ]; then
        echo "ERROR: Ejecutar como root" >> "$LOG"
        exit 1
    fi

    # Backup del servicio si existe
    if [ -d "$SERVICE_DIR" ]; then
        cp -r "$SERVICE_DIR" "$BACKUP" 2>/dev/null || true
    fi

    # 1. Crear usuario incorrecto del servicio
    useradd -r -s /sbin/nologin "$SERVICE_USER" &>/dev/null || true

    # 2. Crear estructura y binario del servicio
    mkdir -p "$SERVICE_DIR"
    echo -e '#!/bin/bash\necho "API running"' > "$SERVICE_DIR/start.sh"
    chmod 700 "$SERVICE_DIR/start.sh"
    chown root:root "$SERVICE_DIR/start.sh"

    # 3. Crear unit file
    cat > /etc/systemd/system/${SERVICE}.service <<EOF
[Unit]
Description=Internal API Service

[Service]
User=${SERVICE_USER}
ExecStart=${SERVICE_DIR}/start.sh

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "$SERVICE" &>/dev/null
    systemctl start "$SERVICE" &>/dev/null

    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB J01: Inyección completada"
        echo "   → Servicio: $SERVICE"
        echo "   → Usuario del servicio: $(id $SERVICE_USER 2>/dev/null || echo 'NO EXISTE')"
        echo "   → Backup: $BACKUP"
        echo "   → Para probar reinicio: systemctl restart $SERVICE"
    } >> "$LOG"

    echo "Lab J01 inyectado. Revisa logs y estado del servicio..."
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
