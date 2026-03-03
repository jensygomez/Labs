#!/bin/bash
# ejercicio.sh - Versión con Edición y Eliminación integrada

source ./db.sh

# Colores y Formato
BOLD='\033[1m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; 
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
SEP="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# --- NUEVA FUNCIÓN: Gestión (Editar/Eliminar) ---
gestionar_ejercicio_interactivo() {
    local id=$1
    echo -e "\n  ${YELLOW}🛠️  OPCIONES DE ADMINISTRACIÓN:${NC}"
    echo -e "  1) 📝 Editar Enunciado"
    echo -e "  2) 🗑️  Eliminar Ejercicio"
    echo -e "  0) 🔙 Cancelar"
    read -rp "  Selecciona: " opt

    case $opt in
        1)
            # 1. Sacar enunciado actual (Base64) y decodificar a temporal
            local b64_actual=$(sqlite3 "$DB" "SELECT enunciado FROM ejercicios WHERE id=$id;")
            echo "$b64_actual" | base64 -d > /tmp/edit_ejer.txt
            
            echo -e "  ${CYAN}Abriendo editor... guarda y cierra para aplicar cambios.${NC}"
            sleep 1
            ${EDITOR:-nano} /tmp/edit_ejer.txt
            
            # 2. Codificar de nuevo y guardar en DB
            local nuevo_b64=$(base64 -w 0 < /tmp/edit_ejer.txt)
            sqlite3 "$DB" "UPDATE ejercicios SET enunciado = '$nuevo_b64' WHERE id = $id;"
            echo -e "  ${GREEN}✅ Enunciado actualizado correctamente.${NC}"
            rm /tmp/edit_ejer.txt
            sleep 1
            return 0 # Refrescar
            ;;
        2)
            echo -e "  ${RED}⚠️  ¿Estás SEGURO de eliminar el ID $id? (escribe 'si' para confirmar)${NC}"
            read -rp "  > " conf
            if [[ "$conf" == "si" ]]; then
                sqlite3 "$DB" "DELETE FROM ejercicios WHERE id = $id;"
                echo -e "  ${RED}❌ Ejercicio borrado.${NC}"
                sleep 1
                return 1 # Indica que el ejercicio ya no existe
            fi
            ;;
    esac
}

# --- Función para agregar nota ---
agregar_nota_interactivo() {
    local id=$1
    echo -e "\n  ${YELLOW}📝 Escribe tu nota (termina con Ctrl+D):${NC}"
    local nota_raw=$(cat)
    if [ -n "$nota_raw" ]; then
        local nota_b64=$(echo "$nota_raw" | base64 -w 0)
        sqlite3 "$DB" "UPDATE ejercicios SET notas = '$nota_b64' WHERE id = $id;"
        echo -e "\n  ${GREEN}✅ Nota guardada${NC}"
    fi
    sleep 1
}

# --- Función para mostrar el ejercicio ---
mostrar_ejercicio() {
    local id=$1; local bloque=$2; local tema=$3; local nivel=$4; 
    local orden=$5; local enunciado_b64=$6; local dificultad=$7; local notas_b64=$9

    local enunciado_real=$(echo "$enunciado_b64" | base64 -d)

    clear
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════╗"
    echo -e "║                    📋  EJERCICIO PRÁCTICO                    ║"
    echo -e "╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n  ${BOLD}🔥 BLOQUE $bloque | $tema | $nivel #$orden${NC}"
    echo -e "  $SEP"
    echo -e "  ${BOLD}🆔 ID:${NC} $id  |  ${BOLD}📋 DIFICULTAD:${NC} $dificultad/5"
    echo -e "\n  ${BOLD}${CYAN}═════════════════════ ENUNCIADO ═════════════════════${NC}\n"
    
    echo -e "$enunciado_real" | while IFS= read -r linea; do echo -e "  $linea"; done
    
    if [ -n "$notas_b64" ] && [ "$notas_b64" != "NULL" ]; then
        echo -e "\n  ${BOLD}📝 TUS NOTAS:${NC}"
        echo -e "${YELLOW}$(echo "$notas_b64" | base64 -d)${NC}" | while IFS= read -r linea; do echo -e "  $linea"; done
    fi
    echo -e "\n  $SEP"
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
        
        IFS='|' read -r id b t n o enu_b64 dif comp ult not <<< "$ejercicio"
        mostrar_ejercicio "$id" "$b" "$t" "$n" "$o" "$enu_b64" "$dif" "$comp" "$not"
        
        # --- MENÚ DE ACCIONES ACTUALIZADO ---
        echo -e "\n  ${GREEN}1) ✅ Completar${NC}  |  ${YELLOW}2) 📝 Nota${NC}  |  ${RED}3) 🛠️  Gestionar${NC}  |  ${BLUE}0) 🔙 Salir${NC}"
        read -rp "  Tu acción: " accion
        
        case $accion in
            1|c|C) completar_ejercicio "$id"; break ;;
            2|n|N) agregar_nota_interactivo "$id" ;;
            3|g|G) 
                gestionar_ejercicio_interactivo "$id"
                # Si el resultado fue eliminar, saltamos al siguiente
                [ $? -eq 1 ] && break 
                ;;
            0|s|S) return 0 ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ejecutar_ejercicio "$1" "$2"
fi