#!/bin/bash
# ==============================================================================
# LAB J01 – JUNIOR
# Escenario: Usuario del servicio incorrecto bloquea aplicación crítica
# ==============================================================================
set -uo pipefail


# ==============================================================================
# Función 2: Mostrar ticket J02
# ==============================================================================
show_ticket() {
    clear
    printf "\033[1;36m========================================================\033[0m\n"
    printf "\033[1;36m   LAB J02 – JUNIOR – DISK PRESSURE BREAKS SERVICE\033[0m\n"
    printf "\033[1;36m========================================================\033[0m\n\n"

    printf "\033[1;33mEscenario (el peso del almacenamiento en Linux):\033[0m\n"
    printf "  Imagina un sistema Linux que ha ido creciendo en silencio: logs que nadie rota, core dumps olvidados, cachés que se inflan con cada actualización. Todo parece funcionar… hasta que el disco, ese recurso finito y a veces subestimado, se convierte en el cuello de botella. De repente, servicios que antes levantaban sin quejas empiezan a fallar, operaciones simples como crear archivos temporales se niegan a ejecutarse, y el sistema te recuerda una verdad básica: sin espacio en disco, no hay progreso. Este no es solo un fallo técnico; es un recordatorio de que la observabilidad y la gestión proactiva del espacio son parte esencial del diseño de un sistema sano.\n\n"

    printf "\033[1;33mSíntomas (lee entre bloques y porcentajes):\033[0m\n"
    printf "  \033[1;31m- systemctl status muestra servicios que fallan al arrancar o se caen inesperadamente, a veces con mensajes crípticos relacionados con escritura de logs o PID files.\033[0m\n"
    printf "  \033[1;31m- journalctl revela errores como \"No space left on device\" o fallos al crear archivos temporales en /tmp, /var/log o directorios de trabajo del servicio.\033[0m\n"
    printf "  \033[1;31m- df -h y du -sh exponen un / casi al límite, con directorios como /var/log, /var/lib/systemd/coredump o /var/cache consumiendo más de lo que deberían.\033[0m\n\n"

    printf "\033[1;33mTarea (piensa como SRE, actúa como admin):\033[0m\n"
    printf "  Restaura la salud del sistema recuperando espacio de forma inteligente, sin destruir evidencias útiles ni provocar más daño. Identifica qué está llenando el disco (logs, core dumps, cachés, archivos temporales) y aplica medidas correctivas: limpieza selectiva, rotación de logs, configuración de límites o políticas de retención. Garantiza que los servicios críticos vuelvan a arrancar de forma confiable y que el sistema no vuelva a quedarse sin espacio a la primera rotación de logs.\n\n"

    printf "\033[1;33mRestricciones (no mates al mensajero):\033[0m\n"
    printf "  • Evita borrar ciegamente todo /var/log; los logs son valiosos para auditoría y troubleshooting.\n"
    printf "  • No desactives la generación de logs o core dumps sin entender el impacto en soporte y análisis de incidentes.\n"
    printf "  • Asegura que cualquier cambio (logrotate, límites de systemd-coredump, limpieza de cachés) sea persistente y se mantenga tras el reboot.\n\n"

    printf "\033[1;33mPistas (del \"df -h\" a la causa raíz):\033[0m\n"
    printf "  • Usa df -h para localizar el filesystem bajo presión y du -sh /var/* /home/* /opt/* para descubrir qué directorios son los responsables.\n"
    printf "  • Inspecciona /var/log, /var/lib/systemd/coredump y /var/cache/dnf: ¿hay archivos gigantes o muchos ficheros antiguos que ya no aportan valor?\n"
    printf "  • Revisa la configuración de rotación de logs (por ejemplo en /etc/logrotate.d/) y de core dumps (systemd-coredump, límites de tamaño) para prevenir que el problema se repita.\n"
    printf "  • Tras liberar espacio, verifica con df -h y luego intenta systemctl restart en los servicios afectados para confirmar que el sistema se ha recuperado.\n\n"

    printf "\033[1;36m========================================================\033[0m\n"
    printf "\nEjecutar con --apply para inyectar el fallo de espacio en disco...\n"
}








# ==============================================================================
# Función: Aplicar fallo para LAB J02 (versión rápida)
# ==============================================================================

apply_fall() {
    local LOG="/var/log/lab_j02.log"
    local APP_LOG_DIR="/var/log/application"
    local COREDUMP_DIR="/var/lib/systemd/coredump"
    local CACHE_DIR="/var/cache/dnf"
    local BACKUP="/root/lab_j02_backup"
    local TARGET_USAGE=95      # Porcentaje objetivo de uso de /
    local MARGIN_MB=200       # Margen de seguridad para no llegar al 100%
    local FILL_DIR="$APP_LOG_DIR"
    local FILL_FILE="$FILL_DIR/disk_filler.bin"

    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB J02: Iniciando inyección de fallo (versión rápida)"
    } >> "$LOG"

    # Validación root
    if [ "$EUID" -ne 0 ]; then
        echo "ERROR: Ejecutar como root" >> "$LOG"
        echo "Este script debe ejecutarse como root."
        return 1
    fi

    # Backup de directorios clave si existen
    mkdir -p "$BACKUP"
    [ -d "$APP_LOG_DIR" ] && cp -r "$APP_LOG_DIR" "$BACKUP" 2>/dev/null || true
    [ -d "$COREDUMP_DIR" ] && cp -r "$COREDUMP_DIR" "$BACKUP" 2>/dev/null || true
    [ -d "$CACHE_DIR" ] && cp -r "$CACHE_DIR" "$BACKUP" 2>/dev/null || true

    # Crear estructura base
    mkdir -p "$APP_LOG_DIR" "$COREDUMP_DIR" "$CACHE_DIR"

    # ------------------------------------------------------------------
    # 1) Llenar disco hasta TARGET_USAGE% con un único archivo grande
    # ------------------------------------------------------------------
    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Calculando tamaño de archivo de relleno..."
    } >> "$LOG"

    local LINE TOTAL_KB USED_KB FREE_KB CURRENT_USAGE
    LINE=$(df -k / | awk 'NR==2 {print $2" "$3" "$4}')
    read TOTAL_KB USED_KB FREE_KB <<< "$LINE"
    CURRENT_USAGE=$(( USED_KB * 100 / TOTAL_KB ))

    {
        echo "Uso actual de /: ${CURRENT_USAGE}% (TOTAL=${TOTAL_KB}K, USED=${USED_KB}K, FREE=${FREE_KB}K)"
    } >> "$LOG"

    if [ "$CURRENT_USAGE" -ge "$TARGET_USAGE" ]; then
        {
            echo "Ya se está por encima de ${TARGET_USAGE}%, no se creará archivo de relleno."
        } >> "$LOG"
    else
        local TARGET_USED_KB NEED_KB NEED_MB
        TARGET_USED_KB=$(( TARGET_USAGE * TOTAL_KB / 100 ))
        NEED_KB=$(( TARGET_USED_KB - USED_KB ))
        NEED_MB=$(( (NEED_KB / 1024) - MARGIN_MB ))

        if [ "$NEED_MB" -le 0 ]; then
            {
                echo "El margen de seguridad (${MARGIN_MB} MB) es mayor que lo que falta para llegar a ${TARGET_USAGE}%."
                echo "No se crea archivo de relleno."
            } >> "$LOG"
        else
            {
                echo "Creando archivo de relleno de aproximadamente ${NEED_MB} MB en $FILL_FILE"
            } >> "$LOG"

            # Intentar con fallocate (rápido); si falla, usar dd
            if command -v fallocate >/dev/null 2>&1; then
                if ! fallocate -l "${NEED_MB}M" "$FILL_FILE" 2>>"$LOG"; then
                    {
                        echo "fallocate falló o el FS no lo soporta; usando dd como alternativa."
                    } >> "$LOG"
                    dd if=/dev/zero of="$FILL_FILE" bs=1M count="$NEED_MB" status=none 2>>"$LOG"
                fi
            else
                dd if=/dev/zero of="$FILL_FILE" bs=1M count="$NEED_MB" status=none 2>>"$LOG"
            fi
        fi
    fi

    # Recalcular uso tras el archivo de relleno
    LINE=$(df -k / | awk 'NR==2 {print $2" "$3" "$4}')
    read TOTAL_KB USED_KB FREE_KB <<< "$LINE"
    CURRENT_USAGE=$(( USED_KB * 100 / TOTAL_KB ))
    {
        echo "Uso de / tras archivo de relleno: ${CURRENT_USAGE}%"
    } >> "$LOG"

    # ------------------------------------------------------------------
    # 2) Ruido “realista”: logs y core dumps pequeños
    #    (no llenan tanto, solo dan contexto al fallo)
    # ------------------------------------------------------------------

    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Creando logs y core dumps de tamaño moderado..."
    } >> "$LOG"

    # Log de aplicación de ~200 MB
    dd if=/dev/zero of="$APP_LOG_DIR/app.log" bs=1M count=200 status=none 2>>"$LOG"

    # 3 core dumps de ~100 MB cada uno
    local i
    for i in 1 2 3; do
        dd if=/dev/zero of="$COREDUMP_DIR/core.app.$(date +%s).$i.gz" \
           bs=1M count=100 status=none 2>>"$LOG"
        sleep 1
    done

    # Opcional: una única pasada de dnf para inflar un poco la cache, sin abusar
    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Inflando ligeramente la cache de DNF (una sola pasada)..."
    } >> "$LOG"

    dnf install -y --downloadonly --downloaddir="$CACHE_DIR" \
        epel-release httpd nginx kernel-devel  >>"$LOG" 2>&1 || true

    # ------------------------------------------------------------------
    # 3) Verificación final
    # ------------------------------------------------------------------
    LINE=$(df -k / | awk 'NR==2 {print $2" "$3" "$4}')
    read TOTAL_KB USED_KB FREE_KB <<< "$LINE"
    CURRENT_USAGE=$(( USED_KB * 100 / TOTAL_KB ))

    {
        echo "Uso final de /: ${CURRENT_USAGE}%"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB J02: Inyección completada (versión rápida)"
        echo "   → Archivo de relleno: $FILL_FILE"
        echo "   → Log gigante: $APP_LOG_DIR/app.log"
        echo "   → Core dumps: $COREDUMP_DIR"
        echo "   → Cache DNF: $CACHE_DIR"
        echo "   → Backup: $BACKUP"
        echo "   → Pruebas sugeridas:"
        echo "       - df -h /"
        echo "       - touch /tmp/test  (debería fallar si el disco está muy lleno)"
    } >> "$LOG"

    echo "Lab J02 inyectado (versión rápida). Revisa $LOG y el uso de disco con df -h /"
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
