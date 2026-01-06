#!/bin/bash
# ==============================================================================
# J07 — Cron Backup Failure & Scheduling Issues
# INJECT SCRIPT
#
# Objetivo:
# - Introducir errores en scripts de backup ejecutados por cron
# - Romper o confundir el entorno de ejecución (PATH, variables, rutas)
# - Generar problemas de permisos y ownership en scripts, logs y destinos
# - Simular configuraciones conflictivas entre cron, cron.d y systemd timers
#
# Distro: RHEL 9 / Rocky / Alma
# Nivel: Sysadmin Junior (producción)
# ==============================================================================

set -uo pipefail


show_ticket() {
    clear
    printf "\033[1;36m========================================================\033[0m\n"
    printf "\033[1;36m   LAB J07\033[0m\n"
    printf "\033[1;36m========================================================\033[0m\n\n"

    printf "\033[1;33mEscenario:\033[0m\n"
    printf "  Una aplicación interna realiza copias de seguridad periódicas de sus datos\n"
    printf "  mediante un script programado con cron bajo un usuario de servicio dedicado.\n"
    printf "  Tras algunos ajustes recientes en la configuración del sistema y del backup,\n"
    printf "  el proceso dejó de comportarse como se esperaba.\n\n"
    printf "  Desde la sesión interactiva, algunos intentos manuales parecen funcionar,\n"
    printf "  pero las ejecuciones programadas no generan los resultados previstos.\n"
    printf "  No hay mensajes claros en pantalla y los usuarios solo notan que falta\n"
    printf "  la copia de seguridad o los logs habituales.\n\n"

    printf "\033[1;33mSíntomas:\033[0m\n"
    printf "  \033[1;31m• El script de backup existe y es invocado desde cron.\033[0m\n"
    printf "  \033[1;31m• No se generan los ficheros de backup esperados o acaban en rutas inesperadas.\033[0m\n"
    printf "  \033[1;31m• Los logs son incompletos, aparecen errores de permisos o directamente no se crean.\033[0m\n"
    printf "  \033[1;31m• Al ejecutar el script manualmente, el resultado puede diferir del cron.\033[0m\n\n"

    printf "\033[1;33mTarea:\033[0m\n"
    printf "  Recuperar un funcionamiento fiable del backup programado:\n"
    printf "  - Verificar qué usuario ejecuta realmente el cron y qué entorno tiene.\n"
    printf "  - Revisar rutas, permisos y variables usadas por el script de backup.\n"
    printf "  - Corregir la configuración para que el backup se ejecute de forma\n"
    printf "    consistente tanto desde cron como en pruebas controladas.\n"
    printf "  - Garantizar que se generen logs útiles para futuras incidencias.\n\n"

    printf "\033[1;33mRestricciones:\033[0m\n"
    printf "  • Prohibido resolver el problema usando chmod 777 de forma indiscriminada.\n"
    printf "  • Prohibido mover el script a root o ejecutarlo como root si no es necesario.\n"
    printf "  • No desactivar controles de seguridad ni eliminar restricciones de cron.\n"
    printf "  • La solución debe ser persistente y respetar buenas prácticas de backup.\n\n"

    printf "\033[1;33mPistas:\033[0m\n"
    printf "  • Cron se ejecuta con un entorno mínimo: no asume tu PATH ni tus variables.\n"
    printf "  • Las rutas relativas y los cambios de directorio se comportan distinto en cron.\n"
    printf "  • Propietario y permisos del script, del directorio de backup y de los logs\n"
    printf "    son tan importantes como el contenido del propio script.\n"
    printf "  • Comparar la ejecución manual con la salida/errores que genera cron\n"
    printf "    suele revelar diferencias críticas.\n\n"

    printf "\033[1;36m========================================================\033[0m\n"
    printf "\nEjecutar con --apply para inyectar el fallo...\n"
}


#!/bin/bash
# lab_j07_cron_function.sh
# Función apply_lab para ser llamada desde main.sh

apply_lab() {
    # ==========================================================================
    # CONFIGURACIÓN
    # ==========================================================================
    local BACKUP_DIR="/opt/backups"
    local DATA_DIR="/data/app"
    local USERNAME="appuser"
    local TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    local LOG_FILE="/var/log/lab_j07_${TIMESTAMP}.log"
    local BACKUP_BASE="/root/backup_j07_${TIMESTAMP}"
    
    # Colores para output (opcional, para main.sh con colores)
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
    
    # ==========================================================================
    # 1. SELECCIÓN ALEATORIA DE ESCENARIO (4 variantes)
    # ==========================================================================
    local RANDOM_SCENARIO=$((RANDOM % 4))
    echo "Seleccionado escenario: $RANDOM_SCENARIO" | tee -a "$LOG_FILE"
    
    # ==========================================================================
    # 2. CREAR ESTRUCTURA BÁSICA (común a todos los escenarios)
    # ==========================================================================
    create_basic_structure() {
        # Crear usuario si no existe
        if ! id "$USERNAME" &> /dev/null; then
            useradd -m -s /bin/bash "$USERNAME"
            echo "$USERNAME:labpass123" | chpasswd
        fi
        
        # Directorios necesarios
        mkdir -p "$BACKUP_DIR/logs"
        mkdir -p "$DATA_DIR"
        
        # Datos de prueba
        for i in {1..5}; do
            echo "Archivo de datos $i - $(date)" > "$DATA_DIR/file$i.txt"
        done
        
        # Archivo de configuración común
        cat > "$BACKUP_DIR/config.conf" << 'CONFIG'
BACKUP_SOURCE="/data/app"
BACKUP_DEST="/opt/backups"
RETENTION_DAYS=7
LOG_DIR="/opt/backups/logs"
CONFIG
        
        chown "$USERNAME:$USERNAME" "$BACKUP_DIR/config.conf"
    }
    
    # ==========================================================================
    # 3. FUNCIONES POR ESCENARIO
    # ==========================================================================
    
    # 3.1 Crear script de backup según escenario
    create_backup_script() {
        local scenario=$RANDOM_SCENARIO
        
        case $scenario in
            0)
                # ESCENARIO 0: PATH incompleto
                cat > "$BACKUP_DIR/backup_app.sh" << 'SCRIPT_0'
#!/bin/bash
# PROBLEMA: PATH mínimo, comandos sin ruta absoluta

# Cargar configuración
CONFIG="/opt/backups/config.conf"
if [ -f "$CONFIG" ]; then
    . "$CONFIG"
fi

# Comandos sin ruta absoluta (peligroso en cron)
BACKUP_FILE="backup_$(date +%Y%m%d).tar.gz"
tar -czf "$BACKUP_FILE" "$BACKUP_SOURCE" 2>/dev/null

if [ -f "$BACKUP_FILE" ]; then
    mv "$BACKUP_FILE" "$BACKUP_DEST/"
fi

echo "Backup: $(date)" > "/tmp/last_backup.log"
SCRIPT_0
                ;;
            
            1)
                # ESCENARIO 1: Variables de entorno faltantes
                cat > "$BACKUP_DIR/backup_app.sh" << 'SCRIPT_1'
#!/bin/bash
# PROBLEMA: Variables de shell no disponibles en cron

# Variables que NO existen en cron
USER_HOME=$HOME
TERM_TYPE=$TERM
LOGNAME=$LOGNAME

# Cargar configuración
source "/opt/backups/config.conf"

# Ruta relativa (depende de directorio actual)
cd "$BACKUP_SOURCE" || exit 1
tar -czf "../backup_$(whoami).tar.gz" .

# Usar $HOME (vacíO en cron)
echo "Backup en: $USER_HOME" > "$LOG_DIR/backup.log"
SCRIPT_1
                ;;
            
            2)
                # ESCENARIO 2: Permisos y redirección
                cat > "$BACKUP_DIR/backup_app.sh" << 'SCRIPT_2'
#!/bin/bash
# PROBLEMA: Permisos y redirección conflictiva

export PATH="/usr/bin:/bin"

# Configuración
CONF_FILE="/opt/backups/config.conf"
[ -f "$CONF_FILE" ] && source "$CONF_FILE"

# Log file (puede fallar por permisos)
LOG_FILE="$LOG_DIR/backup_$(date +%Y%m%d).log"

echo "Inicio: $(date)" > $LOG_FILE
tar -czf "$BACKUP_DEST/backup.tar.gz" "$BACKUP_SOURCE"/* >> $LOG_FILE 2>&1
echo "Fin: $(date)" >> $LOG_FILE
SCRIPT_2
                ;;
            
            3)
                # ESCENARIO 3: Múltiples problemas
                cat > "$BACKUP_DIR/backup_app.sh" << 'SCRIPT_3'
#!/bin/bash
# PROBLEMA: Combinación múltiple

# PATH limitado
PATH=/bin:/usr/bin

# Variable conflictiva
BACKUP_DIR="/tmp"  # ¡Sombra variable global!

# Cargar configuración
. /opt/backups/config.conf 2>/dev/null

# Backup con lógica confusa
TS=$(date +%s)
tar -czf /tmp/backup_${TS}.tar.gz /data/app 2>/dev/null

if [ -e /tmp/backup_${TS}.tar.gz ]; then
    cp /tmp/backup_${TS}.tar.gz /opt/backups/
    rm /tmp/backup_${TS}.tar.gz
fi

logger "Backup ejecutado"  # Depende de syslog
SCRIPT_3
                ;;
        esac
        
        chmod +x "$BACKUP_DIR/backup_app.sh"
        chown "$USERNAME:$USERNAME" "$BACKUP_DIR/backup_app.sh"
    }
    
    # 3.2 Configurar permisos problemáticos
    set_problematic_permissions() {
        local scenario=$RANDOM_SCENARIO
        
        case $scenario in
            0)
                chmod 644 "$BACKUP_DIR/backup_app.sh"  # Sin ejecución
                chown root:root "$BACKUP_DIR/logs"
                chmod 700 "$BACKUP_DIR/logs"
                ;;
            1)
                chmod 755 "$BACKUP_DIR/backup_app.sh"
                chown "$USERNAME:root" "$BACKUP_DIR/logs"
                chmod 770 "$BACKUP_DIR/logs"
                chmod 777 "$BACKUP_DIR/config.conf"
                ;;
            2)
                chmod 750 "$BACKUP_DIR"
                chmod 754 "$BACKUP_DIR/backup_app.sh"
                chown root:root "$BACKUP_DIR/config.conf"
                chmod 600 "$BACKUP_DIR/config.conf"
                ;;
            3)
                chmod 755 "$BACKUP_DIR/backup_app.sh"
                chmod 4755 "$BACKUP_DIR/backup_app.sh" 2>/dev/null || true  # SUID peligroso
                ;;
        esac
    }
    
    # 3.3 Configurar crontab problemático
    set_problematic_crontab() {
        local scenario=$RANDOM_SCENARIO
        
        # Limpiar crontab existente
        crontab -u "$USERNAME" -r 2>/dev/null || true
        
        case $scenario in
            0)
                # Sin entorno, hora específica
                crontab -u "$USERNAME" - << 'CRON_0'
0 2 * * * /opt/backups/backup_app.sh
CRON_0
                ;;
            
            1)
                # Variables incorrectas
                crontab -u "$USERNAME" - << 'CRON_1'
HOME=/tmp
SHELL=/bin/sh
PATH=/usr/bin
0 2 * * * /opt/backups/backup_app.sh
CRON_1
                ;;
            
            2)
                # Redirección incompleta
                crontab -u "$USERNAME" - << 'CRON_2'
PATH=/usr/local/bin:/usr/bin:/bin
0 2 * * * /opt/backups/backup_app.sh > /tmp/cron.log
CRON_2
                ;;
            
            3)
                # Configuración conflictiva
                crontab -u "$USERNAME" - << 'CRON_3'
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=""
0 2 * * * /opt/backups/backup_app.sh >> /opt/backups/logs/cron.log 2>&1
0 4 * * 0 /opt/backup/clean_old.sh 2>&1  # Script que no existe
CRON_3
                ;;
        esac
    }
    
    # 3.4 Problemas adicionales por escenario
    add_additional_problems() {
        local scenario=$RANDOM_SCENARIO
        
        case $scenario in
            0)
                # Archivo cron.deny confuso
                echo "nobody" > /etc/cron.deny 2>/dev/null || true
                ;;
            1)
                # Variables en .bashrc que interfieren
                echo "export BACKUP_DIR=/tmp" >> /home/$USERNAME/.bashrc
                ;;
            2)
                # Configuración de cron.d restrictiva
                cat > /etc/cron.d/50lab-j07 << 'CROND_2'
MAILTO=""
PATH=/usr/bin
CROND_2
                ;;
            3)
                # Systemd timer conflictivo
                cat > /etc/systemd/system/backup-conflict.timer << 'TIMER_3'
[Unit]
Description=Conflict timer
[Timer]
OnCalendar=*-*-* 02:00:00
[Install]
WantedBy=timers.target
TIMER_3
                systemctl daemon-reload 2>/dev/null || true
                ;;
        esac
    }
    
    # ==========================================================================
    # 4. EJECUCIÓN PRINCIPAL DE apply_lab
    # ==========================================================================
    
    # 4.1 Crear backup de configuración actual
    mkdir -p "$BACKUP_BASE"
    crontab -u "$USERNAME" -l 2>/dev/null > "$BACKUP_BASE/crontab.original" || true
    
    # 4.2 Crear estructura básica
    create_basic_structure
    
    # 4.3 Aplicar escenario seleccionado
    create_backup_script
    set_problematic_permissions
    set_problematic_crontab
    add_additional_problems
    
    # 4.4 Verificar aplicación
    {
        echo "=== LAB J07 APLICADO ==="
        echo "Escenario: $RANDOM_SCENARIO"
        echo "Fecha: $(date)"
        echo ""
        echo "=== CONFIGURACIÓN APLICADA ==="
        echo "Script: $BACKUP_DIR/backup_app.sh"
        ls -la "$BACKUP_DIR/backup_app.sh"
        echo ""
        echo "Crontab de $USERNAME:"
        crontab -u "$USERNAME" -l 2>/dev/null || echo "(vacío)"
        echo ""
        echo "=== PRUEBA MANUAL ==="
        echo "Ejecutando como $USERNAME:"
        sudo -u "$USERNAME" "$BACKUP_DIR/backup_app.sh" 2>&1 | head -5
    } | tee -a "$LOG_FILE"
    
    # 4.5 Mensaje final
    echo ""
    echo "========================================" | tee -a "$LOG_FILE"
    echo "✅ LABORATORIO J07 APLICADO" | tee -a "$LOG_FILE"
    echo "Escenario: $RANDOM_SCENARIO" | tee -a "$LOG_FILE"
    echo "Log: $LOG_FILE" | tee -a "$LOG_FILE"
    echo "Backup: $BACKUP_BASE" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"
    
    return 0
}

# ==============================================================================
# Ejecución principal
# ==============================================================================
case "${1:-}" in
    --apply)
        apply_lab
        ;;
    *)
        show_ticket
        ;;
esac