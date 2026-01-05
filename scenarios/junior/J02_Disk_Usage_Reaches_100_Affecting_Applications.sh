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






 apply_lab() {
    local LOG="/var/log/lab_j02.log"
    local BACKUP="/root/lab_j02_backup"
    local TARGET_USAGE=88           # A 88% (¡CRÍTICO!)
    local MARGIN_MB=300             # AUMENTADO margen de seguridad
    local SAFETY_LIMIT_MB=800       # MÁXIMO por archivo individual
    local MIN_FREE_AFTER_MB=600     # MÍNIMO a dejar libre después
    
    {
        echo "========================================"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB J02-Protected: Inyección distribuida y SEGURA"
        echo "========================================"
    } >> "$LOG"

    # Validación root
    [ "$EUID" -ne 0 ] && { 
        echo "ERROR: Ejecutar como root" >> "$LOG"
        echo "Este script debe ejecutarse como root." >&2
        return 1 
    }

    # ------------------------------------------------------------------
    # VERIFICACIÓN DE SEGURIDAD INICIAL (NUEVO)
    # ------------------------------------------------------------------
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Realizando verificaciones de seguridad..." >> "$LOG"
    
    # Obtener métricas actuales
    local TOTAL_KB USED_KB FREE_KB CURRENT_USAGE
    read TOTAL_KB USED_KB FREE_KB <<< $(df -k / | awk 'NR==2 {print $2" "$3" "$4}')
    CURRENT_USAGE=$(( USED_KB * 100 / TOTAL_KB ))
    local FREE_MB=$(( FREE_KB / 1024 ))
    
    {
        echo "Estado inicial del sistema:"
        echo "  Uso actual: ${CURRENT_USAGE}%"
        echo "  Espacio libre: ${FREE_MB} MB"
        echo "  Total espacio: $((TOTAL_KB/1024)) MB"
        echo ""
        echo "Límites de seguridad activados:"
        echo "  Objetivo máximo: ${TARGET_USAGE}%"
        echo "  Margen de seguridad: ${MARGIN_MB} MB"
        echo "  Límite por archivo: ${SAFETY_LIMIT_MB} MB"
        echo "  Mínimo libre final: ${MIN_FREE_AFTER_MB} MB"
    } >> "$LOG"
    
    # VERIFICACIÓN 1: ¿Ya estamos en zona de peligro?
    if [ "$CURRENT_USAGE" -ge 90 ]; then
        echo "❌ ABORTADO: Sistema ya al ${CURRENT_USAGE}% (zona de peligro)" >> "$LOG"
        echo "⚠️  ERROR: El sistema ya tiene presión crítica de disco. No se inyectará más." >&2
        echo "   Uso actual: ${CURRENT_USAGE}% | Libre: ${FREE_MB} MB" >&2
        return 1
    fi
    
    # VERIFICACIÓN 2: ¿Tenemos suficiente espacio para operar?
    local REQUIRED_FREE=$(( MIN_FREE_AFTER_MB + MARGIN_MB ))
    if [ "$FREE_MB" -lt "$REQUIRED_FREE" ]; then
        echo "❌ ABORTADO: Espacio insuficiente para operar de forma segura" >> "$LOG"
        echo "⚠️  ERROR: Solo ${FREE_MB} MB libres (se requieren ${REQUIRED_FREE} MB)" >> "$LOG"
        echo "⚠️  No hay suficiente espacio libre para operar de forma segura." >&2
        return 1
    fi
    
    # Backup (seguro, limitado)
    mkdir -p "$BACKUP"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Creando backup limitado..." >> "$LOG"
    find /var/log -type f -name "*.lab_*" -size -10M -exec cp --parents {} "$BACKUP" \; 2>/dev/null | head -5 >> "$LOG"

    # ------------------------------------------------------------------
    # 1) Distribuir el consumo con LÍMITES DE SEGURIDAD
    # ------------------------------------------------------------------
    if [ "$CURRENT_USAGE" -lt "$TARGET_USAGE" ]; then
        local NEED_KB NEED_MB
        NEED_KB=$(( (TARGET_USAGE * TOTAL_KB / 100) - USED_KB ))
        NEED_MB=$(( (NEED_KB / 1024) - MARGIN_MB ))
        
        # APLICAR LÍMITE DE SEGURIDAD AL TOTAL
        local MAX_SAFE_MB=$(( FREE_MB - MIN_FREE_AFTER_MB ))
        if [ "$NEED_MB" -gt "$MAX_SAFE_MB" ]; then
            echo "⚠️  AJUSTADO: ${NEED_MB}MB excede límite seguro. Reducido a ${MAX_SAFE_MB}MB" >> "$LOG"
            NEED_MB="$MAX_SAFE_MB"
        fi
        
        if [ "$NEED_MB" -gt 100 ]; then  # Solo si hace falta > 100MB (aumentado)
            {
                echo "========================================"
                echo "Creando ${NEED_MB}MB distribuidos (CON LÍMITES DE SEGURIDAD)..."
                echo "========================================"
            } >> "$LOG"
            
            # Array de directorios "plausibles" pero SEGUROS
            local DIRS=(
                "/var/log/application"
                "/var/tmp"
                "/tmp"
                "/var/cache/temp"
                "/opt/backups"
            )
            
            # Patrones de nombres "creíbles"
            local PATTERNS=(
                "debug_dump"
                "session_data" 
                "cache_blob"
                "temp_export"
                "backup_tmp"
                "metrics_data"
                "trace_buffer"
            )
            
            local EXTENSIONS=(".dat" ".tmp" ".cache" ".bin" ".data" "")
            
            # Dividir en 3-6 archivos (reducido de 4-8)
            local NUM_FILES=$((3 + RANDOM % 4))
            local MB_PER_FILE=$(( NEED_MB / NUM_FILES ))
            
            # APLICAR LÍMITE POR ARCHIVO
            if [ "$MB_PER_FILE" -gt "$SAFETY_LIMIT_MB" ]; then
                MB_PER_FILE="$SAFETY_LIMIT_MB"
                NUM_FILES=$(( (NEED_MB / SAFETY_LIMIT_MB) + 1 ))
                echo "⚠️  Límite por archivo activado: máximo ${SAFETY_LIMIT_MB}MB cada uno" >> "$LOG"
            fi
            
            local REMAINING_MB=$(( NEED_MB % NUM_FILES ))
            
            for ((i=1; i<=NUM_FILES; i++)); do
                # ------------------------------------------------------------------
                # VERIFICACIÓN DE SEGURIDAD ANTES DE CADA ARCHIVO (NUEVO)
                # ------------------------------------------------------------------
                local CURRENT_FREE_MB=$(df -m / | awk 'NR==2 {print $4}')
                if [ "$CURRENT_FREE_MB" -lt "$MIN_FREE_AFTER_MB" ]; then
                    echo "🛑 ALTO DE EMERGENCIA: Solo ${CURRENT_FREE_MB}MB libres. Parando creación." >> "$LOG"
                    echo "⚠️  Parada de seguridad activada. Se crearon $((i-1)) de ${NUM_FILES} archivos." >> "$LOG"
                    break
                fi
                
                # Selección aleatoria
                local DIR="${DIRS[$RANDOM % ${#DIRS[@]}]}"
                local PATTERN="${PATTERNS[$RANDOM % ${#PATTERNS[@]}]}"
                local EXT="${EXTENSIONS[$RANDOM % ${#EXTENSIONS[@]}]}"
                local TIMESTAMP=$(date +%s%N | cut -c1-13)
                
                # Tamaño variable ±20% (reducido de ±30%)
                local FILE_MB="$MB_PER_FILE"
                local VARIATION=$(( FILE_MB / 5 ))  # 20%
                FILE_MB=$(( FILE_MB + (RANDOM % (VARIATION * 2)) - VARIATION ))
                
                # Ajustar último archivo con resto
                [ $i -eq $NUM_FILES ] && FILE_MB=$((FILE_MB + REMAINING_MB))
                
                # VERIFICAR LÍMITE POR ARCHIVO (nuevamente)
                if [ "$FILE_MB" -gt "$SAFETY_LIMIT_MB" ]; then
                    echo "⚠️  Archivo ${i} ajustado: ${FILE_MB}MB → ${SAFETY_LIMIT_MB}MB (límite)" >> "$LOG"
                    REMAINING_MB=$(( REMAINING_MB + (FILE_MB - SAFETY_LIMIT_MB) ))
                    FILE_MB="$SAFETY_LIMIT_MB"
                fi
                
                # Nombre "creíble"
                local FILENAME="${PATTERN}_${TIMESTAMP}_${i}${EXT}"
                local FILEPATH="${DIR}/${FILENAME}"
                
                # Crear directorio si no existe
                mkdir -p "$DIR"
                
                {
                    echo "📁 Creando archivo ${i}/${NUM_FILES}:"
                    echo "   Ruta: ${FILEPATH}"
                    echo "   Tamaño: ${FILE_MB} MB"
                    echo "   Libre actual: ${CURRENT_FREE_MB} MB"
                } >> "$LOG"
                
                # Crear archivo CON VERIFICACIÓN DE ERROR
                if ! dd if=/dev/urandom of="$FILEPATH" bs=4M count=$(( (FILE_MB + 3) / 4 )) status=none 2>>"$LOG"; then
                    echo "❌ ERROR dd en ${FILEPATH}. Continuando con siguiente..." >> "$LOG"
                    rm -f "$FILEPATH" 2>/dev/null
                    continue
                fi
                
                # 30% de probabilidad de comprimirlo
                if [ $((RANDOM % 100)) -lt 30 ]; then
                    if gzip -f "$FILEPATH" 2>/dev/null; then
                        FILEPATH="${FILEPATH}.gz"
                        echo "   ✅ Comprimido a ${FILEPATH}.gz" >> "$LOG"
                    fi
                fi
                
                # 20% de probabilidad de cambiar permisos
                if [ $((RANDOM % 100)) -lt 20 ]; then
                    chown nobody:nobody "$FILEPATH" 2>/dev/null || true
                fi
                
                echo "   ✅ Creado exitosamente" >> "$LOG"
                
                # Pequeña pausa y verificación POST-creación
                sleep 0.3
                
                # Verificar espacio después de crear
                local NEW_FREE_MB=$(df -m / | awk 'NR==2 {print $4}')
                echo "   📊 Libre después: ${NEW_FREE_MB} MB" >> "$LOG"
                
                # Si estamos cerca del límite, reducir velocidad
                if [ "$NEW_FREE_MB" -lt $((MIN_FREE_AFTER_MB * 2)) ]; then
                    sleep 1
                    echo "   ⚠️  Espacio bajo, aumentando pausa..." >> "$LOG"
                fi
            done
        else
            echo "ℹ️  No se requiere creación (${NEED_MB}MB < 100MB mínimo)" >> "$LOG"
        fi
    else
        echo "ℹ️  Ya cerca del objetivo (${CURRENT_USAGE}% >= ${TARGET_USAGE}%)" >> "$LOG"
    fi
    
    # ------------------------------------------------------------------
    # 2) Logs "legítimos" con LÍMITES DE SEGURIDAD
    # ------------------------------------------------------------------
    {
        echo ""
        echo "========================================"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Simulando crecimiento controlado de logs..."
        echo "========================================"
    } >> "$LOG"
    
    # Directorios de logs reales (SIN inflar /var/log/messages crítico)
    local LOG_TARGETS=(
        "/var/log/application"
        "/var/log/httpd/access_log"
        "/var/log/httpd/error_log"
    )
    
    for logfile in "${LOG_TARGETS[@]}"; do
        if [ -f "$logfile" ] || [ "$logfile" = "/var/log/application" ]; then
            # CREAR archivo si no existe (solo para /var/log/application)
            if [ "$logfile" = "/var/log/application" ] && [ ! -f "$logfile" ]; then
                mkdir -p "/var/log/application"
                logfile="/var/log/application/app.log"
                touch "$logfile"
            fi
            
            # Tamaño MUCHO más pequeño (5-15MB en lugar de 50-200MB)
            local GROWTH=$((5 + RANDOM % 10))
            
            # Verificar espacio ANTES de añadir logs
            local FREE_NOW=$(df -m / | awk 'NR==2 {print $4}')
            if [ "$FREE_NOW" -lt "$MIN_FREE_AFTER_MB" ]; then
                echo "⚠️  Saltando logs por espacio bajo (${FREE_NOW}MB < ${MIN_FREE_AFTER_MB}MB)" >> "$LOG"
                break
            fi
            
            {
                # Añadir líneas (MUCHAS MENOS)
                for ((j=0; j<GROWTH*10; j++)); do  # 10 líneas por MB (no 100)
                    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Simulated app log entry $(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 8 | head -1)" \
                        >> "$logfile" 2>/dev/null || break
                done
                
                echo "  📝 Expandido: ${logfile} (+${GROWTH}MB)" >> "$LOG"
            } 2>/dev/null
        fi
    done
    
    # ------------------------------------------------------------------
    # 3) Paquetes "olvidados" con LÍMITES
    # ------------------------------------------------------------------
    {
        echo ""
        echo "========================================"
        echo "[$(date '+%m-%d %H:%M:%S')] Creando caché de paquetes residual (LIMITADO)..."
        echo "========================================"
    } >> "$LOG"
    
    # Solo UN directorio (no 4)
    local PKG_DIRS=("/var/cache/dnf/lab_cache")
    
    for pkgdir in "${PKG_DIRS[@]}"; do
        mkdir -p "$pkgdir"
        
        # Solo 2-3 archivos (no 5-10)
        local PKG_FILES=$((2 + RANDOM % 2))
        
        for ((p=1; p<=PKG_FILES; p++)); do
            # Verificar espacio ANTES de cada paquete
            local FREE_NOW=$(df -m / | awk 'NR==2 {print $4}')
            if [ "$FREE_NOW" -lt "$MIN_FREE_AFTER_MB" ]; then
                echo "⚠️  Saltando paquetes por espacio bajo" >> "$LOG"
                break 2
            fi
            
            # Tamaño PEQUEÑO (5-20MB en lugar de 10-90MB)
            local PKG_SIZE=$((5 + RANDOM % 15))
            local PKG_NAME="lab_cache_$(uname -r | cut -d- -f1)-${p}.$(date +%Y%m%d).rpm"
            
            if dd if=/dev/zero of="${pkgdir}/${PKG_NAME}" bs=1M count="$PKG_SIZE" status=none 2>/dev/null; then
                echo "  📦 Creado: ${PKG_NAME} (${PKG_SIZE}MB)" >> "$LOG"
            fi
            sleep 0.2
        done
    done
    
    # ------------------------------------------------------------------
    # 4) VERIFICACIÓN FINAL CON PROTECCIÓN
    # ------------------------------------------------------------------
    read TOTAL_KB USED_KB FREE_KB <<< $(df -k / | awk 'NR==2 {print $2" "$3" "$4}')
    CURRENT_USAGE=$(( USED_KB * 100 / TOTAL_KB ))
    local FINAL_FREE_MB=$(( FREE_KB / 1024 ))
    
    # VERIFICACIÓN FINAL DE SEGURIDAD
    local SAFETY_STATUS="✅"
    if [ "$FINAL_FREE_MB" -lt "$MIN_FREE_AFTER_MB" ]; then
        SAFETY_STATUS="⚠️ "
        echo "ALERTA: Espacio libre final (${FINAL_FREE_MB}MB) por debajo del mínimo (${MIN_FREE_AFTER_MB}MB)" >> "$LOG"
    fi
    
    if [ "$CURRENT_USAGE" -gt 90 ]; then
        SAFETY_STATUS="🔴"
        echo "ALERTA CRÍTICA: Uso final (${CURRENT_USAGE}%) supera el 90%" >> "$LOG"
    fi
 }