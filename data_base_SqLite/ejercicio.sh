#!/bin/bash
# ejercicio.sh - Versión compatible con Base64 para Enunciados y Notas

source ./db.sh

# Colores y Formato
BOLD='\033[1m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; 
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
SEP="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# --- Función para agregar nota ---
agregar_nota_interactivo() {
    local id=$1
    
    echo -e "\n  ${YELLOW}📝 Escribe tu nota (puedes usar varias líneas, termina con Ctrl+D):${NC}"
    echo -e "  ${CYAN}(o presiona ENTER y Ctrl+D para cancelar)${NC}"
    echo ""
    
    # Capturamos la entrada completa (multilínea) hasta que el usuario use Ctrl+D
    local nota_raw=$(cat)
    
    if [ -n "$nota_raw" ]; then
        # Convertimos a Base64 -w 0 para que no inserte saltos de línea en la cadena codificada
        local nota_b64=$(echo "$nota_raw" | base64 -w 0)
        sqlite3 "$DB" "UPDATE ejercicios SET notas = '$nota_b64' WHERE id = $id;"
        echo -e "\n  ${GREEN}✅ Nota guardada correctamente${NC}"
    else
        echo -e "\n  ${YELLOW}⏩ Nota cancelada${NC}"
    fi
    sleep 1
}

# --- Función para mostrar el ejercicio ---
mostrar_ejercicio() {
    local id=$1
    local bloque=$2
    local tema=$3
    local nivel=$4
    local orden=$5
    local enunciado_b64=$6
    local dificultad=$7
    local notas_b64=$9  # Las notas vienen en la posición 9

    # Decodificamos el enunciado
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
    
    # Imprimir enunciado decodificado con sangría
    echo -e "$enunciado_real" | while IFS= read -r linea; do
        echo -e "  $linea"
    done
    
    echo ""
    echo -e "  ${BOLD}${CYAN}════════════════════════════════════════════════════${NC}"

    # --- Mostrar notas si existen ---
    if [ -n "$notas_b64" ] && [ "$notas_b64" != "NULL" ] && [ "$notas_b64" != "" ]; then
        echo -e "\n  ${BOLD}📝 TUS NOTAS:${NC}"
        # Decodificamos la nota al vuelo
        local nota_real=$(echo "$notas_b64" | base64 -d)
        echo -e "${YELLOW}$nota_real${NC}" | while IFS= read -r linea; do
            echo -e "  $linea"
        done
        echo ""
        echo -e "  $SEP"
    fi
}

# --- Función principal de ejecución ---
ejecutar_ejercicio() {
    local bloque=$1
    local nivel=$2
    
    while true; do
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
            2|n|N) 
                agregar_nota_interactivo "$id" 
                # No necesitamos recargar manualmente, el bucle volverá a leer de la DB
                ;;
            0|s|S) return 0 ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ejecutar_ejercicio "$1" "$2"
fi