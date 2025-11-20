#!/bin/bash

# ===================================
# TechNova - Lab 2 - Verificacion del Sitema
# Autor: Jensy Gomez
# Fecha: $(date +%d-%m-%Y)



# ===================================
# Variables del script
NOTES="/root/lab2-notes.txt"
LARGEBINS="/root/lab2-largebins.txt"

# ===================================
# Definiendo Funciones

run_and_log() {
    echo -e "\n[+] Ejecutando: $*" | tee -a "$NOTES"
    echo "=========================================" | tee -a "$NOTES"
    "$@" 2>&1 | tee -a "$NOTES"
    echo "" >> "$NOTES"
}

# ===================================
# INICIO DEL SCRIPT

# Limpiamos el archivo de notas si ya existe (opcional pero muy limpio en exámenes)
> "$NOTES"


# Objetivo 1.1 - Registrar ruta absoluta actual
run_and_log pwd