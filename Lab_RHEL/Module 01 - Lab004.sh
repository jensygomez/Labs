#!/bin/bash
# Laboratorio: Día 04 - Enlaces duros y simbólicos (RHCSA)
# Autor: Jensy Gómez
# Curso: Preparación EX200 - 30 días de fuego
# Objetivo: Dominar hard links, symbolic links y detección de enlaces rotos

OUTPUT="/root/lab_dia04_enlaces_report.txt"
> "$OUTPUT"

log() {
    echo "$1" | tee -a "$OUTPUT"
}

log "=================================================================="
log "           LABORATORIO DÍA 04 - ENLACES DUROS Y SIMBÓLICOS"
log " Curso   : Preparación intensiva RHCSA (EX200)"
log " Autor   : Jensy Gómez"
log " Fecha   : $(date '+%Y-%m-%d %H:%M:%S')"
log " Host    : $(hostname)"
log "=================================================================="
log ""

# ==================== TAREA 1: Crear 3 enlaces duros a /etc/passwd ====================
log "TAREA 1 - Crear 3 enlaces duros a /etc/passwd en /root"
log "Inodo original de /etc/passwd:"
ls -i /etc/passwd 2>/dev/null | tee -a "$OUTPUT"

log "Creando los 3 hard links..."
ln /etc/passwd /root/passwd_link1
ln /etc/passwd /root/passwd_link2
ln /etc/passwd /root/passwd_link3

log "Verificación de inodos (deben ser idénticos):"
ls -i /etc/passwd      /root/passwd_link* 2>/dev/null | tee -a "$OUTPUT"

log "Conclusión Tarea 1:"
log "   → Los 4 caminos tienen el MISMO inodo → son el mismo archivo físico."
log "   → Modificar cualquiera afecta a /etc/passwd (¡cuidado en producción!)"
log "   → Los hard links NO pueden cruzar filesystems ni apuntar a directorios."
log "   TAREA 1 COMPLETADA ✓"
log ""

# ==================== TAREA 2: Crear symlink roto y encontrarlo con find ====================
log "TAREA 2 - Crear un symbolic link roto a propósito y detectarlo"
log "Creando symlink que apunta a archivo inexistente..."
ln -s /archivo/que/no/existe/nunca/jamas.txt /root/symlink_roto

log "Estado del symlink creado:"
ls -l /root/symlink_roto 2>/dev/null | tee -a "$OUTPUT"

log "Búsqueda con find de symlinks rotos solo en /root:"
find /root -type l ! -exec test -e {} \; -print 2>/dev/null | tee -a "$OUTPUT"

log "Conclusión Tarea 2:"
log "   → -type l        → solo symbolic links"
log "   → ! -exec test -e {} \\; → el destino NO existe → enlace roto"
log "   → Esta combinación es la forma estándar en RHCSA para detectar dangling symlinks"
log "   TAREA 2 COMPLETADA ✓"
log ""

# ==================== TAREA 3: Contar todos los symlinks rotos del sistema ====================
log "TAREA 3 - Contar enlaces simbólicos rotos en TODO el sistema"
log "Ejecutando búsqueda global (ignorando errores de permisos y filesystems virtuales)..."
BROKEN_COUNT=$(find / -type l ! -exec test -e {} \; -print 2>/dev/null | wc -l)
log "Número total de symlinks rotos encontrados: $BROKEN_COUNT"

log "Comando exacto utilizado (para el examen):"
log "find / -type l ! -exec test -e {} \\; -print 2>/dev/null | wc -l"
log ""

log "Conclusión Tarea 3:"
log "   → En sistemas reales es común tener cientos o miles de symlinks rotos"
log "     (paquetes desinstalados, actualizaciones, etc.)"
log "   → Este comando es típico en auditorías de seguridad y troubleshooting RHCSA"
log "   → Redirigir errores con 2>/dev/null evita ruido de /proc, /sys, permisos denegados"
log "   TAREA 3 COMPLETADA ✓"
log ""

log "=================================================================="
log "           DÍA 04 COMPLETADO AL 100% - ¡ENLACES DOMINADOS!"
log "   Hard links   → mismo inodo, mismo archivo"
log "   Symlinks     → puntero a ruta, pueden romperse"
log "   find roto    → -type l ! -exec test -e {} \\;"
log "=================================================================="

echo ""
echo "¡DÍA 04 TERMINADO! Reporte generado en: $OUTPUT"
echo "Marca tu lista: DÍA 04 [✓] – Enlaces duros y simbólicos"
echo ""

# Opcional: limpiar lo que creamos (descomenta si quieres)
# rm -f /root/passwd_link* /root/symlink_roto

exit 0