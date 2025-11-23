#!/bin/bash

# ===================================
# TechNova - Lab 2 - Verificación del Sistema
# Autor: Jensy Gómez
# ===================================

NOTES="/root/lab2-notes.txt"
LARGEBINS="/root/lab2-largebins.txt"
REAL_USER="${SUDO_USER:-${USER:-${LOGNAME}}}"

# -------------------------------------------------
# Funciones SILENCIOSAS (solo escriben en el archivo)
# -------------------------------------------------
log() {
    echo -e "\n[+] $1" >> "$NOTES"
    echo "----------------------------------------" >> "$NOTES"
    echo "" >> "$NOTES"
}

run() {
    echo "\$ $*" >> "$NOTES"
    "$@" 2>&1 >> "$NOTES"
    echo "" >> "$NOTES"
}

# ===================================
# INICIO DEL SCRIPT
# ===================================

> "$NOTES"   # Limpiar archivo de notas

# Encabezado (opcional pero queda pro)
log "TechNova - Laboratorio 2 - Verificación del Sistema"
log "Autor: Jensy Gómez"
log "Fecha y hora: $(date '+%d-%m-%Y %H:%M:%S')"
log "Host: $(hostname) | Usuario real: $SUDO_USER (o $(whoami) si no hay sudo)"

# ===================================
# Ahora sí: todo funciona perfecto
# ===================================

log "====Ejercicio 1. Validación inicial del sistema ===="

log "Mostrando el directorio Actual"
run pwd

log "Objetivo 1.1 -  Cambiar al directorio /usr/share usando sólo rutas absolutas."
run cd /usr/share

log "Me cambié al directorio /usr/share usando rutas absolutas"
run pwd

log "Objetivo 1.2 - Regreso al HOME del usuario real ($REAL_USER) usando ruta relativa"
run cd ../../home/$REAL_USER

log "==== Ejercicio 2. Estructura del sistema ===="
log "Objetivo 2.1 - Listar el contenido de /etc mostrando permisos, dueño y tamaño."
run ls -lh /etc | heaad -10

log "Objetivo 2.2 - Buscar dentro de /etc un archivo que contenga la palabra “release”."
run find /etc -type f -name "*release*" 2>/dev/null

log "Objetivo 2.2 - Muestro el contenido del primer archivo encontrado"
# El truco sin condicional: tomamos solo la primera línea que encuentre find
run find /etc -type f -name "*release*" 2>/dev/null | head -1 | xargs cat

log "===== RUTA COMPLETA DEL ARCHIVO ENCONTRADO (para entrega) ====="
# Aquí está lo que pedías: mostramos y guardamos la ruta completa sin if
run echo "Ruta completa guardada por el comando de arriba:"
run find /etc -type f -name "*release*" 2>/dev/null | head -1



# ===================================
# AL FINAL: mostramos todo el reporte bonito de una vez
# ===================================
echo
echo "=========================================="
echo "   LABORATORIO 2 COMPLETADO"
echo "   Mostrando reporte generado..."
echo "=========================================="
echo
cat "$NOTES"
echo
echo "Reporte también guardado en: $NOTES"
echo


