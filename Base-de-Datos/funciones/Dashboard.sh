#!/bin/bash
# =========================================================
# dashboard.sh - Resumen de progreso en la pantalla inicial
#
# IMPORTANTE: nada de esto se guarda en la base de datos.
# "Curso activo" y "% completado" se calculan al vuelo
# comparando contenidos totales vs Completados. Así, un
# curso desaparece solo de "Cursos activos" el día que
# marques su última actividad pendiente como Completada,
# sin que haya que programar ningún borrado.
# =========================================================

_formatear_horas() {
    local total_min="$1"
    total_min="${total_min%%.*}"   # trunca decimales (CAST AS REAL puede traer .0)
    [ -z "$total_min" ] && total_min=0
    local h=$((total_min / 60))
    local m=$((total_min % 60))
    if [ "$h" -gt 0 ]; then
        echo "${h}h ${m}m"
    else
        echo "${m}m"
    fi
}

mostrar_dashboard_resumen() {
    local fila total completados
    fila=$(db_row "SELECT COUNT(*), COALESCE(SUM(CASE WHEN estado='Completado' THEN 1 ELSE 0 END),0) FROM contenidos;")
    IFS='|' read -r total completados <<< "$fila"

    # Si todavía no hay contenidos cargados, no mostrar nada (evita una pantalla de puros ceros)
    if [ -z "$total" ] || [ "$total" = "0" ]; then
        return
    fi

    local porcentaje=$((completados * 100 / total))
    echo -e "${C_GRIS}Progreso general: ${completados}/${total} completados (${porcentaje}%)${C_RESET}"

    # --- Cursos activos: no 100% completados, ordenados por % de avance, top 4 ---
    local cursos_activos
    cursos_activos=$(db_row "
        SELECT c.nombre_curso,
               SUM(CASE WHEN co.estado='Completado' THEN 1 ELSE 0 END),
               COUNT(co.id_contenido)
        FROM cursos c
        JOIN modulos m ON m.id_curso = c.id_curso
        JOIN contenidos co ON co.id_modulo = m.id_modulo
        GROUP BY c.id_curso
        HAVING SUM(CASE WHEN co.estado='Completado' THEN 1 ELSE 0 END) < COUNT(co.id_contenido)
        ORDER BY (SUM(CASE WHEN co.estado='Completado' THEN 1 ELSE 0 END) * 1.0 / COUNT(co.id_contenido)) DESC
        LIMIT 4;
    ")

    if [ -n "$cursos_activos" ]; then
        echo -e "${C_GRIS}Cursos activos:${C_RESET}"
        while IFS='|' read -r nombre comp tot; do
            [ -z "$nombre" ] && continue
            echo -e "${C_GRIS}  - $nombre ($comp/$tot)${C_RESET}"
        done <<< "$cursos_activos"
    fi

    # --- Horas totales y por tipo de contenido, solo de lo Completado ---
    local id_prop_minutos
    id_prop_minutos=$(db_scalar "SELECT id_propiedad FROM propiedades_catalogo WHERE nombre_propiedad='minutos';")

    if [ -n "$id_prop_minutos" ]; then
        local total_minutos
        total_minutos=$(db_scalar "
            SELECT COALESCE(SUM(CAST(cp.valor AS REAL)),0)
            FROM contenido_propiedades cp
            JOIN contenidos co ON co.id_contenido = cp.id_contenido
            WHERE co.estado='Completado' AND cp.id_propiedad = $id_prop_minutos;
        ")

        if [ -n "$total_minutos" ] && [ "$total_minutos" != "0" ] && [ "$total_minutos" != "0.0" ]; then
            local horas_por_tipo linea_horas
            horas_por_tipo=$(db_row "
                SELECT t.nombre_tipo, SUM(CAST(cp.valor AS REAL))
                FROM contenidos co
                JOIN tipos_contenido t ON co.id_tipo = t.id_tipo
                JOIN contenido_propiedades cp ON cp.id_contenido = co.id_contenido AND cp.id_propiedad = $id_prop_minutos
                WHERE co.estado = 'Completado'
                GROUP BY t.id_tipo
                HAVING SUM(CAST(cp.valor AS REAL)) > 0;
            ")

            linea_horas="Horas: $(_formatear_horas "$total_minutos") total"
            while IFS='|' read -r tipo mins; do
                [ -z "$tipo" ] && continue
                linea_horas="${linea_horas}  |  ${tipo}: $(_formatear_horas "$mins")"
            done <<< "$horas_por_tipo"
            echo -e "${C_GRIS}${linea_horas}${C_RESET}"
        fi
    fi

    separador
}
