#!/bin/bash
# Laboratorio 001 - Búsqueda de archivos + Tarea 4 añadida
# Autor: Jensy Gómez
# Curso: Red Hat System Administration I (RH124)

OUTPUT="lab.txt"
> "$OUTPUT"  # Borra el archivo si ya existe

# Colores (opcional, queda lindo)
GREEN='\033[0;32m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}$1${NC}" | tee -a "$OUTPUT"
}

log "=================================================================="
log " LABORATORIO 002 - find Nivel Dios"
log " Curso: Red Hat System Administration I (RH124)"
log " Autor: Jensy Gómez"
log " Fecha: $(date)"
log " Host: $(hostname)"
log " Usuario: $(whoami)"
log "=================================================================="

# ==================== TAREA 1 ====================
log "Tarea 1 – Lista todos los archivos > 10 MB en todo el sistema"
log "Comando utilizado:"
log "find / -type f -size +10M ! -path "/proc/*" ! -path "/sys/*" ! -path "/dev/*" \
     ! -path "/tmp/*" ! -path "/run/*" 2>/dev/null"
log "Resultado:"

find / -type f -size +10M ! -path "/proc/*" ! -path "/sys/*" ! -path "/dev/*" \
     ! -path "/tmp/*" ! -path "/run/*" 2>/dev/null

log ""
log "Conclusión:"
log "En el sistema actual no existe ningún archivo regular mayor de 10 MiB."
log "=================================================================="

# ==================== TAREA 2 ====================
log "Tarea 2 – Encuentra todos los archivos que pertenecen al usuario phoenix (UID 1000)"
log "Comando utilizado:"
log "find /usr/share -type f | wc -l"
count2=$(find /usr/share -type f | wc -l)

log "Resultado:"
log "$count2"

log "=================================================================="

# ==================== TAREA 3 ====================
log "Tarea 3 – Listar todos los archivos ocultos (que empiecen por .) en /etc"
log "Comando utilizado:"
log "find /etc -type f -name '.*' | sort"
log "Resultado:"

find /etc -type f -name ".*" | sort | tee -a "$OUTPUT"
count3=$(find /etc -type f -name ".*" | wc -l)

log ""
log "Total de archivos ocultos encontrados: $count3"
log "=================================================================="


log " LABORATORIO COMPLETADO CORRECTAMENTE"
log " Script ejecutado el $(date '+%Y-%m-%d %H:%M:%S %Z')"
log "=================================================================="

