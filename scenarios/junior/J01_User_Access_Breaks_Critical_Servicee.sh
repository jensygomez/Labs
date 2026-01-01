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

    printf "\033[1;33mEscenario (con un toque filosófico de Linux):\033[0m\n"
    printf "  Imagina un ecosistema Linux donde todo fluye en armonía, guiado por los principios de menor privilegio y separación de responsabilidades. Pero, como en la vida real, un ajuste administrativo bien intencionado –quizá un cambio en la configuración de usuarios para reforzar la seguridad– puede romper esa armonía. Aquí, un servicio interno de producción, esencial para el funcionamiento diario, se detiene abruptamente. El culpable: una configuración de usuario errónea que impide la ejecución del servicio, recordándonos que en Linux, los permisos no son solo reglas técnicas, sino guardianes de la integridad del sistema. Este escenario no es solo un fallo; es una lección sobre cómo las acciones humanas interactúan con la máquina, y cómo un pequeño desequilibrio puede propagarse como ondas en un estanque.\n\n"

    printf "\033[1;33mSíntomas (observa con ojos de senior):\033[0m\n"
    printf "  \033[1;31m- systemctl status internal-api.service revela un fallo, pero profundiza: ¿qué dice realmente sobre el estado del servicio? ¿Es un problema de inicio o de runtime?\033[0m\n"
    printf "  \033[1;31m- journalctl expone errores de permisos o ownership, invitándote a reflexionar: ¿por qué este usuario no puede acceder? ¿Es un tema de herencia de grupos o de paths absolutos?\033[0m\n"
    printf "  \033[1;31m- El servicio ignora reinicios, sugiriendo que el problema es persistente, como un karma no resuelto en el ciclo de vida del sistema.\033[0m\n\n"

    printf "\033[1;33mTarea (piensa como un senior, actúa con precisión):\033[0m\n"
    printf "  Restaura el equilibrio del servicio, pero hazlo con sabiduría linuxera: asegura que el usuario y los permisos reflejen el principio de 'lo justo y necesario'. Levanta el servicio para que sea resiliente, persistente más allá de reinicios, y mantén la integridad global sin comprometer la seguridad. Recuerda, un senior no solo arregla; entiende el 'porqué' para prevenir futuros desequilibrios. Pregúntate: ¿cómo impacta esto en la escalabilidad? ¿Y en auditorías de seguridad?\n\n"

    printf "\033[1;33mRestricciones (honra los mandamientos de Linux):\033[0m\n"
    printf "  • Evita el caos de chmod 777 o el abuso de root; eso sería como abrir las puertas del templo a todos, invitando al desastre.\n"
    printf "  • Asegura que tus soluciones perduren post-reboot, como raíces profundas en el filesystem que sobreviven al ciclo de encendido.\n\n"

    printf "\033[1;33mPistas (guías para la iluminación):\033[0m\n"
    printf "  • Inspecciona el user y group del servicio en su unidad systemd; ¿coinciden con los owners de los archivos críticos?\n"
    printf "  • Usa journalctl -u internal-api.service para descifrar los logs como un oráculo, buscando patrones en el tiempo.\n"
    printf "  • Recarga el daemon con systemctl daemon-reload y reinicia, pero solo después de alinear las configuraciones.\n"
    printf "  • Considera chown en paths específicos como /opt/internal-api/start.sh, pero reflexiona: ¿es este el único punto de fricción, o hay más en la cadena?\n\n"

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
    local API_LOG="/var/log/internal-api.log"

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

    # 1. Crear usuario del servicio
    useradd -r -s /sbin/nologin "$SERVICE_USER" &>/dev/null || true

    # 2. Crear estructura y script con loop infinito (más realista)
    mkdir -p "$SERVICE_DIR"

    cat > "$SERVICE_DIR/start.sh" <<'EOF'
#!/bin/bash
echo "Internal API started (PID $$) - listening..."
echo "$(date '+%Y-%m-%d %H:%M:%S') - API started (PID $$)" >> /var/log/internal-api.log

# Bucle infinito para mantener el servicio vivo
while true; do
    sleep 300  # duerme 5 minutos entre iteraciones (bajo consumo)
done
EOF

    chmod 700 "$SERVICE_DIR/start.sh"
    chown root:root "$SERVICE_DIR/start.sh"   # ← Aquí inyectamos el fallo de permisos

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

    # Crear el archivo de log de la API (para que exista y dé otro síntoma opcional)
    touch "$API_LOG"
    chown root:root "$API_LOG"
    chmod 640 "$API_LOG"

    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB J01: Inyección completada"
        echo "   → Servicio: $SERVICE"
        echo "   → Usuario del servicio: $(id $SERVICE_USER 2>/dev/null || echo 'NO EXISTE')"
        echo "   → Backup: $BACKUP"
        echo "   → Script con loop infinito para estado 'active (running)'"
        echo "   → Log de API creado en $API_LOG (ownership root:root)"
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
