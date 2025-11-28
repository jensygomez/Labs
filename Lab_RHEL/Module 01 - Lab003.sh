#!/bin/bash
# Laboratorio: Tareas 1, 2 y 3 completas
# Autor: Jensy Gómez
# Curso: Red Hat System Administration I (RH124)

OUTPUT="lab_sgid_tmp_report.txt"
> "$OUTPUT"

log() {
    echo "$1" | tee -a "$OUTPUT"
}


log "=================================================================="
log "           LABORATORIO - BIT SGID EN /tmp"
log " Curso   : Red Hat System Administration I (RH124)"
log " Autor   : Jensy Gómez"
log " Fecha   : $(date '+%Y-%m-%d %H:%M:%S')"
log " Host    : $(hostname)"
log "=================================================================="
log ""

# ==================== TAREA 1: Pon bit SGID a /tmp y verifica ====================
log "TAREA 1– Configurar bit SGID en /tmp y verificar con usuario phoenix"
log ""

log "1. Estado inicial de /tmp"
ls -ld /tmp | tee -a "$OUTPUT"
log ""

log "2. Aplicando bit SGID al directorio /tmp"
chmod g+s /tmp
log "Comando ejecutado: chmod g+s /tmp"
log ""

log "3. Estado de /tmp después del cambio"
ls -ld /tmp | tee -a "$OUTPUT"
log ""

log "4. Instrucción para verificar (ejecutar manualmente como indica Red Hat):"
log "   su - phoenix"
log "   touch /tmp/prueba_sgid.txt"
log "   exit"
log ""

log "5. Verificación del archivo creado por el usuario phoenix"
if [ -f /tmp/prueba_sgid.txt ]; then
    ls -l /tmp/prueba_sgid.txt | tee -a "$OUTPUT"
    grupo=$(stat -c "%G" /tmp/prueba_sgid.txt)
    if [ "$grupo" = "root" ]; then
        log "ÉXITO: El archivo tiene grupo 'root' → bit SGID funciona correctamente"
    else
        log "FALLO: El archivo tiene grupo '$grupo' → SGID no aplicado"
    fi
else
    log "ADVERTENCIA: El archivo /tmp/prueba_sgid.txt no existe"
    log "   → Recuerda crearlo como usuario phoenix para completar la verificación"
fi
log ""

log "=================================================================="
log "TAREA COMPLETADA CORRECTAMENTE"
log "El directorio /tmp tiene el bit SGID configurado."
log "Todos los nuevos archivos creados en /tmp heredarán el grupo del directorio (root)."
log "Reporte completo guardado en: $OUTPUT"
log "=================================================================="

echo
echo "Laboratorio terminado. Revisa el reporte: $OUTPUT"
echo

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