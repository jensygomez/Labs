#!/bin/bash

# ===================================
# TechNova - Lab 2 - Verificacion del Sistema
# Autor: Jensy Gomez
# Fecha: $(date +%d-%m-%Y)

# ===================================
# Variables del script
NOTES="/root/lab2-notes.txt"
LARGEBINS="/root/lab2-largebins.txt"

# ===================================
# Función mejorada
# Uso:
#   run_and_log "comentario"
#   run_and_log "comentario" comando arg1 arg2 ...

run_and_log() {
    local comment="$1"    # Primer argumento: Comentario
    shift                 # Quitamos el comentario de la lista de argumentos

    echo -e "\n[+] $comment" | tee -a "$NOTES"
    echo "=========================================" | tee -a "$NOTES"

    # Si quedan argumentos → ejecutar comando
    if [ $# -gt 0 ]; then
        "$@" 2>&1 | tee -a "$NOTES"
    else
        echo "(Sin comando para ejecutar)" | tee -a "$NOTES"
    fi

    echo "" >> "$NOTES"
}

# ===================================
# INICIO DEL SCRIPT

# Limpiar notas
> "$NOTES"

# Objetivo 1.1 - Registrar ruta absoluta actual
run_and_log "Mostrando ruta absoluta actual" pwd

# Objetivo 1.2 - Solo comentario, sin comando
run_and_log "Este es solo un comentario sin comando"