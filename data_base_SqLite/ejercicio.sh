#!/bin/bash
# ejercicio.sh - Versión Corregida y Simplificada

source ./db.sh

# Colores y Formato
BOLD='\033[1m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; GREEN='\033[0;32m'; NC='\033[0m'
SEP="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mostrar_ejercicio() {
    # Recibimos las variables limpias
    local id=$1
    local bloque=$2
    local tema=$3
    local nivel=$4
    local orden=$5
    local enunciado=$6
    local dificultad=$7

    clear
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════╗"
    echo -e "║                    📋  EJERCICIO PRÁCTICO                    ║"
    echo -e "╚══════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n  ${BOLD}🔥 BLOQUE $bloque | $tema | $nivel #$orden${NC}"
    echo -e "  $SEP"
    echo -e "  ${BOLD}🆔 ID:${NC} $id  |  ${BOLD}📋 DIFICULTAD:${NC} $dificultad/5"
    echo ""
    echo -e "  ${BOLD}${CYAN}═════════════════════ ENUNCIADO ═════════════════════${NC}"
    echo ""
    
    # Imprimir el enunciado. Si viene de SQLite con saltos de línea (\n), los respetará.
    echo -e "  $enunciado"
    
    echo ""
    echo -e "  ${BOLD}${CYAN}════════════════════════════════════════════════════${NC}"
}

ejecutar_ejercicio() {
    local bloque=$1
    local nivel=$2
    
    while true; do
        # OBTENCIÓN DE DATOS (Asegúrate que obtener_siguiente_ejercicio use "|" como separador)
        local ejercicio=$(obtener_siguiente_ejercicio "$bloque" "$nivel")
        
        if [ -z "$ejercicio" ]; then
            echo "No hay más ejercicios."; return 0
        fi
        
        # PARSEO: Cambiamos el pingüino por |
        IFS='|' read -r id b t n o enu dif comp ult not <<< "$ejercicio"
        
        # Mostramos solo lo relevante
        mostrar_ejercicio "$id" "$b" "$t" "$n" "$o" "$enu" "$dif"
        
        # Menú rápido
        echo -e "\n  1) ✅ Completado  |  2) 📝 Nota  |  0) 🔙 Salir"
        read -rp "  Tu acción: " accion
        
        case $accion in
            1|c) completar_ejercicio "$id"; break ;;
            2|n) agregar_nota_interactivo "$id" ;;
            0|s) return 0 ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ejecutar_ejercicio "$1" "$2"
fi