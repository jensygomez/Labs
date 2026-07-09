#!/bin/bash

mostrar_menu_schema() {
    clear
    echo "========================================="
    echo "   SUBMENÚ: EVOLUCIÓN DINÁMICA (SCHEMA)  "
    echo "========================================="
    echo "1) Agregar nueva columna a una tabla"
    echo "2) Ver estructura actual de las tablas"
    echo "3) Volver al Menú Principal"
    echo "========================================="
    read -p "Selecciona una opción: " opt_schema
    
    case $opt_schema in
        3) return ;;
        1)
            clear
            echo "--- Agregar Columna Dinámica ---"
            read -p "Nombre de la tabla (ej. contenidos): " tabla
            read -p "Nombre del nuevo atributo/columna: " columna
            
            # Ejecución del ALTER TABLE dinámico
            sqlite3 progreso.db "ALTER TABLE $tabla ADD COLUMN $columna TEXT;" 2>/dev/null
            if [ $? -eq 0 ]; then
                echo "¡Columna '$columna' añadida con éxito a la tabla '$tabla'!"
            else
                echo "Error: Verifica que la tabla exista y la columna no esté repetida."
            fi
            read -p "Presiona ENTER para continuar..."
            ;;
        2)
            clear
            echo "--- Estructura de la Base de Datos ---"
            sqlite3 progreso.db ".schema"
            read -p "Presiona ENTER para continuar..."
            ;;
        *) echo "Opción inválida"; sleep 1 ;;
    esac
}
