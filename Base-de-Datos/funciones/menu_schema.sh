#!/bin/bash
# =========================================================
# menu_schema.sh - Configuración avanzada / evolución de DB
# =========================================================

mostrar_menu_schema() {
    while true; do
        clear
        titulo "CONFIGURACIÓN AVANZADA (SCHEMA)"
        echo "1) Ver estructura actual de las tablas"
        echo "2) Agregar columna manual a una tabla (avanzado)"
        echo "3) Volver al Menú Principal"
        advertencia "Nota: para nuevos atributos de contenido, mejor usa"
        advertencia "'Gestión de Propiedades' en el menú principal en vez de esto."
        separador
        local opt_schema
        preguntar opt_schema "Selecciona una opción: "

        case $opt_schema in
            3) return ;;
            1)
                clear
                titulo "ESTRUCTURA DE LA BASE DE DATOS"
                sqlite3 "$DB_NAME" ".schema"
                pausa
                ;;
            2)
                clear
                titulo "AGREGAR COLUMNA MANUAL"
                advertencia "Esto modifica la estructura real de una tabla. Úsalo con cuidado."
                local tabla columna
                preguntar tabla "Nombre de la tabla: "
                preguntar columna "Nombre de la nueva columna: "

                # Validación básica: solo letras, números y guion bajo (evita inyección vía ALTER)
                if [[ ! "$tabla" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || [[ ! "$columna" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
                    error_msg "Nombres inválidos. Solo letras, números y guion bajo, sin empezar con número."
                    pausa; continue
                fi

                sqlite3 "$DB_NAME" "ALTER TABLE $tabla ADD COLUMN $columna TEXT;" 2>/tmp/schema_err
                if [ $? -eq 0 ]; then
                    exito "Columna '$columna' añadida a la tabla '$tabla'."
                else
                    error_msg "Falló: $(cat /tmp/schema_err)"
                fi
                pausa
                ;;
            *) error_msg "Opción inválida"; sleep 1 ;;
        esac
    done
}
