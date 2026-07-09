#!/bin/bash
# =========================================================
# menu_modificar.sh - Editar / eliminar registros existentes
# =========================================================

mostrar_menu_modificar() {
    while true; do
        clear
        titulo "MODIFICAR O ELIMINAR"
        echo "1) Path"
        echo "2) Curso"
        echo "3) Módulo"
        echo "4) Contenido"
        echo "5) Volver al Menú Principal"
        separador
        local opt
        preguntar opt "Selecciona una opción: "
        case $opt in
            1) _modificar_generico paths nombre_path id_path "Path" ;;
            2) _modificar_generico cursos nombre_curso id_curso "Curso" ;;
            3) _modificar_generico modulos nombre_modulo id_modulo "Módulo" ;;
            4) _modificar_contenido ;;
            5) return ;;
            *) error_msg "Opción inválida"; sleep 1 ;;
        esac
    done
}

# Editar nombre / eliminar para tablas simples (paths, cursos, modulos)
_modificar_generico() {
    local tabla="$1" columna="$2" id_columna="$3" etiqueta="$4"
    clear
    titulo "MODIFICAR / ELIMINAR $etiqueta"
    db_query "SELECT $id_columna, $columna FROM $tabla ORDER BY $columna;"
    separador
    local target_id
    preguntar target_id "ID a modificar (o vacío para volver): "
    if [ -z "$target_id" ]; then return; fi

    local existe
    existe=$(db_exec "SELECT COUNT(*) FROM $tabla WHERE $id_columna=$target_id;")
    if [ "$existe" != "1" ]; then error_msg "ID inválido."; pausa; return; fi

    echo "1) Cambiar nombre"
    echo "2) Eliminar (borrado en cascada de todo lo asociado)"
    local accion
    preguntar accion "Selecciona [1-2]: "

    if [ "$accion" = "1" ]; then
        local nuevo_nombre nuevo_safe
        preguntar nuevo_nombre "Nuevo nombre: "
        if [ -n "$nuevo_nombre" ]; then
            nuevo_safe=$(escapar_sql "$nuevo_nombre")
            db_exec "UPDATE $tabla SET $columna='$nuevo_safe' WHERE $id_columna=$target_id;"
            exito "Actualizado con éxito."
        fi
    elif [ "$accion" = "2" ]; then
        if confirmar "¿Seguro que quieres eliminar este $etiqueta y TODO lo asociado?"; then
            db_exec "PRAGMA foreign_keys = ON; DELETE FROM $tabla WHERE $id_columna=$target_id;"
            exito "$etiqueta eliminado."
        fi
    fi
    pausa
}

_modificar_contenido() {
    clear
    titulo "MODIFICAR / ELIMINAR CONTENIDO"
    local id_contenido
    id_contenido=$(_navegar_a_contenido)
    if [ -z "$id_contenido" ]; then return; fi

    echo "1) Cambiar título"
    echo "2) Eliminar (incluye sus propiedades)"
    local accion
    preguntar accion "Selecciona [1-2]: "

    if [ "$accion" = "1" ]; then
        local nuevo_titulo nuevo_safe
        preguntar nuevo_titulo "Nuevo título: "
        if [ -n "$nuevo_titulo" ]; then
            nuevo_safe=$(escapar_sql "$nuevo_titulo")
            db_exec "UPDATE contenidos SET titulo='$nuevo_safe' WHERE id_contenido=$id_contenido;"
            exito "Título actualizado."
        fi
    elif [ "$accion" = "2" ]; then
        if confirmar "¿Seguro que quieres eliminar este contenido?"; then
            db_exec "PRAGMA foreign_keys = ON; DELETE FROM contenidos WHERE id_contenido=$id_contenido;"
            exito "Contenido eliminado."
        fi
    fi
    pausa
}
