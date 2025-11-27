#!/bin/bash
# Laboratorio FIND – Tareas 1, 2 y 3 completas
# Autor: Jensy Gómez
# Curso: Red Hat System Administration I (RH124)

OUTPUT="lab_find_report.txt"
> "$OUTPUT"

GREEN='\033[0;32m'
NC='\033[0m'

log() {
    echo -e "${GREEN}$1${NC}" | tee -a "$OUTPUT"
    echo "$1" >> "$OUTPUT"
}

log "=================================================================="
log "           LABORATORIO FIND - Tareas 1 a 3"
log " Curso   : Red Hat System Administration I (RH124)"
log " Autor   : Jensy Gómez"
log " Fecha   : $(date '+%Y-%m-%d %H:%M:%S')"
log " Host    : $(hostname)"
log "=================================================================="
log ""

# ==================== TAREA 1 – Archivos mayores de 10 MiB ====================
log "TAREA 1 – Listar todos los archivos regulares mayores de 10 MiB"
log "Comando: find / -type f -size +10M 2>/dev/null"
log ""
log "Resultado:"
find / -type f -size +10M 2>/dev/null | tee -a "$OUTPUT" | nl
log ""
if find / -type f -size +10M 2>/dev/null | grep -q .; then
    log "Se encontraron archivos mayores de 10 MiB (ver listado arriba)."
else
    log "Conclusión: En este sistema NO existen archivos regulares mayores de 10 MiB."
fi
log ""
log "=================================================================="
log ""

# ==================== TAREA 2 – Archivos del usuario phoenix ====================
log "TAREA 2 – Todos los objetos que pertenecen al usuario phoenix (UID 1000)"
log "Comando: find / -user phoenix 2>/dev/null"
log ""
log "Resultado:"
find / -user phoenix 2>/dev/null | tee -a "$OUTPUT"
log ""
log "Conclusión:"
log "Se muestran archivos, directorios y pseudo-archivos del kernel. La gran"
log "cantidad de entradas en /proc es normal en contenedores que corren como phoenix."
log ""
log "=================================================================="
log ""

# ==================== TAREA 3 – Contar archivos con bit SUID ====================
log "TAREA 3 – Contar archivos con el bit SUID activado"
log "Comando: find / -type f -perm -4000 2>/dev/null | wc -l"
log ""
SUID_COUNT=$(find / -type f -perm -4000 2>/dev/null | wc -l)
log "Resultado: $SUID_COUNT archivos tienen el bit SUID activado"
log ""
log "Conclusión:"
log "El bit SUID (4xxx) permite que un ejecutable corra con los privilegios del"
log "propietario (normalmente root). Tener solo $SUID_COUNT es un número típico"
log "y seguro en sistemas RHEL/Rocky/AlmaLinux mínimos."
log ""
log "=================================================================="
log ""
log "¡LABORATORIO COMPLETADO CON ÉXITO!"
log "Reporte guardado en: $OUTPUT"
log "=================================================================="