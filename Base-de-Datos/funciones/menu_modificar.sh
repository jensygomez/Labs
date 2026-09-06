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
        echo "5) Reordenar Cursos"
        echo "6) Reordenar Módulos"
        echo "7) Reordenar Contenidos"
        echo "8) Volver al Menú Principal"
        separador
        local opt
        preguntar opt "Selecciona una opción: "
        case $opt in
            1) _modificar_generico paths nombre_path id_path "Path" ;;
            2) _modificar_curso ;;
            3) _modificar_modulo ;;
            4) _modificar_contenido ;;
            5) _reordenar_cursos ;;
            6) _reordenar_modulos ;;
            7) _reordenar_contenidos ;;
            8) return ;;
            *) error_msg "Opción inválida"; sleep 1 ;;
        esac
    done
}

# Editar nombre / eliminar para tablas simples sin orden (paths, cursos)
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

_modificar_curso() {
    clear
    titulo "MODIFICAR / ELIMINAR CURSO"
    local id_curso
    id_curso=$(seleccionar_o_crear cursos nombre_curso id_curso "Curso" "" "" "orden")
    if [ -z "$id_curso" ]; then return; fi

    echo "1) Cambiar nombre"
    echo "2) Eliminar (borrado en cascada de todo lo asociado)"
    local accion
    preguntar accion "Selecciona [1-2]: "

    if [ "$accion" = "1" ]; then
        local nuevo_nombre nuevo_safe
        preguntar nuevo_nombre "Nuevo nombre: "
        if [ -n "$nuevo_nombre" ]; then
            nuevo_safe=$(escapar_sql "$nuevo_nombre")
            db_exec "UPDATE cursos SET nombre_curso='$nuevo_safe' WHERE id_curso=$id_curso;"
            exito "Actualizado con éxito."
        fi
    elif [ "$accion" = "2" ]; then
        if confirmar "¿Seguro que quieres eliminar este Curso y TODO lo asociado?"; then
            db_exec "PRAGMA foreign_keys = ON; DELETE FROM cursos WHERE id_curso=$id_curso;"
            exito "Curso eliminado."
        fi
    fi
    pausa
}

_modificar_modulo() {
    clear
    titulo "MODIFICAR / ELIMINAR MÓDULO"
    local id_curso
    id_curso=$(seleccionar_o_crear cursos nombre_curso id_curso "Curso" "" "" "orden")
    if [ -z "$id_curso" ]; then return; fi

    clear
    titulo "MODIFICAR / ELIMINAR MÓDULO"
    local id_modulo
    id_modulo=$(seleccionar_o_crear modulos nombre_modulo id_modulo "Módulo" id_curso "$id_curso" "orden")
    if [ -z "$id_modulo" ]; then return; fi

    echo "1) Cambiar nombre"
    echo "2) Eliminar (borrado en cascada de todo lo asociado)"
    local accion
    preguntar accion "Selecciona [1-2]: "

    if [ "$accion" = "1" ]; then
        local nuevo_nombre nuevo_safe
        preguntar nuevo_nombre "Nuevo nombre: "
        if [ -n "$nuevo_nombre" ]; then
            nuevo_safe=$(escapar_sql "$nuevo_nombre")
            db_exec "UPDATE modulos SET nombre_modulo='$nuevo_safe' WHERE id_modulo=$id_modulo;"
            exito "Actualizado con éxito."
        fi
    elif [ "$accion" = "2" ]; then
        if confirmar "¿Seguro que quieres eliminar este Módulo y TODO lo asociado?"; then
            db_exec "PRAGMA foreign_keys = ON; DELETE FROM modulos WHERE id_modulo=$id_modulo;"
            exito "Módulo eliminado."
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

# =========================================================
# _reordenar_generico
# Muestra una lista numerada (Nº, no ID) y permite mover un
# elemento hacia arriba o abajo intercambiando su valor de
# 'orden' con el del vecino inmediato.
# =========================================================
_reordenar_generico() {
    local tabla="$1" columna="$2" id_columna="$3" etiqueta="$4"
    local col_filtro="$5" val_filtro="$6" titulo_plural="$7"
    local where=""
    [ -n "$col_filtro" ] && where="WHERE $col_filtro=$val_filtro"

    while true; do
        clear
        titulo "REORDENAR ${titulo_plural:-$etiqueta}"
        local filas
        filas=$(db_row "SELECT ROW_NUMBER() OVER (ORDER BY orden, $id_columna), $id_columna, orden, $columna FROM $tabla $where;")
        declare -A mapa_id mapa_orden
        if [ -z "$filas" ]; then
            info_msg "[ No hay ${etiqueta}s para reordenar ]"
            pausa
            unset mapa_id mapa_orden
            return
        fi
        printf "%-4s %s\n" "Nº" "$etiqueta"
        while IFS='|' read -r num rid rorden rnombre; do
            printf "%-4s %s\n" "$num)" "$rnombre"
            mapa_id["$num"]="$rid"
            mapa_orden["$num"]="$rorden"
        done <<< "$filas"
        separador
        echo "q) Volver"
        separador
        local sel
        preguntar sel "Número a mover (o q): "
        if [ "$sel" = "q" ]; then unset mapa_id mapa_orden; return; fi
        if [ -z "${mapa_id[$sel]}" ]; then
            error_msg "Número inválido."; sleep 1; unset mapa_id mapa_orden; continue
        fi

        echo "1) Subir (mover arriba)"
        echo "2) Bajar (mover abajo)"
        local dir
        preguntar dir "Selecciona: "

        local id_actual="${mapa_id[$sel]}" orden_actual="${mapa_orden[$sel]}"
        local vecino_num
        if [ "$dir" = "1" ]; then
            vecino_num=$((sel-1))
        elif [ "$dir" = "2" ]; then
            vecino_num=$((sel+1))
        else
            error_msg "Opción inválida."; sleep 1; unset mapa_id mapa_orden; continue
        fi

        if [ -z "${mapa_id[$vecino_num]}" ]; then
            advertencia "Ya está en el extremo, no se puede mover más."
            sleep 1
        else
            local id_vecino="${mapa_id[$vecino_num]}" orden_vecino="${mapa_orden[$vecino_num]}"
            db_exec "UPDATE $tabla SET orden=$orden_vecino WHERE $id_columna=$id_actual;
                     UPDATE $tabla SET orden=$orden_actual WHERE $id_columna=$id_vecino;"
            exito "Movido."
            sleep 1
        fi
        unset mapa_id mapa_orden
    done
}

_reordenar_cursos() {
    clear
    titulo "REORDENAR CURSOS"
    _reordenar_generico cursos nombre_curso id_curso "Curso" "" "" "CURSOS"
}

_reordenar_modulos() {
    clear
    titulo "REORDENAR MÓDULOS"
    local id_curso
    id_curso=$(seleccionar_o_crear cursos nombre_curso id_curso "Curso" "" "" "orden")
    if [ -z "$id_curso" ]; then return; fi
    _reordenar_generico modulos nombre_modulo id_modulo "Módulo" id_curso "$id_curso" "MÓDULOS"
}

_reordenar_contenidos() {
    clear
    titulo "REORDENAR CONTENIDOS"
    local id_curso
    id_curso=$(seleccionar_o_crear cursos nombre_curso id_curso "Curso" "" "" "orden")
    if [ -z "$id_curso" ]; then return; fi
    clear
    titulo "REORDENAR CONTENIDOS"
    local id_modulo
    id_modulo=$(seleccionar_o_crear modulos nombre_modulo id_modulo "Módulo" id_curso "$id_curso" "orden")
    if [ -z "$id_modulo" ]; then return; fi
    _reordenar_generico contenidos titulo id_contenido "Contenido" id_modulo "$id_modulo" "CONTENIDOS"
}
