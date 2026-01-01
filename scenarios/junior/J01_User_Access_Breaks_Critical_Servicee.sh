#!/bin/bash
# ==============================================================================
# LAB J01 – JUNIOR
# Escenario: Usuario del servicio incorrecto bloquea aplicación crítica
# ==============================================================================
set -uo pipefail

# ==============================================================================
# Función 1: Mostrar ticket
# ==============================================================================
show_ticket() {
    clear
    printf "\033[1;36m========================================================\033[0m\n"
    printf "\033[1;36m   LAB J01 – JUNIOR – USER ACCESS BREAKS SERVICE\033[0m\n"
    printf "\033[1;36m========================================================\033[0m\n\n"

    printf "\033[1;33mEscenario:\033[0m\n"
    printf "  En Linux todo funciona cuando se respeta el principio de menor privilegio.\n"
    printf "  Un ajuste administrativo (quizá para mejorar la seguridad) cambió algo\n"
    printf "  y rompió el equilibrio: el servicio internal-api dejó de arrancar.\n"
    printf "  El problema está en la configuración del usuario que ejecuta el servicio,\n"
    printf "  recordándonos que los permisos son los guardianes silenciosos del sistema.\n\n"

    printf "\033[1;33mSíntomas:\033[0m\n"
    printf "  \033[1;31m• systemctl status internal-api.service\033[0m muestra fallo\n"
    printf "  \033[1;31m• journalctl\033[0m revela errores de permisos u ownership\n"
    printf "  \033[1;31m• El servicio no responde a reinicios\033[0m\n\n"

    printf "\033[1;33mTarea:\033[0m\n"
    printf "  Recuperar el servicio manteniendo la seguridad:\n"
    printf "  - Usuario y permisos correctos (solo lo necesario)\n"
    printf "  - Servicio funcionando y persistente tras reboot\n"
    printf "  - Sin relajar permisos de forma global\n\n"

    printf "\033[1;33mRestricciones:\033[0m\n"
    printf "  • Prohibido chmod 777 o usar root sin necesidad\n"
    printf "  • Las correcciones deben sobrevivir a un reinicio\n\n"

    printf "\033[1;33mPistas:\033[0m\n"
    printf "  • Revisa User= y Group= en la unit de systemd\n"
    printf "  • journalctl -u internal-api.service te dirá el error exacto\n"
    printf "  • Compara el owner de /opt/internal-api/start.sh con el usuario del servicio\n"
    printf "  • Un chown preciso suele ser la solución más limpia\n\n"

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
