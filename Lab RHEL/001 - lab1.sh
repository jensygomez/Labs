#!/bin/bash

# Este es mi Laboratorio LAB1
# Mi nombre es Jensy Gomez
# Variable donde se guardarán las notas
NOTES="/root/lab-notes.txt"

# Determinar cuál es el usuario actual
TARGET_USER="${SUDO_USER:-$USER}"

# 1.1 Registrando la ruta absoluta
echo "1.1 Esta es la ruta absoluta inicial" | tee -a "$NOTES"
pwd | tee -a "$NOTES"
echo "" | tee -a "$NOTES"

# 1.2 Cambiando al directorio /usr/share
cd /usr/share
echo "Estoy en el directorio $(pwd) gracias a que usé la ruta absoluta cd /usr/share" | tee -a "$NOTES"
echo "" | tee -a "$NOTES"

# 1.2 Volver a HOME con ruta relativa
cd ../../home/$TARGET_USER
echo "Regresé a mi $(pwd), usando la ruta relativa cd ../../home/$TARGET_USER" | tee -a "$NOTES"
echo "" | tee -a "$NOTES"

# 2.1 Listar contenido de /etc
ls -l /etc | tee -a "$NOTES"
echo "" | tee -a "$NOTES"
echo "Usé el comando ls -l /etc para listar el contenido de este directorio" | tee -a "$NOTES"
echo "" | tee -a "$NOTES"

# 2.2 Buscar archivo que contenga 'release'
RELEASE_FILE=$(find /etc -name "*release*")
echo "2.2 Archivos encontrados que contienen la palabra 'release':" | tee -a "$NOTES"
echo "$RELEASE_FILE" | tee -a "$NOTES"
echo "" | tee -a "$NOTES"

# 2.3 Registrar la ruta completa
echo "2.3 Registrando rutas completas de archivos 'release':" | tee -a "$NOTES"
echo "$RELEASE_FILE" | tee -a "$NOTES"
echo "" | tee -a "$NOTES"

# 3.1 Archivos modificados en últimas 24h
FIND_FILES=$(find /var/log -type f -mtime -1)
echo "3.1 Archivos modificados en las últimas 24 horas en /var/log:" | tee -a "$NOTES"
echo "$FIND_FILES" | tee -a "$NOTES"
echo "" | tee -a "$NOTES"

# 3.2 Mostrar los 5 archivos más recientes
RECENT_5_FILES=$(find /var/log -type f -printf "%T@ %p\n" | sort -nr | head -n 5)
echo "3.2 Los 5 archivos más recientes en /var/log son:" | tee -a "$NOTES"
echo "$RECENT_5_FILES" | tee -a "$NOTES"
echo "" | tee -a "$NOTES"

# 3.3 Guardando la salida exacta
echo "$RECENT_5_FILES" | tee /root/lastlogs.txt
echo "" | tee -a "$NOTES"
