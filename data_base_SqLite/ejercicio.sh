#!/bin/bash
# ejercicio.sh - Muestra un ejercicio y procesa acciones del usuario
# Ubicación: ~/Labs/data_base_SqLite/ejercicio.sh

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

SEP="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
LINE="────────────────────────────────────────────────────────────"

# Cargar funciones de base de datos
source ./db.sh

# Función para mostrar el header del ejercicio
mostrar_header_ejercicio() {
    clear
    echo -e "${BOLD}${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    📋  EJERCICIO PRÁCTICO                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Función para mostrar el ejercicio
mostrar_ejercicio() {
    local id=$1
    local bloque=$2
    local tema=$3
    local nivel=$4
    local orden=$5
    local enunciado=$6
    local dificultad=$7
    local completado=$8
    local notas=$9
    
    # Calcular estrellas de dificultad
    local estrellas=""
    # Asegurar que dificultad es solo números
    dificultad_=$(echo "$dificultad_" | tr -cd '0-9')
    for ((i=1; i<=5; i++)); do
        if [ "$i" -le "$dificultad_" ] 2>/dev/null; then
            estrellas="${estrellas}★"
        else
            estrellas="${estrellas}☆"
        fi
    done
    
    # Mostrar información del ejercicio
    echo -e "\n  ${BOLD}🔥 BLOQUE $bloque | $tema | $nivel #$orden${NC}"
    echo -e "  $SEP"
    echo ""
    echo -e "  ${BOLD}📋 DIFICULTAD:${NC} $estrellas ($dificultad/5)"
    echo -e "  ${BOLD}⚡ NIVEL:${NC} $nivel"
    echo -e "  ${BOLD}🆔 ID:${NC} $id"
    echo ""
    echo -e "  ${BOLD}${CYAN}═════════════════════ ENUNCIADO ═════════════════════${NC}"
    echo ""
    
    # Mostrar el enunciado completo (viene con saltos de línea)
    echo "$enunciado" | while IFS= read -r linea; do
        echo -e "  $linea"
    done
    
    echo ""
    echo -e "  ${BOLD}${CYAN}════════════════════════════════════════════════════${NC}"
    
    # Mostrar notas si existen
    if [ -n "$notas" ] && [ "$notas" != "NULL" ]; then
        echo -e "\n  ${BOLD}📝 TUS NOTAS:${NC}"
        echo -e "  ${YELLOW}$notas${NC}"
        echo ""
    fi
    
    echo -e "  $SEP"
}

# Función para mostrar el menú de acciones
mostrar_menu_acciones() {
    local id=$1
    local pendientes=$2
    
    echo -e "\n  ${BOLD}🆕 SIGUIENTE EJERCICIO ($pendientes pendientes en este nivel)${NC}"
    echo -e "  $LINE"
    echo -e "  ${GREEN}✅  completado  | c  | 1${NC}   - cuando termines"
    echo -e "  ${YELLOW}📝  nota        | n  | 2${NC}   - agregar/editar nota personal"
    echo -e "  ${CYAN}📊  progreso    | p  | 3${NC}   - ver progreso del bloque"
    echo -e "  ${MAGENTA}🔍  ver         | v  | 4${NC}   - volver a ver el enunciado"
    echo -e "  ${BLUE}🔙  salir       | s  | 0${NC}   - volver al menú de niveles"
    echo -e "  $LINE"
}

# Función para agregar nota
agregar_nota_interactivo() {
    local id=$1
    
    echo -e "\n  ${YELLOW}📝 Escribe tu nota (máximo 200 caracteres):${NC}"
    echo -e "  ${CYAN}(deja vacío y ENTER para cancelar)${NC}"
    echo ""
    read -rp "  Nota: " nota
    
    if [ -n "$nota" ]; then
        # Limitar longitud y escapar comillas simples
        nota=$(echo "$nota" | sed "s/'/''/g" | cut -c1-200)
        sqlite3 "$DB" "UPDATE ejercicios SET notas = '$nota' WHERE id = $id;"
        echo -e "\n  ${GREEN}✅ Nota guardada correctamente${NC}"
    else
        echo -e "\n  ${YELLOW}⏩ Nota cancelada${NC}"
    fi
    sleep 1
}

# Función para mostrar progreso del bloque
mostrar_progreso() {
    local bloque=$1
    local nivel=$2
    
    echo -e "\n  ${CYAN}📊 PROGRESO DEL BLOQUE $bloque - $nivel${NC}"
    echo -e "  $LINE"
    
    sqlite3 "$DB" <<EOF
.mode table
SELECT 
    orden as '#',
    CASE WHEN completado=1 THEN '✅' ELSE '⏳' END as Estado,
    dificultad as '★',
    substr(enunciado, 1, 50) || '...' as Enunciado
FROM ejercicios 
WHERE bloque = $bloque AND nivel = '$nivel'
ORDER BY orden;
EOF
    
    echo ""
    read -rp "  Presiona ENTER para continuar..." _
}

# Función principal para ejecutar un ejercicio
ejecutar_ejercicio() {
    local bloque=$1
    local nivel=$2
    
    while true; do
        # Obtener el siguiente ejercicio pendiente
        local ejercicio=$(obtener_siguiente_ejercicio "$bloque" "$nivel")
        
        # Si no hay ejercicios pendientes
        if [ -z "$ejercicio" ]; then
            mostrar_header_ejercicio
            echo -e "\n  ${GREEN}🎉 ¡FELICIDADES!${NC}"
            echo -e "  $SEP"
            echo -e "  Has completado TODOS los ejercicios de"
            echo -e "  ${BOLD}$nivel - ${BLOQUES[$bloque]}${NC}"
            echo -e "  $SEP"
            echo ""
            
            # Mostrar resumen final
            sqlite3 "$DB" <<EOF
.mode table
SELECT 
    orden as '#',
    dificultad as '★',
    CASE WHEN notas IS NOT NULL AND notas != '' THEN '📝' ELSE '' END as Notas
FROM ejercicios 
WHERE bloque = $bloque AND nivel = '$nivel'
ORDER BY orden;
EOF
            echo ""
            read -rp "  Presiona ENTER para volver al menú..." _
            return 0
        fi
        
        # Parsear el resultado (formato: id|bloque|tema|nivel|orden|enunciado|dificultad|completado|ultima_vez|notas)
        IFS='🐧' read -r id bloque_ tema_ nivel_ orden_ enunciado_ dificultad_ completado_ ultima_vez_ notas_ <<< "$ejercicio"

        
        # Calcular pendientes en este nivel
        local pendientes=$(sqlite3 "$DB" "SELECT COUNT(*) FROM ejercicios WHERE bloque=$bloque AND nivel='$nivel' AND completado=0;")
        
        # Bucle de interacción con el ejercicio actual
        while true; do
            mostrar_header_ejercicio
            mostrar_ejercicio "$id" "$bloque_" "$tema_" "$nivel_" "$orden_" "$enunciado_" "$dificultad_" "$completado_" "$notas_"
            mostrar_menu_acciones "$id" "$pendientes"
            
            read -rp "  Tu acción: " accion
            echo ""
            
            case $accion in
                completado|c|C|1)
                    completar_ejercicio "$id"
                    echo -e "  ${GREEN}✅ Ejercicio $id COMPLETADO ✓ (${pendientes} pendientes restantes)${NC}"
                    sleep 1
                    break  # Salir del bucle interno para pasar al siguiente ejercicio
                    ;;
                nota|n|N|2)
                    agregar_nota_interactivo "$id"
                    # Actualizar notas para mostrarlas
                    notas_=$(sqlite3 "$DB" "SELECT notas FROM ejercicios WHERE id=$id;")
                    ;;
                progreso|p|P|3)
                    mostrar_progreso "$bloque_" "$nivel_"
                    ;;
                ver|v|V|4)
                    # Solo refresca la pantalla (volverá a mostrar el ejercicio)
                    continue
                    ;;
                salir|s|S|0)
                    echo -e "  ${BLUE}🔙 Volviendo al menú de niveles...${NC}"
                    sleep 1
                    return 0
                    ;;
                *)
                    echo -e "  ${RED}❌ Acción no reconocida${NC}"
                    echo -e "  Usa: completado|c|1 | nota|n|2 | progreso|p|3 | ver|v|4 | salir|s|0"
                    sleep 1
                    ;;
            esac
        done
    done
}

# Si el script se ejecuta directamente (no se hace source)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ $# -ne 2 ]; then
        echo -e "${RED}Uso: $0 <bloque> <nivel>${NC}"
        exit 1
    fi
    ejecutar_ejercicio "$1" "$2"
fi