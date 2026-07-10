#!/bin/bash
# =========================================================
# progreso.sh - Sistema de Seguimiento de Estudio
# =========================================================

cd "$(dirname "$0")"

source ./funciones/colores.sh
source ./funciones/common.sh
source ./funciones/db_init.sh
source ./funciones/menu_contenido.sh
source ./funciones/menu_progreso.sh
source ./funciones/menu_modificar.sh
source ./funciones/menu_propiedades.sh
source ./funciones/menu_schema.sh

inicializar_db

while true; do
    clear
    titulo "    SISTEMA DE SEGUIMIENTO DE ESTUDIO    "
    echo "1) Agregar Nuevo (Video/Lectura/Lab/Simulacro...)"
    echo "2) Mi Progreso (Rutas y Avances)"
    echo "3) Modificar / Eliminar"
    echo "4) Gestión de Propiedades (catálogo)"
    echo "5) Configuración Avanzada (Schema)"
    echo "6) Salir del Sistema"
    separador
    opcion=""
    preguntar opcion "Selecciona una opción [1-6]: "

    case $opcion in
        1) agregar_nuevo_contenido ;;
        2) mostrar_menu_progreso ;;
        3) mostrar_menu_modificar ;;
        4) mostrar_menu_propiedades ;;
        5) mostrar_menu_schema ;;
        6) exito "¡Buen entrenamiento! Sigue dándole duro a los laboratorios."; exit 0 ;;
        *) error_msg "Opción no válida, intenta de nuevo."; sleep 1 ;;
    esac
done
