#!/bin/bash
# ==============================================================================
# LAB J02 – JUNIOR
# Escenario: Disk pressure causes application instability
# ==============================================================================
set -uo pipefail


# ==============================================================================
# Función: Mostrar ticket J02
# ==============================================================================
show_ticket() {
    clear
    printf "\033[1;36m========================================================\033[0m\n"
    printf "\033[1;36m   LAB J02 – JUNIOR\033[0m\n"
    printf "\033[1;36m========================================================\033[0m\n\n"

    printf "\033[1;33mEscenario:\033[0m\n"
    printf "  En Linux, muchos problemas no aparecen de forma abrupta, sino que se\n"
    printf "  acumulan en silencio. El sistema ha estado funcionando sin cambios\n"
    printf "  recientes aparentes, pero en los últimos días algunos servicios han\n"
    printf "  comenzado a comportarse de forma inestable.\n\n"
    printf "  Procesos que antes iniciaban sin dificultad ahora fallan al arrancar,\n"
    printf "  otros se detienen inesperadamente, y tareas simples parecen tardar más\n"
    printf "  de lo normal. El sistema sigue en línea, pero algo esencial se está\n"
    printf "  agotando.\n\n"

    printf "\033[1;33mSíntomas:\033[0m\n"
    printf "  \033[1;31m• Servicios fallan al iniciar o se caen de forma intermitente.\033[0m\n"
    printf "  \033[1;31m• El journal muestra errores relacionados con escritura de archivos.\033[0m\n"
    printf "  \033[1;31m• Operaciones rutinarias generan mensajes poco claros o genéricos.\033[0m\n"
    printf "  \033[1;31m• No se observan fallos de red ni errores evidentes de configuración.\033[0m\n\n"

    printf "\033[1;33mTarea:\033[0m\n"
    printf "  Restaurar la estabilidad del sistema identificando el recurso bajo presión\n"
    printf "  y recuperando su funcionamiento normal sin comprometer la operación.\n"
    printf "  Para ello deberás:\n"
    printf "  - Determinar qué recurso crítico se encuentra al límite\n"
    printf "  - Identificar qué componentes del sistema están contribuyendo al problema\n"
    printf "  - Aplicar una solución precisa y sostenible\n\n"
    printf "  La solución correcta no consiste en eliminar datos de forma indiscriminada,\n"
    printf "  sino en comprender qué información es prescindible y cuál es necesaria\n"
    printf "  para la operación y el soporte del sistema.\n\n"

    printf "\033[1;33mRestricciones:\033[0m\n"
    printf "  • Prohibido eliminar datos de forma masiva o sin análisis previo\n"
    printf "  • No desactivar mecanismos de logging como solución rápida\n"
    printf "  • Evitar acciones que comprometan la capacidad de auditoría o diagnóstico\n"
    printf "  • Las correcciones deben ser persistentes tras reiniciar el sistema\n\n"

    printf "\033[1;33mPistas:\033[0m\n"
    printf "  • Cuando el disco se agota, los errores no siempre son explícitos\n"
    printf "  • df y du revelan más que muchos mensajes de error\n"
    printf "  • Algunos directorios crecen lentamente hasta convertirse en un problema\n"
    printf "  • Liberar espacio es solo parte de la solución; prevenir es igual de importante\n\n"

    printf "\033[1;36m========================================================\033[0m\n"
    printf "\nEjecutar con --apply para inyectar la condición de presión de disco...\n"
}







# ==============================================================================
# Función: Aplicar fallo para LAB J02 (versión rápida)
# ==============================================================================

apply_lab() {
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
