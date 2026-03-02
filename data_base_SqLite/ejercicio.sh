#!/bin/bash
# ejercicio.sh - Versión compatible con Base64

source ./db.sh

# Colores y Formato
BOLD='\033[1m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; 
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
SEP="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mostrar_ejercicio() {
    local id=$1
    local bloque=$2
    local tema=$3
    local nivel=$4
    local orden=$5
    local enunciado_b64=$6  # Viene en Base64 desde la DB
    local dificultad=$7
    local notas=$9

    # DECODIFICACIÓN: Aquí está el truco
    # Decodificamos el Base64 para recuperar los saltos de línea originales
    local enunciado_real=$(echo "$enunciado_b64" | base64 -d)

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
    
    # Imprimimos el enunciado decodificado
    # Usamos -e para que respete cualquier formato especial
    echo -e "$enunciado_real" | while IFS= read -r linea; do
        echo -e "  $linea"
    done
    
    echo ""
    echo -e "  ${BOLD}${CYAN}════════════════════════════════════════════════════${NC}"

    if [ -n "$notas" ] && [ "$notas" != "NULL" ]; then
        echo -e "\n  ${BOLD}📝 TUS NOTAS:${NC} ${YELLOW}$notas${NC}"
    fi
}

ejecutar_ejercicio() {
    local bloque=$1
    local nivel=$2
    
    while true; do
        # Asegúrate de que db.sh devuelva los campos separados por |
        local ejercicio=$(obtener_siguiente_ejercicio "$bloque" "$nivel")
        
        if [ -z "$ejercicio" ]; then
            echo -e "\n  ${GREEN}✅ ¡Nivel completado!${NC}"; return 0
        fi
        
        # Parseo con pipe |
        IFS='|' read -r id b t n o enu_b64 dif comp ult not <<< "$ejercicio"
        
        mostrar_ejercicio "$id" "$b" "$t" "$n" "$o" "$enu_b64" "$dif" "$comp" "$not"
        
        echo -e "\n  ${GREEN}1) ✅ Completado${NC}  |  ${YELLOW}2) 📝 Nota${NC}  |  ${BLUE}0) 🔙 Salir${NC}"
        read -rp "  Tu acción: " accion
        
        case $accion in
            1|c|C) completar_ejercicio "$id"; break ;;
            2|n|N) agregar_nota_interactivo "$id" ;; # Asumo que esta función está en db.sh o ejercicio.sh
            0|s|S) return 0 ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ejecutar_ejercicio "$1" "$2"
fi