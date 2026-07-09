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

# =========================================================
# seleccionar_o_crear
# Lista los registros de una tabla, permite elegir uno por ID
# o crear uno nuevo si no existe. Devuelve el ID por stdout.
#
# Uso:
#   id_path=$(seleccionar_o_crear paths nombre_path id_path "Path")
#
# Con filtro (ej. módulos de un curso específico):
#   id_mod=$(seleccionar_o_crear modulos nombre_modulo id_modulo "Módulo" id_curso "$id_curso")
# =========================================================
seleccionar_o_crear() {
    local tabla="$1" columna="$2" id_columna="$3" etiqueta="$4"
    local col_filtro="$5" val_filtro="$6"

    local where=""
    if [ -n "$col_filtro" ]; then
        where="WHERE $col_filtro=$val_filtro"
    fi

    while true; do
        echo -e "${C_AZUL}--- Selecciona un $etiqueta ---${C_RESET}" >&2
        local filas
        filas=$(db_query "SELECT $id_columna, $columna FROM $tabla $where ORDER BY $columna;")
        if [ -z "$filas" ]; then
            echo -e "${C_GRIS}[ No hay ${etiqueta}s registrados aún ]${C_RESET}" >&2
        else
            echo "$filas" >&2
        fi
        separador >&2
        echo -e "${C_AMARILLO}0) Crear nuevo $etiqueta${C_RESET}" >&2
        echo -e "${C_GRIS}q) Cancelar${C_RESET}" >&2
        separador >&2

        local sel
        preguntar sel "ID (o 0 para nuevo, q para cancelar): "

        if [ "$sel" = "q" ]; then
            echo ""   # ID vacío = cancelado
            return 1
        elif [ "$sel" = "0" ]; then
            local nuevo
            preguntar nuevo "Nombre del nuevo $etiqueta: "
            if [ -z "$nuevo" ]; then
                error_msg "Nombre vacío, intenta de nuevo." >&2
                sleep 1
                continue
            fi
            local nuevo_safe
            nuevo_safe=$(escapar_sql "$nuevo")

            if [ -n "$col_filtro" ]; then
                db_exec "INSERT OR IGNORE INTO $tabla ($columna, $col_filtro) VALUES ('$nuevo_safe', $val_filtro);"
            else
                db_exec "INSERT OR IGNORE INTO $tabla ($columna) VALUES ('$nuevo_safe');"
            fi

            local nuevo_id
            nuevo_id=$(db_scalar "SELECT $id_columna FROM $tabla WHERE $columna='$nuevo_safe' $( [ -n "$col_filtro" ] && echo "AND $col_filtro=$val_filtro" ) ORDER BY $id_columna DESC LIMIT 1;")
            exito "'$nuevo' creado con ID $nuevo_id" >&2
            echo "$nuevo_id"
            return 0
        else
            local existe
            existe=$(db_scalar "SELECT COUNT(*) FROM $tabla WHERE $id_columna=$sel $( [ -n "$col_filtro" ] && echo "AND $col_filtro=$val_filtro" );" 2>/dev/null)
            if [ "$existe" = "1" ]; then
                echo "$sel"
                return 0
            else
                error_msg "ID inválido para $etiqueta." >&2
                sleep 1
            fi
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
            # Normaliza espacios, quita vacíos y duplicados, conserva el orden de aparición
            v=$(echo "$v" | tr ',' '\n' | sed 's/^[ \t]*//; s/[ \t]*$//' | grep -v '^$' | awk '!seen[$0]++' | paste -sd, -)
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