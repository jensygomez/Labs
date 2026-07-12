#!/bin/bash
# =========================================================
# common.sh - Funciones reutilizables en todo el sistema
# =========================================================
#
# CONVENCIÓN IMPORTANTE:
# Las funciones que "devuelven" un valor (para usar con $(...))
# escriben SOLO el resultado final por stdout. Todo el texto de
# interfaz (menús, prompts, mensajes) va a stderr con `>&2`.
# Así podés hacer: id=$(seleccionar_o_crear ...) sin que el
# menú se te cuele dentro de la variable.
# =========================================================

DB_NAME="progreso.db"

# =========================================================
# IMPORTANTE: cada llamada a `sqlite3` abre una conexión NUEVA.
# PRAGMA foreign_keys=ON no persiste entre llamadas, así que si
# no se repite en cada invocación, los ON DELETE CASCADE quedan
# desactivados en silencio. Estos wrappers lo garantizan siempre.
# =========================================================

# Para INSERT/UPDATE/DELETE (sin salida tabular)
db_exec() {
    sqlite3 "$DB_NAME" "PRAGMA foreign_keys = ON; $1"
}

# Para SELECT que se muestran al usuario en tabla
db_query() {
    sqlite3 "$DB_NAME" -column -header "PRAGMA foreign_keys = ON; $1"
}

# Para SELECT de un solo valor o con separador custom
db_scalar() {
    sqlite3 "$DB_NAME" "PRAGMA foreign_keys = ON; $1"
}

# Para SELECT de varias columnas que se desempaquetan con IFS='|' read
db_row() {
    sqlite3 "$DB_NAME" -separator '|' "PRAGMA foreign_keys = ON; $1"
}

# --- Escapar comillas simples para evitar romper el SQL / inyección básica ---
escapar_sql() {
    local input="$1"
    echo "${input//\'/\'\'}"
}

# --- Confirmación sí/no ---
confirmar() {
    local prompt="$1"
    local resp
    preguntar resp "$prompt (s/n): "
    [[ "$resp" =~ ^[sS]$ ]]
}

# --- Normaliza una lista de tags: trim, quita vacíos, dedup, conserva orden ---
normalizar_tags() {
    local input="$1"
    echo "$input" | tr ',' '\n' | sed 's/^[ \t]*//; s/[ \t]*$//' | grep -v '^$' | awk '!seen[$0]++' | paste -sd, -
}

# --- Si la propiedad guardada es "fecha", auto-marca el contenido como Completado ---
verificar_autocompletado() {
    local id_contenido="$1" nombre_prop="$2"
    if [ "$nombre_prop" = "fecha" ]; then
        local estado_actual
        estado_actual=$(db_scalar "SELECT estado FROM contenidos WHERE id_contenido=$id_contenido;")
        if [ "$estado_actual" != "Completado" ]; then
            db_exec "UPDATE contenidos SET estado='Completado' WHERE id_contenido=$id_contenido;"
            exito "Estado actualizado automáticamente a 'Completado' (por asignar fecha)." >&2
        fi
    fi
}

# =========================================================
# seleccionar_o_crear
# Lista los registros de una tabla, permite elegir uno o crear
# uno nuevo. Devuelve el ID real por stdout (nunca visible al usuario
# cuando hay orden_columna: se muestra un Nº de posición en su lugar).
#
# Uso simple (sin orden, muestra ID):
#   id_path=$(seleccionar_o_crear paths nombre_path id_path "Path")
#
# Con filtro:
#   id_mod=$(seleccionar_o_crear modulos nombre_modulo id_modulo "Módulo" id_curso "$id_curso" "orden")
#
# Si se pasa orden_columna (7mo argumento), la lista se muestra
# numerada según esa columna y el usuario elige por Nº, no por ID.
# =========================================================
seleccionar_o_crear() {
    local tabla="$1" columna="$2" id_columna="$3" etiqueta="$4"
    local col_filtro="$5" val_filtro="$6" orden_columna="$7"

    local where=""
    if [ -n "$col_filtro" ]; then
        where="WHERE $col_filtro=$val_filtro"
    fi

    while true; do
        echo -e "${C_AZUL}--- Selecciona un $etiqueta ---${C_RESET}" >&2
        local filas
        declare -A mapa_num

        if [ -n "$orden_columna" ]; then
            filas=$(db_row "SELECT ROW_NUMBER() OVER (ORDER BY $orden_columna, $id_columna), $id_columna, $columna FROM $tabla $where;")
            if [ -z "$filas" ]; then
                echo -e "${C_GRIS}[ No hay ${etiqueta}s registrados aún ]${C_RESET}" >&2
            else
                printf "${C_GRIS}%-4s %s${C_RESET}\n" "Nº" "$etiqueta" >&2
                while IFS='|' read -r num rid rnombre; do
                    printf "%-4s %s\n" "$num)" "$rnombre" >&2
                    mapa_num["$num"]="$rid"
                done <<< "$filas"
            fi
        else
            filas=$(db_query "SELECT $id_columna, $columna FROM $tabla $where ORDER BY $columna;")
            if [ -z "$filas" ]; then
                echo -e "${C_GRIS}[ No hay ${etiqueta}s registrados aún ]${C_RESET}" >&2
            else
                echo "$filas" >&2
            fi
        fi

        separador >&2
        echo -e "${C_AMARILLO}0) Crear nuevo $etiqueta${C_RESET}" >&2
        echo -e "${C_GRIS}q) Cancelar${C_RESET}" >&2
        separador >&2

        local sel
        if [ -n "$orden_columna" ]; then
            preguntar sel "Número (o 0 para nuevo, q para cancelar): "
        else
            preguntar sel "ID (o 0 para nuevo, q para cancelar): "
        fi

        if [ "$sel" = "q" ]; then
            unset mapa_num
            echo ""
            return 1
        elif [ "$sel" = "0" ]; then
            local nuevo
            preguntar nuevo "Nombre del nuevo $etiqueta: "
            if [ -z "$nuevo" ]; then
                error_msg "Nombre vacío, intenta de nuevo." >&2
                sleep 1
                unset mapa_num
                continue
            fi
            local nuevo_safe
            nuevo_safe=$(escapar_sql "$nuevo")
            local nuevo_id

            case "$tabla" in
                cursos)
                    # Los tags de un curso se heredan a todos sus módulos y lecciones
                    local tags_nuevos siguiente_orden_curso
                    preguntar tags_nuevos "Tags para este curso (separados por coma, se heredan a módulos y lecciones; opcional): "
                    tags_nuevos=$(normalizar_tags "$tags_nuevos")
                    siguiente_orden_curso=$(db_scalar "SELECT COALESCE(MAX(orden),0)+1 FROM cursos;")
                    db_exec "INSERT OR IGNORE INTO cursos (nombre_curso, tags, orden) VALUES ('$nuevo_safe', '$tags_nuevos', $siguiente_orden_curso);"
                    nuevo_id=$(db_scalar "SELECT id_curso FROM cursos WHERE nombre_curso='$nuevo_safe';")
                    ;;
                modulos)
                    # Hereda tags del curso padre + permite agregar propios; asigna la siguiente posición
                    local tags_heredados tags_propios tags_finales siguiente_orden
                    tags_heredados=$(db_scalar "SELECT tags FROM cursos WHERE id_curso=$val_filtro;")
                    [ -n "$tags_heredados" ] && info_msg "Tags heredados del curso: $tags_heredados" >&2
                    preguntar tags_propios "Tags adicionales para este módulo (opcional): "
                    tags_finales=$(normalizar_tags "${tags_heredados},${tags_propios}")
                    siguiente_orden=$(db_scalar "SELECT COALESCE(MAX(orden),0)+1 FROM modulos WHERE id_curso=$val_filtro;")
                    db_exec "INSERT INTO modulos (nombre_modulo, id_curso, tags, orden) VALUES ('$nuevo_safe', $val_filtro, '$tags_finales', $siguiente_orden);"
                    nuevo_id=$(db_scalar "SELECT id_modulo FROM modulos WHERE id_curso=$val_filtro ORDER BY id_modulo DESC LIMIT 1;")
                    ;;
                *)
                    if [ -n "$col_filtro" ]; then
                        db_exec "INSERT OR IGNORE INTO $tabla ($columna, $col_filtro) VALUES ('$nuevo_safe', $val_filtro);"
                        nuevo_id=$(db_scalar "SELECT $id_columna FROM $tabla WHERE $columna='$nuevo_safe' AND $col_filtro=$val_filtro ORDER BY $id_columna DESC LIMIT 1;")
                    else
                        db_exec "INSERT OR IGNORE INTO $tabla ($columna) VALUES ('$nuevo_safe');"
                        nuevo_id=$(db_scalar "SELECT $id_columna FROM $tabla WHERE $columna='$nuevo_safe';")
                    fi
                    ;;
            esac

            exito "'$nuevo' creado con éxito." >&2
            unset mapa_num
            echo "$nuevo_id"
            return 0
        else
            if [ -n "$orden_columna" ]; then
                if [ -n "$sel" ] && [ -n "${mapa_num[$sel]}" ]; then
                    local id_real="${mapa_num[$sel]}"
                    unset mapa_num
                    echo "$id_real"
                    return 0
                else
                    error_msg "Número inválido para $etiqueta." >&2
                    sleep 1
                fi
            else
                local existe
                existe=$(db_scalar "SELECT COUNT(*) FROM $tabla WHERE $id_columna=$sel $( [ -n "$col_filtro" ] && echo "AND $col_filtro=$val_filtro" );" 2>/dev/null)
                if [ "$existe" = "1" ]; then
                    unset mapa_num
                    echo "$sel"
                    return 0
                else
                    error_msg "ID inválido para $etiqueta." >&2
                    sleep 1
                fi
            fi
            unset mapa_num
        fi
    done
}

# =========================================================
# pedir_valor_tipado
# Pide un valor validado según el tipo de dato de la propiedad.
# Tipos: numero, fecha, tags, texto, base64
# Devuelve el valor (ya listo para guardar) por stdout.
# =========================================================
pedir_valor_tipado() {
    local tipo_dato="$1"
    local etiqueta="$2"
    local valor_actual="$3"   # opcional, para modo edición

    case "$tipo_dato" in
        numero)
            while true; do
                local v
                preguntar v "$etiqueta (número): "
                if [[ "$v" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
                    echo "$v"
                    return 0
                fi
                error_msg "Debe ser un número." >&2
            done
            ;;
        fecha)
            while true; do
                local v
                preguntar v "$etiqueta (formato YYYY-MM-DD, o 'hoy'): "
                if [ "$v" = "hoy" ]; then
                    date +%F
                    return 0
                elif [[ "$v" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                    echo "$v"
                    return 0
                fi
                error_msg "Formato inválido. Usa YYYY-MM-DD." >&2
            done
            ;;
        tags)
            local v nuevas
            if [ -n "$valor_actual" ]; then
                info_msg "Tags actuales: $valor_actual" >&2
                preguntar nuevas "$etiqueta - agregar tags (separados por coma, se suman a las existentes, ENTER para dejar igual): "
                if [ -z "$nuevas" ]; then
                    echo "$valor_actual"
                    return 0
                fi
                v="${valor_actual},${nuevas}"
            else
                preguntar v "$etiqueta (separados por coma, ej: netplan,dnat,vagrant): "
            fi
            v=$(normalizar_tags "$v")
            echo "$v"
            return 0
            ;;
        texto)
            local v
            preguntar v "$etiqueta: "
            echo "$v"
            return 0
            ;;
        base64)
            editar_valor_largo "$etiqueta" "$valor_actual"
            return 0
            ;;
        *)
            local v
            preguntar v "$etiqueta: "
            echo "$v"
            return 0
            ;;
    esac
}

# =========================================================
# editar_valor_largo
# Abre $EDITOR (o vi) sobre el contenido actual (decodificado),
# y al guardar devuelve el contenido re-codificado en base64
# por stdout. Ideal para pegar scripts, outputs largos, notas.
# =========================================================
editar_valor_largo() {
    local etiqueta="$1"
    local valor_actual_b64="$2"
    local tmpfile
    tmpfile=$(mktemp /tmp/lab_edit_XXXXXX.txt)

    if [ -n "$valor_actual_b64" ]; then
        echo "$valor_actual_b64" | base64 -d > "$tmpfile" 2>/dev/null
    fi

    info_msg "Abriendo editor para '$etiqueta' (guarda y sal para continuar)..." >&2
    sleep 1
    "${EDITOR:-vi}" "$tmpfile" >&2 2>&1

    local nuevo_valor
    nuevo_valor=$(base64 -w0 "$tmpfile")
    rm -f "$tmpfile"
    echo "$nuevo_valor"
}

# =========================================================
# seleccionar_o_crear_propiedad
# Variante especial de seleccionar_o_crear para el catálogo de
# propiedades: al crear una nueva, también pide su tipo_dato.
# Devuelve "id_propiedad|tipo_dato" por stdout.
# =========================================================
seleccionar_o_crear_propiedad() {
    while true; do
        echo -e "${C_AZUL}--- Selecciona una propiedad ---${C_RESET}" >&2
        local filas
        filas=$(db_query "SELECT id_propiedad, nombre_propiedad, tipo_dato FROM propiedades_catalogo ORDER BY nombre_propiedad;")
        if [ -z "$filas" ]; then
            echo -e "${C_GRIS}[ No hay propiedades registradas aún ]${C_RESET}" >&2
        else
            echo "$filas" >&2
        fi
        separador >&2
        echo -e "${C_AMARILLO}0) Crear nueva propiedad${C_RESET}" >&2
        echo -e "${C_GRIS}q) Terminar de agregar propiedades${C_RESET}" >&2
        separador >&2

        local sel
        preguntar sel "ID (o 0 para nueva, q para terminar): "

        if [ "$sel" = "q" ]; then
            echo ""
            return 1
        elif [ "$sel" = "0" ]; then
            local nombre_prop
            preguntar nombre_prop "Nombre de la nueva propiedad (ej: dificultad, ruta_repo): "
            if [ -z "$nombre_prop" ]; then
                error_msg "Nombre vacío." >&2; sleep 1; continue
            fi
            echo -e "${C_AZUL}Tipo de dato:${C_RESET}" >&2
            echo "  1) numero" >&2
            echo "  2) fecha" >&2
            echo "  3) tags" >&2
            echo "  4) texto" >&2
            echo "  5) base64 (para contenido largo: scripts, outputs, notas)" >&2
            local tipo_sel tipo_dato
            preguntar tipo_sel "Selecciona [1-5]: "
            case "$tipo_sel" in
                1) tipo_dato="numero" ;;
                2) tipo_dato="fecha" ;;
                3) tipo_dato="tags" ;;
                4) tipo_dato="texto" ;;
                5) tipo_dato="base64" ;;
                *) error_msg "Opción inválida, se usará 'texto' por defecto." >&2; tipo_dato="texto" ;;
            esac

            local nombre_safe
            nombre_safe=$(escapar_sql "$nombre_prop")
            db_exec "INSERT OR IGNORE INTO propiedades_catalogo (nombre_propiedad, tipo_dato) VALUES ('$nombre_safe', '$tipo_dato');"
            local nuevo_id
            nuevo_id=$(db_scalar "SELECT id_propiedad FROM propiedades_catalogo WHERE nombre_propiedad='$nombre_safe';")
            exito "Propiedad '$nombre_prop' ($tipo_dato) creada." >&2
            echo "${nuevo_id}|${tipo_dato}"
            return 0
        else
            local fila
            fila=$(db_row "SELECT id_propiedad, tipo_dato FROM propiedades_catalogo WHERE id_propiedad=$sel;")
            if [ -n "$fila" ]; then
                echo "$fila"
                return 0
            else
                error_msg "ID inválido." >&2; sleep 1
            fi
        fi
    done
}

# Muestra el valor de una propiedad de forma legible según su tipo
# (para pantallas de "ver detalle")
mostrar_valor_propiedad() {
    local tipo_dato="$1"
    local valor="$2"
    case "$tipo_dato" in
        base64)
            local bytes
            bytes=$(echo "$valor" | base64 -d 2>/dev/null | wc -c)
            echo -e "${C_GRIS}[contenido largo, $bytes bytes — usa 'Editar' para verlo en vi]${C_RESET}"
            ;;
        *)
            echo "$valor"
            ;;
    esac
}
