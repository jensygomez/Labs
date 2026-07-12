#!/bin/bash
# =========================================================
# menu_progreso.sh - Consultas y actualización de progreso
# =========================================================

mostrar_menu_progreso() {
    while true; do
        clear
        titulo "MI PROGRESO ACTUAL"
        echo "1) Ver todas mis Rutas (Paths)"
        echo "2) Ver estado de un Curso"
        echo "3) Actualizar Estado de un Contenido"
        echo "4) Ver / Editar Detalle de un Contenido"
        echo "5) Volver al Menú Principal"
        separador
        local opt_progreso
        preguntar opt_progreso "Selecciona una opción: "

        case $opt_progreso in
            1) ver_paths ;;
            2) ver_estado_curso ;;
            3) actualizar_estado_contenido ;;
            4) ver_detalle_contenido ;;
            5) return ;;
            *) error_msg "Opción inválida"; sleep 1 ;;
        esac
    done
}

ver_paths() {
    clear
    titulo "MIS RUTAS (PATHS)"
    db_query "
        SELECT
            p.nombre_path AS Path,
            COUNT(DISTINCT c.id_curso) AS Cursos,
            COUNT(DISTINCT co.id_contenido) AS Contenidos,
            SUM(CASE WHEN co.estado='Completado' THEN 1 ELSE 0 END) AS Completados
        FROM paths p
        LEFT JOIN path_cursos pc ON p.id_path = pc.id_path
        LEFT JOIN cursos c ON pc.id_curso = c.id_curso
        LEFT JOIN modulos m ON m.id_curso = c.id_curso
        LEFT JOIN contenidos co ON co.id_modulo = m.id_modulo
        GROUP BY p.id_path
        ORDER BY p.nombre_path;
    "
    pausa
}

ver_estado_curso() {
    clear
    titulo "VER ESTADO DE UN CURSO"
    local id_curso
    id_curso=$(seleccionar_o_crear cursos nombre_curso id_curso "Curso" "" "" "orden")
    if [ -z "$id_curso" ]; then return; fi

    local nombre_curso
    nombre_curso=$(db_exec "SELECT nombre_curso FROM cursos WHERE id_curso=$id_curso;")

    clear
    titulo "CURSO: $nombre_curso"
    db_query "
        SELECT
            m.nombre_modulo AS Modulo,
            t.nombre_tipo AS Tipo,
            co.titulo AS Titulo,
            co.estado AS Estado
        FROM modulos m
        JOIN contenidos co ON co.id_modulo = m.id_modulo
        JOIN tipos_contenido t ON co.id_tipo = t.id_tipo
        WHERE m.id_curso = $id_curso
        ORDER BY m.nombre_modulo, co.id_contenido;
    "
    separador
    db_query "
        SELECT
            COUNT(*) AS Total,
            SUM(CASE WHEN co.estado='Completado' THEN 1 ELSE 0 END) AS Completados,
            SUM(CASE WHEN co.estado='En Progreso' THEN 1 ELSE 0 END) AS EnProgreso,
            SUM(CASE WHEN co.estado='Pendiente' THEN 1 ELSE 0 END) AS Pendientes
        FROM modulos m
        JOIN contenidos co ON co.id_modulo = m.id_modulo
        WHERE m.id_curso = $id_curso;
    "
    pausa
}

# Navega Curso -> Módulo -> Contenido y devuelve id_contenido por stdout
# (Se omite filtrar por Path porque un curso puede pertenecer a varios paths
# a la vez — el path es solo organizativo, no un filtro estricto de cursos)
_navegar_a_contenido() {
    local id_curso id_modulo id_contenido

    { clear; titulo "NAVEGAR"; } >&2
    id_curso=$(seleccionar_o_crear cursos nombre_curso id_curso "Curso" "" "" "orden")
    [ -z "$id_curso" ] && return 1

    { clear; titulo "NAVEGAR"; } >&2
    id_modulo=$(seleccionar_o_crear modulos nombre_modulo id_modulo "Módulo" id_curso "$id_curso" "orden")
    [ -z "$id_modulo" ] && return 1

    { clear; titulo "NAVEGAR"; } >&2
    echo -e "${C_AZUL}--- Selecciona un Contenido ---${C_RESET}" >&2
    local filas
    filas=$(db_row "SELECT ROW_NUMBER() OVER (ORDER BY orden, id_contenido), id_contenido, titulo, estado FROM contenidos WHERE id_modulo=$id_modulo;")
    declare -A mapa_cont
    if [ -z "$filas" ]; then
        echo -e "${C_GRIS}[ No hay contenidos en este módulo ]${C_RESET}" >&2
        unset mapa_cont
        return 1
    fi
    printf "${C_GRIS}%-4s %-45s %s${C_RESET}\n" "Nº" "Título" "Estado" >&2
    while IFS='|' read -r num rid rtitulo restado; do
        printf "%-4s %-45s %s\n" "$num)" "$rtitulo" "$restado" >&2
        mapa_cont["$num"]="$rid"
    done <<< "$filas"
    separador >&2
    local sel
    preguntar sel "Número del Contenido (o vacío para cancelar): "
    if [ -z "$sel" ] || [ -z "${mapa_cont[$sel]}" ]; then
        unset mapa_cont
        return 1
    fi
    id_contenido="${mapa_cont[$sel]}"
    unset mapa_cont
    echo "$id_contenido"
}

actualizar_estado_contenido() {
    clear
    titulo "ACTUALIZAR ESTADO DE UN CONTENIDO"
    local id_contenido
    id_contenido=$(_navegar_a_contenido)
    if [ -z "$id_contenido" ]; then advertencia "Cancelado."; pausa; return; fi

    local existe
    existe=$(db_exec "SELECT COUNT(*) FROM contenidos WHERE id_contenido=$id_contenido;")
    if [ "$existe" != "1" ]; then error_msg "ID inválido."; pausa; return; fi

    clear
    titulo "NUEVO ESTADO"
    echo "1) Pendiente"
    echo "2) En Progreso"
    echo "3) Completado"
    local sel nuevo_estado
    preguntar sel "Selecciona [1-3]: "
    case "$sel" in
        1) nuevo_estado="Pendiente" ;;
        2) nuevo_estado="En Progreso" ;;
        3) nuevo_estado="Completado" ;;
        *) error_msg "Opción inválida."; pausa; return ;;
    esac

    db_exec "UPDATE contenidos SET estado='$nuevo_estado' WHERE id_contenido=$id_contenido;"
    exito "Estado actualizado a '$nuevo_estado'."
    pausa
}

ver_detalle_contenido() {
    clear
    titulo "VER / EDITAR DETALLE DE UN CONTENIDO"
    local id_contenido
    id_contenido=$(_navegar_a_contenido)
    if [ -z "$id_contenido" ]; then return; fi

    while true; do
        clear
        local info
        info=$(db_row "
            SELECT co.titulo, t.nombre_tipo, co.estado, m.nombre_modulo, c.nombre_curso
            FROM contenidos co
            JOIN tipos_contenido t ON co.id_tipo = t.id_tipo
            JOIN modulos m ON co.id_modulo = m.id_modulo
            JOIN cursos c ON m.id_curso = c.id_curso
            WHERE co.id_contenido = $id_contenido;
        ")
        IFS='|' read -r v_titulo v_tipo v_estado v_modulo v_curso <<< "$info"

        titulo "$v_titulo"
        echo -e "${C_GRIS}Curso: $v_curso  |  Módulo: $v_modulo  |  Tipo: $v_tipo  |  Estado: $v_estado${C_RESET}"
        separador

        # Listar propiedades con índice numérico para poder editarlas
        local props
        props=$(db_row "
            SELECT pc.id_propiedad, pc.nombre_propiedad, pc.tipo_dato, cp.valor
            FROM contenido_propiedades cp
            JOIN propiedades_catalogo pc ON cp.id_propiedad = pc.id_propiedad
            WHERE cp.id_contenido = $id_contenido
            ORDER BY pc.nombre_propiedad;
        ")

        declare -A mapa_id
        local n=1
        if [ -z "$props" ]; then
            info_msg "[ Sin propiedades registradas ]"
        else
            while IFS='|' read -r pid pnombre ptipo pvalor; do
                local mostrado
                mostrado=$(mostrar_valor_propiedad "$ptipo" "$pvalor")
                echo -e "  ${C_AMARILLO}$n)${C_RESET} $pnombre ${C_GRIS}($ptipo)${C_RESET}: $mostrado"
                mapa_id[$n]="$pid|$ptipo|$pnombre"
                n=$((n+1))
            done <<< "$props"
        fi
        separador
        echo "e) Editar una propiedad (por número)"
        echo "a) Agregar propiedad nueva"
        echo "q) Volver"
        separador
        local sel
        preguntar sel "Selecciona: "

        case "$sel" in
            q) unset mapa_id; return ;;
            a)
                local resultado id_propiedad tipo_dato nombre_prop valor_previo valor valor_safe
                resultado=$(seleccionar_o_crear_propiedad)
                [ -z "$resultado" ] && continue
                id_propiedad="${resultado%%|*}"
                tipo_dato="${resultado##*|}"
                nombre_prop=$(db_exec "SELECT nombre_propiedad FROM propiedades_catalogo WHERE id_propiedad=$id_propiedad;")
                valor_previo=$(db_exec "SELECT valor FROM contenido_propiedades WHERE id_contenido=$id_contenido AND id_propiedad=$id_propiedad;")
                valor=$(pedir_valor_tipado "$tipo_dato" "$nombre_prop" "$valor_previo")
                valor_safe=$(escapar_sql "$valor")
                db_exec "INSERT INTO contenido_propiedades (id_contenido, id_propiedad, valor)
                                     VALUES ($id_contenido, $id_propiedad, '$valor_safe')
                                     ON CONFLICT(id_contenido, id_propiedad) DO UPDATE SET valor=excluded.valor;"
                exito "Guardado."
                verificar_autocompletado "$id_contenido" "$nombre_prop"
                sleep 1
                ;;
            e)
                local num
                preguntar num "Número de propiedad a editar: "
                if [ -z "${mapa_id[$num]}" ]; then
                    error_msg "Número inválido."; sleep 1; continue
                fi
                IFS='|' read -r ed_id ed_tipo ed_nombre <<< "${mapa_id[$num]}"
                local valor_actual valor_nuevo valor_safe
                valor_actual=$(db_exec "SELECT valor FROM contenido_propiedades WHERE id_contenido=$id_contenido AND id_propiedad=$ed_id;")
                valor_nuevo=$(pedir_valor_tipado "$ed_tipo" "$ed_nombre" "$valor_actual")
                valor_safe=$(escapar_sql "$valor_nuevo")
                db_exec "UPDATE contenido_propiedades SET valor='$valor_safe' WHERE id_contenido=$id_contenido AND id_propiedad=$ed_id;"
                exito "'$ed_nombre' actualizado."
                verificar_autocompletado "$id_contenido" "$ed_nombre"
                sleep 1
                ;;
            *) error_msg "Opción inválida."; sleep 1 ;;
        esac
    done
}
