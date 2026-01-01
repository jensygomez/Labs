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
    printf "  Servicio interno de producción falla tras ajustes administrativos.\n"
    printf "  Usuario del servicio configurado incorrectamente, bloqueando ejecución.\n\n"

    printf "\033[1;33mSíntomas:\033[0m\n"
    printf "  \033[1;31m- systemctl status internal-api.service muestra fallo\033[0m\n"
    printf "  \033[1;31m- journalctl muestra problemas de permisos o ownership\033[0m\n"
    printf "  \033[1;31m- Servicio no responde a reinicios\033[0m\n\n"

    printf "\033[1;33mTarea:\033[0m\n"
    printf "  Recuperar el servicio asegurando que:\n"
    printf "  - Usuario y permisos correctos\n"
    printf "  - Servicio levantado y persistente\n"
    printf "  - No se relajan permisos globales\n\n"

    printf "\033[1;33mRestricciones:\033[0m\n"
    printf "  • NO usar chmod 777 ni root innecesario\n"
    printf "  • Persistir fixes post-reboot\n\n"

    printf "\033[1;33mPistas:\033[0m\n"
    printf "  • Verificar user y group del servicio\n"
    printf "  • journalctl -u internal-api.service\n"
    printf "  • systemctl daemon-reload + restart\n"
    printf "  • chown /opt/internal-api/start.sh\n\n"

    printf "\033[1;36m========================================================\033[0m\n"
    printf "\nEjecutar con --apply para inyectar el fallo...\n"
}

# ==============================================================================
# Función 2: Aplicar laboratorio
# ==============================================================================
apply_lab() {
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
