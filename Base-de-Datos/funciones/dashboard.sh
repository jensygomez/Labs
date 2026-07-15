#!/bin/bash
# =========================================================
# dashboard.sh - Resumen de progreso en la pantalla inicial
#
# IMPORTANTE: nada de esto se guarda en la base de datos.
# "Curso en progreso" y "% completado" se calculan al vuelo
# comparando contenidos totales vs Completados. Así, un
# curso desaparece solo de "Cursos en progreso" el día que
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

# Barra de progreso visual coloreada según el % (rojo bajo, amarillo medio, verde alto)
_barra_progreso() {
    local pct="$1" ancho=28
    local llenos=$((pct * ancho / 100))
    local vacios=$((ancho - llenos))
    local color="$C_ROJO"
    [ "$pct" -ge 40 ] && color="$C_AMARILLO_B"
    [ "$pct" -ge 80 ] && color="$C_VERDE_B"

    local barra=""
    local i
    for ((i=0; i<llenos; i++)); do barra+="█"; done
    echo -ne "${color}${barra}${C_RESET}"
    barra=""
    for ((i=0; i<vacios; i++)); do barra+="░"; done
    echo -e "${C_GRIS}${barra}${C_RESET}"
}

mostrar_dashboard_resumen() {
    local fila total completados
    fila=$(db_row "SELECT COUNT(*), COALESCE(SUM(CASE WHEN estado='Completado' THEN 1 ELSE 0 END),0) FROM contenidos;")
    IFS='|' read -r total completados <<< "$fila"

    if [ -z "$total" ] || [ "$total" = "0" ]; then
        return
    fi

    local porcentaje=$((completados * 100 / total))

    echo ""
    echo -ne "  ${C_CIAN_B}Progreso general${C_RESET}  ${C_BOLD}${completados}/${total}${C_RESET}  "
    _barra_progreso "$porcentaje"
    echo -e "  ${C_AMARILLO_B}${porcentaje}%${C_RESET}"
    echo ""

    # --- Obtener TODOS los cursos con su progreso ---
    local todos_cursos
    todos_cursos=$(db_row "
        SELECT c.id_curso, c.nombre_curso,
               SUM(CASE WHEN co.estado='Completado' THEN 1 ELSE 0 END) as comp,
               COUNT(co.id_contenido) as tot
        FROM cursos c
        JOIN modulos m ON m.id_curso = c.id_curso
        JOIN contenidos co ON co.id_modulo = m.id_modulo
        GROUP BY c.id_curso
        ORDER BY (SUM(CASE WHEN co.estado='Completado' THEN 1 ELSE 0 END) * 1.0 / COUNT(co.id_contenido)) DESC;
    ")

    # Separar cursos activos y completados
    local cursos_activos=""
    local cursos_completados=""
    local contador=1

    while IFS='|' read -r id nombre comp tot; do
        [ -z "$id" ] && continue
        
        if [ "$comp" -eq "$tot" ]; then
            # Curso completado (4 campos)
            cursos_completados+="${id}|${nombre}|${comp}|${tot}
    "
        else
            # Curso activo (5 campos: contador|id|nombre|comp|tot)
            cursos_activos+="${contador}|${id}|${nombre}|${comp}|${tot}
    "
            ((contador++))
        fi
    done <<< "$todos_cursos"

    # --- Sección: Cursos que deberías estudiar (activos) ---
    if [ -n "$cursos_activos" ]; then
        echo -e "  ${C_MAGENTA}📚 Cursos que deberías estudiar${C_RESET}"
        local num=1
        while IFS='|' read -r id nombre comp tot; do
            [ -z "$id" ] && continue
            local pct=$((comp * 100 / tot))
            echo -e "    ${C_BOLD}${num})${C_RESET} ${C_CIAN}${nombre}${C_RESET}  ${C_AMARILLO}(${comp}/${tot} - ${pct}%)${C_RESET}"
            ((num++))
        done <<< "$cursos_activos"
        echo ""
    fi

    # --- Sección: Cursos completados ---
    if [ -n "$cursos_completados" ]; then
        echo -e "  ${C_VERDE_B}✅ Cursos completados${C_RESET}"
        while IFS='|' read -r id nombre comp tot; do
            [ -z "$id" ] && continue
            echo -e "    ${C_VERDE}▸ ${nombre}${C_RESET}  ${C_GRIS}(${comp}/${tot})${C_RESET}"
        done <<< "$cursos_completados"
        echo ""
    fi

    # --- Horas totales ---
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
            local horas_por_tipo
            horas_por_tipo=$(db_row "
                SELECT t.nombre_tipo, SUM(CAST(cp.valor AS REAL))
                FROM contenidos co
                JOIN tipos_contenido t ON co.id_tipo = t.id_tipo
                JOIN contenido_propiedades cp ON cp.id_contenido = co.id_contenido AND cp.id_propiedad = $id_prop_minutos
                WHERE co.estado = 'Completado'
                GROUP BY t.id_tipo
                HAVING SUM(CAST(cp.valor AS REAL)) > 0;
            ")

            echo -ne "  ${C_VERDE_B}⏱ $(_formatear_horas "$total_minutos") totales${C_RESET}"
            local colores_tipo=("$C_AZUL" "$C_MAGENTA" "$C_CIAN" "$C_AMARILLO")
            local idx=0
            while IFS='|' read -r tipo mins; do
                [ -z "$tipo" ] && continue
                local color_actual="${colores_tipo[$((idx % 4))]}"
                echo -ne "   ${C_GRIS}|${C_RESET}  ${color_actual}${tipo}: $(_formatear_horas "$mins")${C_RESET}"
                idx=$((idx+1))
            done <<< "$horas_por_tipo"
            echo ""
            echo ""
        fi
    fi

    separador
}
