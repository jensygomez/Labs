#!/bin/bash
# RHCSA EX200 – Boot & Recovery Slot 01
# Purpose: Default target incorrecto (modo seguro, reproducible)
# Author: Jensy Gomez
# Modular version: standalone scenario

set -euo pipefail

# --- Variables internas ---
TARGET_INCORRECTO="rescue.target"
TARGET_CORRECTO="multi-user.target"
LOG_FILE="/var/log/inject_boot.log"

# --- Función de log silencioso ---
log_injection() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Inject V1 executed" >> "$LOG_FILE"
}

# --- Validaciones básicas ---
if ! command -v systemctl &> /dev/null; then
    exit 1
fi

if ! systemctl list-unit-files | grep -q "^${TARGET_INCORRECTO}"; then
    exit 1
fi

# --- Inyección de fallo ---
# Cambia el default target a uno incorrecto (sin tocar el target activo)
systemctl set-default "$TARGET_INCORRECTO"

# --- Logging ---
log_injection

# --- Salida limpia ---
exit 0
