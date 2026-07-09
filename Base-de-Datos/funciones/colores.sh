#!/bin/bash
# =========================================================
# colores.sh - Paleta y helpers de output unificados
# Todo el color del sistema vive aquí. Si mañana querés
# cambiar la paleta completa, solo tocás este archivo.
# =========================================================

# --- Colores base (ANSI) ---
readonly C_RESET="\033[0m"
readonly C_BOLD="\033[1m"
readonly C_DIM="\033[2m"

readonly C_ROJO="\033[0;31m"
readonly C_VERDE="\033[0;32m"
readonly C_AMARILLO="\033[0;33m"
readonly C_AZUL="\033[0;34m"
readonly C_MAGENTA="\033[0;35m"
readonly C_CIAN="\033[0;36m"
readonly C_GRIS="\033[0;90m"

readonly C_VERDE_B="\033[1;32m"
readonly C_CIAN_B="\033[1;36m"
readonly C_AMARILLO_B="\033[1;33m"

# --- Helpers semánticos de impresión ---

titulo() {
    # Encabezado principal de pantalla
    echo -e "${C_CIAN_B}=========================================${C_RESET}"
    echo -e "${C_CIAN_B}$1${C_RESET}"
    echo -e "${C_CIAN_B}=========================================${C_RESET}"
}

subtitulo() {
    echo -e "${C_AZUL}--- $1 ---${C_RESET}"
}

exito() {
    echo -e "${C_VERDE_B}✓ $1${C_RESET}"
}

error_msg() {
    echo -e "${C_ROJO}✗ $1${C_RESET}"
}

advertencia() {
    echo -e "${C_AMARILLO_B}⚠ $1${C_RESET}"
}

info_msg() {
    echo -e "${C_GRIS}$1${C_RESET}"
}

separador() {
    echo -e "${C_GRIS}-----------------------------------------${C_RESET}"
}

# Prompt de lectura con color (usa read -p normal, solo colorea el texto)
preguntar() {
    local __resultvar=$1
    local __prompt=$2
    local __input
    if [ -t 0 ]; then
        read -e -p "$(echo -e "${C_AMARILLO}${__prompt}${C_RESET}")" __input
    else
        read -p "$(echo -e "${C_AMARILLO}${__prompt}${C_RESET}")" __input
    fi
    eval "$__resultvar=\"\$__input\""
}

pausa() {
    read -p "$(echo -e "${C_GRIS}Presiona ENTER para continuar...${C_RESET}")"
}
