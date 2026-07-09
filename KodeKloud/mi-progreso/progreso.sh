#!/bin/bash

# Cambiar al directorio del script para evitar fallos de rutas relativas
cd "$(dirname "$0")"

# Importar módulos y lógica secundaria
source ./funciones/db_init.sh
source ./funciones/menu_progreso.sh
source ./funciones/menu_crud.sh
source ./funciones/menu_schema.sh

# Asegurar que la base de datos exista y tenga la estructura inicial
inicializar_db

while true; do
    clear
    echo "========================================="
    echo "    SISTEMA DE SEGUIMIENTO DE ESTUDIO    "
    echo "========================================="
    echo "1) Mi Progreso (Rutas y Avances)"
    echo "2) Gestión de Contenido (Agregar/Editar/Borrar)"
    echo "3) Configuración Avanzada (Evolución de DB)"
    echo "4) Salir del Sistema"
    echo "========================================="
    read -p "Selecciona una opción [1-4]: " opcion

    case $opcion in
        1) mostrar_menu_progreso ;;
        2) mostrar_menu_crud ;;
        3) mostrar_menu_schema ;;
        4) echo "¡Buen entrenamiento! Sigue dándole duro a los laboratorios."; exit 0 ;;
        *) echo "Opción no válida, intenta de nuevo."; sleep 1 ;;
    esac
done
