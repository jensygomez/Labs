#!/bin/bash

mostrar_menu_progreso() {
    clear
    echo "========================================="
    echo "       SUBMENÚ: MI PROGRESO ACTUAL       "
    echo "========================================="
    echo "1) Ver todas mis Rutas (Paths)"
    echo "2) Ver estado de un Curso"
    echo "3) Actualizar Estado de un Contenido (Lab/Video/Lectura)"
    echo "4) Volver al Menú Principal"
    echo "========================================="
    read -p "Selecciona una opción: " opt_progreso
    
    case $opt_progreso in
        4) return ;;
        *) echo "Función en desarrollo... Presiona ENTER para continuar"; read ;;
    esac
}
