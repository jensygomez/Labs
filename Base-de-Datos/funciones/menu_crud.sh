#!/bin/bash

DB_NAME="progreso.db"

mostrar_menu_crud() {
    while true; do
        clear
        echo "========================================="
        echo "   SUBMENÚ: GESTIÓN DE CONTENIDO (CRUD)  "
        echo "========================================="
        echo "1) Agregar nuevo Path (Ruta)"
        echo "2) Agregar Curso y asociarlo a un Path"
        echo "3) Agregar Módulo a un Curso"
        echo "4) Agregar Contenido (Video/Lectura/Lab)"
        echo "5) MODIFICAR o ELIMINAR (Paths, Cursos, Módulos)"
        echo "6) Volver al Menú Principal"
        echo "========================================="
        read -p "Selecciona una opción [1-6]: " opt_crud
        
        case $opt_crud in
            1)
                clear
                echo "--- Registrar Nuevo Path ---"
                echo "(Escribe 'q' y presiona ENTER para cancelar y volver)"
                read -p "Nombre del Path: " v_path
                
                # Validación de salida o vacío
                if [ -z "$v_path" ] || [ "$v_path" = "q" ]; then
                    echo "Operación cancelada."
                    sleep 1; continue
                fi
                
                sqlite3 "$DB_NAME" "INSERT OR IGNORE INTO paths (nombre_path) VALUES ('$v_path');"
                echo "¡Path '$v_path' procesado!"
                read -p "Presiona ENTER para continuar..."
                ;;
                
            2)
                clear
                echo "--- Registrar Curso y Asociar a Path ---"
                echo "Paths disponibles:"
                sqlite3 "$DB_NAME" -column -header "SELECT id_path, nombre_path FROM paths;"
                echo "-----------------------------------------"
                echo "(Escribe 'q' para cancelar)"
                read -p "Introduce el ID del Path al que pertenece: " v_id_path
                
                if [ "$v_id_path" = "q" ] || [ -z "$v_id_path" ]; then
                    echo "Operación cancelada."
                    sleep 1; continue
                fi
                
                # Validar que el ID sea numérico y exista
                path_check=$(sqlite3 "$DB_NAME" "SELECT count(*) FROM paths WHERE id_path='$v_id_path';")
                if [ "$path_check" -eq 0 ]; then
                    echo "Error: ID de Path no válido."
                    sleep 2; continue
                fi
                
                read -p "Nombre del Curso: " v_curso
                if [ -z "$v_curso" ] || [ "$v_curso" = "q" ]; then
                    echo "Operación cancelada."
                    sleep 1; continue
                fi
                
                sqlite3 "$DB_NAME" "INSERT OR IGNORE INTO cursos (nombre_curso) VALUES ('$v_curso');"
                v_id_curso=$(sqlite3 "$DB_NAME" "SELECT id_curso FROM cursos WHERE nombre_curso='$v_curso';")
                sqlite3 "$DB_NAME" "INSERT OR IGNORE INTO path_cursos (id_path, id_curso) VALUES ($v_id_path, $v_id_curso);"
                echo "¡Curso registrado y asociado con éxito!"
                read -p "Presiona ENTER para continuar..."
                ;;
                
            3)
                clear
                echo "--- Registrar Módulo en un Curso ---"
                echo "Cursos disponibles:"
                sqlite3 "$DB_NAME" -column -header "SELECT id_curso, nombre_curso FROM cursos;"
                echo "-----------------------------------------"
                read -p "ID del Curso (o 'q' para salir): " v_id_curso
                
                if [ "$v_id_curso" = "q" ] || [ -z "$v_id_curso" ]; then continue; fi
                
                read -p "Nombre del Módulo: " v_modulo
                if [ -z "$v_modulo" ] || [ "$v_modulo" = "q" ]; then continue; fi
                
                sqlite3 "$DB_NAME" "INSERT INTO modulos (id_curso, nombre_modulo) VALUES ($v_id_curso, '$v_modulo');"
                echo "¡Módulo agregado!"
                read -p "Presiona ENTER para continuar..."
                ;;
                
            4)
                while true; do
                    clear
                    echo "========================================="
                    echo "         REGISTRAR NUEVO CONTENIDO       "
                    echo "========================================="
                    # Mostrar módulos disponibles
                    sqlite3 "$DB_NAME" -column -header "SELECT m.id_modulo, c.nombre_curso, m.nombre_modulo FROM modulos m JOIN cursos c ON m.id_curso = c.id_curso;"
                    echo "-----------------------------------------"
                    echo "(Escribe 'q' para regresar al menú CRUD)"
                    read -p "ID del Módulo base: " v_id_modulo
                    
                    if [ "$v_id_modulo" = "q" ] || [ -z "$v_id_modulo" ]; then
                        break # Rompe el bucle principal de contenido y vuelve al menú CRUD
                    fi

                    # Validar que el módulo exista y obtener su nombre
                    mod_nombre=$(sqlite3 "$DB_NAME" "SELECT nombre_modulo FROM modulos WHERE id_modulo='$v_id_modulo';")
                    if [ -z "$mod_nombre" ]; then
                        echo "Error: ID de Módulo no válido."
                        sleep 2; continue
                    fi

                    # BUCLE INTERNO: Para quedarse dentro del mismo módulo si el usuario quiere
                    while true; do
                        clear
                        echo "========================================="
                        echo " MÓDULO SELECCIONADO: $mod_nombre"
                        echo "========================================="
                        echo "Contenido ya registrado en este módulo:"
                        echo "-----------------------------------------"
                        
                        # 1. Mostrar contenido existente para no repetir
                        con_check=$(sqlite3 "$DB_NAME" "SELECT count(*) FROM contenidos WHERE id_modulo=$v_id_modulo;")
                        if [ "$con_check" -eq 0 ]; then
                            echo "[ No hay contenido registrado aún ]"
                        else
                            sqlite3 "$DB_NAME" -column -header "SELECT tipo, titulo, estado FROM contenidos WHERE id_modulo=$v_id_modulo;"
                        fi
                        echo "========================================="
                        
                        # 2. Selección de Tipo de Contenido en formato de lista (vertical)
                        echo "Selecciona el Tipo de Contenido:"
                        echo "1) Video"
                        echo "2) Lectura"
                        echo "3) Laboratorio"
                        echo "4) Volver a cambiar de Módulo"
                        echo "-----------------------------------------"
                        read -p "Selecciona una opción [1-4]: " v_tipo_opt
                        
                        case $v_tipo_opt in
                            1) v_tipo="Video" ;;
                            2) v_tipo="Lectura" ;;
                            3) v_tipo="Laboratorio" ;;
                            4) break ;; # Sale del bucle interno, permitiendo elegir otro módulo
                            *) echo "Opción no válida"; sleep 1; continue ;;
                        esac
                        
                        echo "-----------------------------------------"
                        read -p "Título del Contenido (ej. El Candado Oxidado o Lesson 01): " v_titulo
                        if [ -z "$v_titulo" ] || [ "$v_titulo" = "q" ]; then
                            echo "Inserción cancelada."
                            sleep 1; continue
                        fi
                        
                        # 3. Guardar en la Base de Datos
                        sqlite3 "$DB_NAME" "INSERT INTO contenidos (id_modulo, tipo, titulo) VALUES ($v_id_modulo, '$v_tipo', '$v_titulo');"
                        echo "-----------------------------------------"
                        echo "¡'$v_titulo' ($v_tipo) guardado con éxito!"
                        echo "-----------------------------------------"
                        
                        # 4. Menú de decisión posterior en lista vertical
                        echo "¿Qué deseas hacer ahora?"
                        echo "1) Agregar más contenido a este mismo módulo ($mod_nombre)"
                        echo "2) Volver a la lista de módulos / Salir"
                        echo "-----------------------------------------"
                        read -p "Selecciona una opción [1-2]: " v_sig_accion
                        
                        if [ "$v_sig_accion" != "1" ]; then
                            break # Rompe el bucle de inserción continua y vuelve a la lista de módulos
                        fi
                    done
                done
                ;;

            5)
                # LLAMADA AL SUBMENÚ DE EDICIÓN Y BORRADO
                gestionar_modificaciones
                ;;
                
            6) return ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac
    done
}

gestionar_modificaciones() {
    while true; do
        clear
        echo "========================================="
        echo "       MODIFICAR O ELIMINAR DATOS        "
        echo "========================================="
        echo "1) Editar / Eliminar un PATH"
        echo "2) Editar / Eliminar un CURSO"
        echo "3) Volver al menú CRUD"
        echo "========================================="
        read -p "Selecciona una opción [1-3]: " opt_mod
        
        case $opt_mod in
            1)
                clear
                echo "--- Lista de Paths ---"
                sqlite3 "$DB_NAME" -column -header "SELECT id_path, nombre_path FROM paths;"
                echo "-----------------------------------------"
                read -p "Introduce el ID del Path a modificar (o 'q' para volver): " target_id
                if [ "$target_id" = "q" ] || [ -z "$target_id" ]; then continue; fi
                
                echo "Acción: 1) Cambiar Nombre  2) ELIMINAR (Borrado en Cascada)"
                read -p "Selecciona [1-2]: " accion
                
                if [ "$accion" = "1" ]; then
                    read -p "Nuevo nombre para el Path: " nuevo_nombre
                    if [ -n "$nuevo_nombre" ]; then
                        sqlite3 "$DB_NAME" "UPDATE paths SET nombre_path='$nuevo_nombre' WHERE id_path=$target_id;"
                        echo "¡Actualizado con éxito!"
                    fi
                elif [ "$accion" = "2" ]; then
                    read -p "¿Estás seguro de eliminar el Path $target_id y TODO su contenido asociado? (s/n): " confirmar
                    if [ "$confirmar" = "s" ]; then
                        # Forzar la activación de FK para que ejecute el CASCADE en esta sesión
                        sqlite3 "$DB_NAME" "PRAGMA foreign_keys = ON; DELETE FROM paths WHERE id_path=$target_id;"
                        echo "¡Path y dependencias eliminados de la base de datos!"
                    fi
                fi
                read -p "Presiona ENTER para continuar..."
                ;;
            2)
                clear
                echo "--- Lista de Cursos ---"
                sqlite3 "$DB_NAME" -column -header "SELECT id_curso, nombre_curso FROM cursos;"
                echo "-----------------------------------------"
                read -p "Introduce el ID del Curso a modificar (o 'q' para volver): " target_id
                if [ "$target_id" = "q" ] || [ -z "$target_id" ]; then continue; fi
                
                echo "Acción: 1) Cambiar Nombre  2) ELIMINAR"
                read -p "Selecciona [1-2]: " accion
                
                if [ "$accion" = "1" ]; then
                    read -p "Nuevo nombre para el Curso: " nuevo_nombre
                    if [ -n "$nuevo_nombre" ]; then
                        sqlite3 "$DB_NAME" "UPDATE cursos SET nombre_curso='$nuevo_nombre' WHERE id_curso=$target_id;"
                        echo "¡Actualizado con éxito!"
                    fi
                elif [ "$accion" = "2" ]; then
                    read -p "¿Seguro de eliminar el Curso $target_id? Se borrarán sus módulos y contenidos (s/n): " confirmar
                    if [ "$confirmar" = "s" ]; then
                        sqlite3 "$DB_NAME" "PRAGMA foreign_keys = ON; DELETE FROM cursos WHERE id_curso=$target_id;"
                        echo "¡Curso eliminado con éxito!"
                    fi
                fi
                read -p "Presiona ENTER para continuar..."
                ;;
            3) return ;;
        esac
    done
}
