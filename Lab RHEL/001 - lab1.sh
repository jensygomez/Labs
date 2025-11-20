#!/bin/bash

# ============================================
# LABORATORIO LAB1 – SCRIPT OPTIMIZADO
# Autor: Jensy Gomez
# ============================================

NOTES="/root/lab-notes.txt"
TARGET_USER="${SUDO_USER:-$USER}"

# -------------------------
# Funciones reutilizables
# -------------------------

# Función para registrar texto en pantalla y archivo
log() {
    echo "$1" | tee -a "$NOTES"
}

# Línea en blanco (para no repetir echo "")
blank() {
    echo "" | tee -a "$NOTES"
}

# --------------------------------------------
# 1.1 Ruta absoluta inicial
# --------------------------------------------
log "1.1 Esta es la ruta absoluta inicial"
pwd | tee -a "$NOTES"
blank

# --------------------------------------------
# 1.2 Cambiar a /usr/share
# --------------------------------------------
cd /usr/share
log "Estoy en el directorio $(pwd) gracias a que usé la ruta absoluta cd /usr/share"
blank

# --------------------------------------------
# 1.3 Volver al HOME con ruta relativa
# --------------------------------------------
cd ../../home/$TARGET_USER
log "Regresé a mi $(pwd), usando la ruta relativa cd ../../home/$TARGET_USER"
blank

# --------------------------------------------
# 2.1 Listar contenido /etc
# --------------------------------------------
ls -l /etc | head -n 10 | tee -a "$NOTES"
log "2.1 Listado del contenido del directorio /etc:"
blank
log "Usé el comando ls -l /etc para listar el contenido de este directorio"
blank

# --------------------------------------------
# 2.2 Buscar archivo con 'release'
# --------------------------------------------
RELEASE_FILE=$(find /etc -name "*release*")
log "2.2 Archivos encontrados que contienen la palabra 'release':"
log "$RELEASE_FILE"
blank

# 2.3 Registrar rutas completas
log "2.3 Registrando rutas completas de archivos 'release':"
log "$RELEASE_FILE"
blank

# --------------------------------------------
# 3.1 Archivos modificados últimas 24h
# --------------------------------------------
FIND_FILES=$(find /var/log -type f -mtime -1)
log "3.1 Archivos modificados en las últimas 24 horas en /var/log:"
log "$FIND_FILES"
blank

# --------------------------------------------
# 3.2 5 archivos más recientes
# --------------------------------------------
RECENT_5_FILES=$(find /var/log -type f -printf "%T@ %p\n" | sort -nr | head -n 5)
log "3.2 Los 5 archivos más recientes en /var/log son:"
log "$RECENT_5_FILES"
blank

# 3.3 Guardar salida exacta
echo "$RECENT_5_FILES" | tee /root/lastlogs.txt
blank

# --------------------------------------------
# 4.1 Buscar archivo llamado passwd
# --------------------------------------------
log "Buscando en el directorio / un archivo llamado passwd"
PASSWORD_FILE=$(find / -type f -iname "passwd" 2>/dev/null)
log "$PASSWORD_FILE"
blank

# --------------------------------------------
# 4.2 Archivos .conf > 20K
# --------------------------------------------
log "Buscando en /etc archivos .conf que pesen más de 20k"
CONF_FILES=$(find /etc -type f -name "*.conf" -size +20k 2>/dev/null)
log "$CONF_FILES"
blank

# 4.3 Contar archivos encontrados
CONF_COUNT=$(echo "$CONF_FILES" | wc -l)
log "La cantidad de archivos .conf que pesan más de 20k en /etc es: $CONF_COUNT"
blank

# --------------------------------------------
# 5.1 Archivo más grande en /usr/bin
# --------------------------------------------
LARGEST_FILE=$(find /usr/bin -type f -printf "%s %p\n" 2>/dev/null | sort -nr | head -n 1)
log "5.1 El archivo más grande en /usr/bin es:"
log "$LARGEST_FILE"
blank

# --------------------------------------------
# 5.2 Archivo más pequeño en /usr/bin
# --------------------------------------------
SMALLEST_FILE=$(find /usr/bin -type f -printf "%s %p\n" 2>/dev/null | sort -n | head -n 1)
log "5.2 El archivo más pequeño en /usr/bin es:"
log "$SMALLEST_FILE"
blank

# --------------------------------------------
# 5.3 Archivo que NO es regular
# --------------------------------------------
NON_REGULAR_FILE=$(find /usr/bin ! -type f | head -n 1)
log "5.3 Un archivo que no es regular en /usr/bin es:"
log "$NON_REGULAR_FILE"
blank

