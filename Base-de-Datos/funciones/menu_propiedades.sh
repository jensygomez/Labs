#!/bin/bash
# =========================================================
# menu_propiedades.sh - Gestión del catálogo de propiedades
# =========================================================

mostrar_menu_propiedades() {
    while true; do
        clear
        titulo "CATÁLOGO DE PROPIEDADES"
        db_query "
            SELECT
                pc.id_propiedad AS ID,
                pc.nombre_propiedad AS Propiedad,
                pc.tipo_dato AS Tipo,
                COUNT(cp.id_contenido) AS 'En uso'
            FROM propiedades_catalogo pc
            LEFT JOIN contenido_propiedades cp ON pc.id_propiedad = cp.id_propiedad
            GROUP BY pc.id_propiedad
            ORDER BY pc.nombre_propiedad;
        "
        separador
        echo "1) Crear nueva propiedad"
        echo "2) Eliminar propiedad (solo si no está en uso)"
        echo "3) Volver al Menú Principal"
        separador
        local opt
        preguntar opt "Selecciona una opción: "

        case $opt in
            1)
                clear
                titulo "NUEVA PROPIEDAD"
                seleccionar_o_crear_propiedad > /dev/null
                ;;
            2)
                clear
                local target_id
                preguntar target_id "ID de la propiedad a eliminar: "
                local en_uso
                en_uso=$(db_exec "SELECT COUNT(*) FROM contenido_propiedades WHERE id_propiedad=$target_id;")
                if [ "$en_uso" != "0" ]; then
                    error_msg "No se puede eliminar: está en uso en $en_uso contenido(s)."
                else
                    db_exec "DELETE FROM propiedades_catalogo WHERE id_propiedad=$target_id;"
                    exito "Propiedad eliminada."
                fi
                pausa
                ;;
            3) return ;;
            *) error_msg "Opción inválida"; sleep 1 ;;
        esac
    done
}
