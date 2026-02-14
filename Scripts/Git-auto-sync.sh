#!/bin/bash
#
# Script: git-auto-sync.sh
# Descripción: Sincroniza automáticamente un repositorio Git con GitHub
# Ejecutado por: systemd timer cada 5 minutos
# Acciones: stash → pull(rebase) → pop(stash) → add → commit → push
#

# Variables de configuración
REPO_DIR="$HOME/Labs"              # CAMBIA ESTO al path de tu repo clonado
LOG_FILE="$HOME/scripts/git-sync.log"
MAX_LOG_LINES=500
REMOTE_NAME="${REMOTE_NAME:-origin}"  # Soporte para remote personalizado
BRANCH_NAME="${BRANCH_NAME:-$(git branch --show-current 2>/dev/null || echo main)}"

# Función para logging con timestamp
log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local hostname=$(hostname)
    echo "[$timestamp] [$hostname] $1" >> "$LOG_FILE"
}

# Función para rotar logs si crecen mucho
rotate_log() {
    if [ -f "$LOG_FILE" ]; then
        local line_count=$(wc -l < "$LOG_FILE")
        if [ "$line_count" -gt "$MAX_LOG_LINES" ]; then
            tail -n 250 "$LOG_FILE" > "$LOG_FILE.tmp"
            mv "$LOG_FILE.tmp" "$LOG_FILE"
            log_message "INFO: Log rotado (excedió $MAX_LOG_LINES líneas)"
        fi
    fi
}

# Rotar log al inicio
rotate_log

# Verificar que el directorio existe
if [ ! -d "$REPO_DIR" ]; then
    log_message "ERROR: El directorio $REPO_DIR no existe"
    exit 1
fi

# Cambiar al directorio del repositorio
cd "$REPO_DIR" || {
    log_message "ERROR: No se pudo acceder a $REPO_DIR"
    exit 1
}

# Verificar que es un repositorio git
if [ ! -d .git ]; then
    log_message "ERROR: $REPO_DIR no es un repositorio Git"
    exit 1
fi

log_message "INFO: Iniciando sincronización completa ($REMOTE_NAME/$BRANCH_NAME)..."

# PASO 0: Stash cambios sin commitear si existen
STASHED=false
if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
    log_message "WARNING: Cambios sin commitear detectados, haciendo stash..."
    if git stash push -m "Auto-stash $(date '+%Y-%m-%d %H:%M:%S')" 2>&1 | tee -a "$LOG_FILE"; then
        STASHED=true
        log_message "SUCCESS: Cambios guardados en stash"
    else
        log_message "ERROR: Fallo al hacer stash"
        exit 1
    fi
fi

# PASO 1: Pull con rebase (traer cambios remotos)
log_message "INFO: git pull --rebase $REMOTE_NAME $BRANCH_NAME"
if OUTPUT=$(git pull --rebase "$REMOTE_NAME" "$BRANCH_NAME" 2>&1); then
    echo "$OUTPUT" >> "$LOG_FILE"
    log_message "SUCCESS: Git pull con rebase completado"
    
    # Recuperar stash si existe
    if [ "$STASHED" = true ] && [ -n "$(git stash list 2>/dev/null | grep 'Auto-stash')" ]; then
        log_message "INFO: Recuperando stash..."
        if git stash pop 2>&1 | tee -a "$LOG_FILE"; then
            log_message "SUCCESS: Stash recuperado correctamente"
        else
            log_message "WARNING: Fallo al recuperar stash (posibles conflictos manuales)"
        fi
    fi
else
    echo "$OUTPUT" >> "$LOG_FILE"
    log_message "ERROR: Fallo al hacer git pull --rebase"
    exit 1
fi


# PASO 2: Verificar si hay cambios para commitear
if [[ -n $(git status -s 2>/dev/null) ]]; then
    log_message "INFO: Cambios detectados, agregando archivos..."
    
    # Agregar todos los archivos modificados
    if git add -A 2>&1 | tee -a "$LOG_FILE"; then
        log_message "SUCCESS: Archivos agregados al staging"
        
        # PASO 3: Commit
        COMMIT_MSG="Auto-sync: $(date '+%Y-%m-%d %H:%M:%S') desde $(hostname)"
        log_message "INFO: Creando commit: $COMMIT_MSG"
        
        if git commit -m "$COMMIT_MSG" 2>&1 | tee -a "$LOG_FILE"; then
            log_message "SUCCESS: Commit creado exitosamente"
            
            # PASO 4: Push (subir cambios)
            log_message "INFO: git push $REMOTE_NAME $BRANCH_NAME"
            if git push "$REMOTE_NAME" "$BRANCH_NAME" 2>&1 | tee -a "$LOG_FILE"; then
                log_message "🎉 SUCCESS: ✓ Sincronización completa exitosa!"
            else
                log_message "ERROR: Fallo al hacer git push"
                exit 1
            fi
        else
            log_message "ERROR: Fallo al crear commit (posiblemente nada que commitear)"
            exit 1
        fi
    else
        log_message "ERROR: Fallo al agregar archivos"
        exit 1
    fi
else
    log_message "INFO: ✅ No hay cambios locales para sincronizar"
fi

log_message "INFO: Ciclo de sincronización completado exitosamente"
exit 0
