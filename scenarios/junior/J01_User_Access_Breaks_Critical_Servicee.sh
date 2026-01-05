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

apply_lab() {
    local LOG="/var/log/lab_j01.log"
    local SERVICE="internal-api"
    local SERVICE_USER="apiuser"
    local SERVICE_DIR="/opt/internal-api"
    local BACKUP="/root/lab_j01_backup"
    
    # Generar variante aleatoria (1-5)
    local VARIANT=$(( (RANDOM % 5) + 1 ))
    
    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB J01: Iniciando inyección de fallo - VARIANTE $VARIANT"
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

    # Crear estructura base
    mkdir -p "$SERVICE_DIR"
    echo -e '#!/bin/bash\necho "API running"\nsleep 2' > "$SERVICE_DIR/start.sh"
    chmod 700 "$SERVICE_DIR/start.sh"

    # Aplicar variante aleatoria
    case $VARIANT in
        1)
            # VARIANTE 1: Usuario del servicio eliminado
            userdel "$SERVICE_USER" &>/dev/null || true
            useradd -r -s /bin/bash "apiuser-temp" &>/dev/null || true
            chown apiuser-temp:apiuser-temp "$SERVICE_DIR/start.sh"
            
            cat > /etc/systemd/system/${SERVICE}.service <<EOF
[Unit]
Description=Internal API Service

[Service]
User=${SERVICE_USER}  # Usuario que NO existe
ExecStart=${SERVICE_DIR}/start.sh

[Install]
WantedBy=multi-user.target
EOF
            echo "Variante 1: Usuario '$SERVICE_USER' no existe en el sistema" >> "$LOG"
            ;;
            
        2)
            # VARIANTE 2: Permisos incorrectos en script de inicio
            useradd -r -s /sbin/nologin "$SERVICE_USER" &>/dev/null || true
            chmod 000 "$SERVICE_DIR/start.sh"  # Sin permisos de ejecución
            chown "$SERVICE_USER":"$SERVICE_USER" "$SERVICE_DIR/start.sh"
            
            cat > /etc/systemd/system/${SERVICE}.service <<EOF
[Unit]
Description=Internal API Service

[Service]
User=${SERVICE_USER}
ExecStart=${SERVICE_DIR}/start.sh

[Install]
WantedBy=multi-user.target
EOF
            echo "Variante 2: Script sin permisos de ejecución (chmod 000)" >> "$LOG"
            ;;
            
        3)
            # VARIANTE 3: Grupo incorrecto en directorio del servicio
            useradd -r -s /sbin/nologin "$SERVICE_USER" &>/dev/null || true
            groupadd "apiadmin" &>/dev/null || true
            chown "$SERVICE_USER":apiadmin "$SERVICE_DIR/start.sh"
            chmod 750 "$SERVICE_DIR/start.sh"
            
            # Cambiar permisos del directorio
            chown root:root "$SERVICE_DIR"
            chmod 700 "$SERVICE_DIR"  # Usuario del servicio no puede entrar
            
            cat > /etc/systemd/system/${SERVICE}.service <<EOF
[Unit]
Description=Internal API Service

[Service]
User=${SERVICE_USER}
Group=${SERVICE_USER}
ExecStart=${SERVICE_DIR}/start.sh

[Install]
WantedBy=multi-user.target
EOF
            echo "Variante 3: Permisos de directorio incorrectos (chmod 700 como root)" >> "$LOG"
            ;;
            
        4)
            # VARIANTE 4: Usuario sin shell válido (pero diferente)
            useradd -r -s /bin/false "$SERVICE_USER" &>/dev/null || true
            chown "$SERVICE_USER":"$SERVICE_USER" "$SERVICE_DIR/start.sh"
            chmod 755 "$SERVICE_DIR/start.sh"
            
            # Crear archivo de configuración que el servicio necesita leer
            echo "API_KEY=secret123" > "$SERVICE_DIR/config.env"
            chmod 600 "$SERVICE_DIR/config.env"  # Solo root puede leer
            
            cat > /etc/systemd/system/${SERVICE}.service <<EOF
[Unit]
Description=Internal API Service

[Service]
User=${SERVICE_USER}
ExecStart=/bin/bash ${SERVICE_DIR}/start.sh
EnvironmentFile=${SERVICE_DIR}/config.env

[Install]
WantedBy=multi-user.target
EOF
            echo "Variante 4: Usuario con shell /bin/false + archivo config inaccesible" >> "$LOG"
            ;;
            
        5)
            # VARIANTE 5: Conflictos con grupos y sudoers
            useradd -r -s /sbin/nologin "$SERVICE_USER" &>/dev/null || true
            useradd -r -s /sbin/nologin "backup-user" &>/dev/null || true
            
            # Asignar grupo primario incorrecto
            usermod -g backup-user "$SERVICE_USER" &>/dev/null || true
            
            chown "$SERVICE_USER":backup-user "$SERVICE_DIR/start.sh"
            chmod 751 "$SERVICE_DIR/start.sh"
            
            # Crear archivo de logs con permisos incorrectos
            touch "/var/log/${SERVICE}.log"
            chown root:root "/var/log/${SERVICE}.log"
            chmod 600 "/var/log/${SERVICE}.log"
            
            cat > /etc/systemd/system/${SERVICE}.service <<EOF
[Unit]
Description=Internal API Service

[Service]
User=${SERVICE_USER}
ExecStart=${SERVICE_DIR}/start.sh
StandardOutput=append:/var/log/${SERVICE}.log
StandardError=append:/var/log/${SERVICE}.log

[Install]
WantedBy=multi-user.target
EOF
            echo "Variante 5: Usuario con grupo primario incorrecto + log inaccesible" >> "$LOG"
            ;;
    esac

    systemctl daemon-reload
    systemctl enable "$SERVICE" &>/dev/null
    systemctl start "$SERVICE" &>/dev/null 2>&1 || true

    # Esperar un momento y verificar estado
    sleep 1
    
    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB J01: Inyección completada - VARIANTE $VARIANT"
        echo "   → Servicio: $SERVICE"
        echo "   → Estado del servicio: $(systemctl is-active $SERVICE 2>/dev/null || echo 'FAILED')"
        echo "   → Usuario del servicio: $(id $SERVICE_USER 2>/dev/null || echo 'NO EXISTE')"
        echo "   → Permisos del script: $(ls -la $SERVICE_DIR/start.sh 2>/dev/null | awk '{print $1}')"
        echo "   → Propietario del script: $(ls -la $SERVICE_DIR/start.sh 2>/dev/null | awk '{print $3":"$4}')"
        echo "   → Backup: $BACKUP"
        echo "   → Para diagnóstico: journalctl -u $SERVICE -n 20 --no-pager"
        echo "   → Para probar reinicio: systemctl restart $SERVICE"
        echo ""
        echo "PISTA DE LA VARIANTE:"
        case $VARIANT in
            1) echo "   - El usuario especificado en el servicio no existe" ;;
            2) echo "   - Problema con permisos de ejecución en el binario" ;;
            3) echo "   - El usuario no puede acceder al directorio del servicio" ;;
            4) echo "   - Shell del usuario o archivos de configuración inaccesibles" ;;
            5) echo "   - Conflictos de grupos o permisos de archivos de log" ;;
        esac
    } >> "$LOG"

    echo "================================================"
    echo "Lab J01 inyectado - VARIANTE $VARIANT"
    echo "================================================"
    echo "Servicio: $SERVICE"
    echo "Estado: $(systemctl is-active $SERVICE 2>/dev/null || echo 'INACTIVE/ERROR')"
    echo "Logs del lab: $LOG"
    echo "Para diagnóstico: journalctl -u $SERVICE -n 20 --no-pager"
    echo "================================================"
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
