#!/bin/bash
# gestion_db.sh - Editar y Eliminar ejercicios

source ./db.sh

# Colores
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

# --- Función para eliminar ---
eliminar_ejercicio() {
    local id=$1
    read -p "⚠️ ¿Estás seguro de eliminar el ejercicio ID $id? (s/n): " confirmar
    if [[ $confirmar == "s" ]]; then
        sqlite3 "$DB" "DELETE FROM ejercicios WHERE id = $id;"
        echo -e "${RED}❌ Ejercicio eliminado.${NC}"
    fi
}

# --- Función para editar enunciado ---
editar_enunciado() {
    local id=$1
    # 1. Extraer el base64 actual
    local b64_actual=$(sqlite3 "$DB" "SELECT enunciado FROM ejercicios WHERE id=$id;")
    
    # 2. Decodificar a un archivo temporal para editar
    echo "$b64_actual" | base64 -d > /tmp/edit_ejercicio.txt
    
    echo -e "${YELLOW}Se abrirá el editor para modificar el enunciado...${NC}"
    sleep 1
    ${EDITOR:-nano} /tmp/edit_ejercicio.txt
    
    # 3. Volver a codificar y guardar
    local nuevo_b64=$(base64 -w 0 < /tmp/edit_ejercicio.txt)
    sqlite3 "$DB" "UPDATE ejercicios SET enunciado = '$nuevo_b64' WHERE id = $id;"
    
    echo -e "${GREEN}✅ Enunciado actualizado.${NC}"
    rm /tmp/edit_ejercicio.txt
}

# --- Menú de Gestión ---
echo -e "${YELLOW}--- MANTENIMIENTO DE BASE DE DATOS ---${NC}"
read -p "Introduce el ID del ejercicio a gestionar: " id_buscado

# Verificar si existe
existe=$(sqlite3 "$DB" "SELECT id FROM ejercicios WHERE id=$id_buscado;")

if [ -z "$existe" ]; then
    echo -e "${RED}El ID $id_buscado no existe.${NC}"
    exit 1
fi

echo -e "\n1) 📝 Editar Enunciado\n2) 🗑️  Eliminar Ejercicio\n0) 🔙 Cancelar"
read -p "Selecciona una opción: " opcion

case $opcion in
    1) editar_enunciado "$id_buscado" ;;
    2) eliminar_ejercicio "$id_buscado" ;;
    *) exit 0 ;;
esac