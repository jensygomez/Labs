#!/bin/bash
# =========================================================
# menu_contenido.sh - Wizard unificado "Agregar Nuevo"
# =========================================================

agregar_nuevo_contenido() {
    clear
    titulo "AGREGAR NUEVO CONTENIDO"
    info_msg "Te voy a guiar paso a paso. En cada paso podés elegir algo existente o crear uno nuevo."
    echo ""

    # --- Paso 1: Path ---
    local id_path
    id_path=$(seleccionar_o_crear paths nombre_path id_path "Path")
    if [ -z "$id_path" ]; then advertencia "Cancelado."; pausa; return; fi

    # --- Paso 2: Curso (no filtrado por path, un curso puede vivir en varios paths) ---
    clear
    titulo "AGREGAR NUEVO CONTENIDO"
    local id_curso
    id_curso=$(seleccionar_o_crear cursos nombre_curso id_curso "Curso" "" "" "orden")
    if [ -z "$id_curso" ]; then advertencia "Cancelado."; pausa; return; fi

    # Asegurar el vínculo curso <-> path (idempotente, no duplica)
    db_exec "INSERT OR IGNORE INTO path_cursos (id_path, id_curso) VALUES ($id_path, $id_curso);"

    # --- Paso 3: Módulo (filtrado por el curso elegido) ---
    clear
    titulo "AGREGAR NUEVO CONTENIDO"
    local id_modulo
    id_modulo=$(seleccionar_o_crear modulos nombre_modulo id_modulo "Módulo" id_curso "$id_curso" "orden")
    if [ -z "$id_modulo" ]; then advertencia "Cancelado."; pausa; return; fi

    # --- Paso 4: Tipo de contenido ---
    clear
    titulo "AGREGAR NUEVO CONTENIDO"
    local id_tipo
    id_tipo=$(seleccionar_o_crear tipos_contenido nombre_tipo id_tipo "Tipo de Contenido")
    if [ -z "$id_tipo" ]; then advertencia "Cancelado."; pausa; return; fi

    # --- Paso 5: Título ---
    clear
    titulo "AGREGAR NUEVO CONTENIDO"
    local titulo_contenido
    preguntar titulo_contenido "Título del contenido (ej: NET-005 - NAT Vagrant/libvirt): "
    if [ -z "$titulo_contenido" ]; then
        error_msg "Título vacío, se cancela la operación."
        pausa; return
    fi
    local titulo_safe
    titulo_safe=$(escapar_sql "$titulo_contenido")

    local siguiente_orden
    siguiente_orden=$(db_scalar "SELECT COALESCE(MAX(orden),0)+1 FROM contenidos WHERE id_modulo=$id_modulo;")
    db_exec "INSERT INTO contenidos (id_modulo, id_tipo, titulo, orden) VALUES ($id_modulo, $id_tipo, '$titulo_safe', $siguiente_orden); SELECT last_insert_rowid();"
    local id_contenido
    id_contenido=$(db_scalar "SELECT id_contenido FROM contenidos WHERE id_modulo=$id_modulo ORDER BY id_contenido DESC LIMIT 1;")
    exito "Contenido '$titulo_contenido' creado."
    sleep 1

    # Heredar automáticamente los tags del módulo (que ya incluyen los del curso)
    local tags_heredados_mod
    tags_heredados_mod=$(db_scalar "SELECT tags FROM modulos WHERE id_modulo=$id_modulo;")
    if [ -n "$tags_heredados_mod" ]; then
        local id_prop_tags
        id_prop_tags=$(db_scalar "SELECT id_propiedad FROM propiedades_catalogo WHERE nombre_propiedad='tags';")
        if [ -n "$id_prop_tags" ]; then
            db_exec "INSERT INTO contenido_propiedades (id_contenido, id_propiedad, valor)
                     VALUES ($id_contenido, $id_prop_tags, '$tags_heredados_mod')
                     ON CONFLICT(id_contenido, id_propiedad) DO UPDATE SET valor=excluded.valor;"
            info_msg "Tags heredados automáticamente: $tags_heredados_mod"
            sleep 1
        fi
    fi

    # --- Paso 6: Propiedades (loop) ---
    while true; do
        clear
        titulo "PROPIEDADES DE: $titulo_contenido"
        local props_actuales
        props_actuales=$(db_query "
            SELECT pc.nombre_propiedad AS propiedad, pc.tipo_dato AS tipo,
                   CASE WHEN pc.tipo_dato='base64' THEN '[contenido largo]' ELSE cp.valor END AS valor
            FROM contenido_propiedades cp
            JOIN propiedades_catalogo pc ON cp.id_propiedad = pc.id_propiedad
            WHERE cp.id_contenido = $id_contenido;
        ")
        if [ -z "$props_actuales" ]; then
            info_msg "[ Todavía no agregaste propiedades a este contenido ]"
        else
            echo "$props_actuales"
        fi
        separador
        if ! confirmar "¿Agregar una propiedad?"; then
            break
        fi

        local resultado id_propiedad tipo_dato
        resultado=$(seleccionar_o_crear_propiedad)
        if [ -z "$resultado" ]; then
            continue
        fi
        id_propiedad="${resultado%%|*}"
        tipo_dato="${resultado##*|}"

        local nombre_prop
        nombre_prop=$(db_exec "SELECT nombre_propiedad FROM propiedades_catalogo WHERE id_propiedad=$id_propiedad;")

        local valor_previo
        valor_previo=$(db_exec "SELECT valor FROM contenido_propiedades WHERE id_contenido=$id_contenido AND id_propiedad=$id_propiedad;")

        local valor
        valor=$(pedir_valor_tipado "$tipo_dato" "$nombre_prop" "$valor_previo")
        local valor_safe
        valor_safe=$(escapar_sql "$valor")

        db_exec "INSERT INTO contenido_propiedades (id_contenido, id_propiedad, valor)
                             VALUES ($id_contenido, $id_propiedad, '$valor_safe')
                             ON CONFLICT(id_contenido, id_propiedad) DO UPDATE SET valor=excluded.valor;"
        exito "Propiedad '$nombre_prop' guardada."
        verificar_autocompletado "$id_contenido" "$nombre_prop"
        sleep 1
    done

    exito "¡Contenido '$titulo_contenido' completo!"
    pausa
}
