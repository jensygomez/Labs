#!/bin/bash
# =========================================================
# importar_csv.sh - Importador dinámico desde CSV a SQLite
# Con auto-detección de módulo y tipo de contenido
# =========================================================
cd "$(dirname "$0")"
source ./funciones/colores.sh
source ./funciones/common.sh
source ./funciones/db_init.sh   # idempotente

# =========================================================
# 1. Preguntar ruta del CSV
# =========================================================
echo -e "
${C_AZUL}=== IMPORTADOR DESDE CSV ===${C_RESET}"
read -p "Ruta del archivo CSV a importar: " csv_path
if [ ! -f "$csv_path" ]; then
    error_msg "Archivo no encontrado: $csv_path"
    exit 1
fi
info_msg "Usando: $csv_path"

# =========================================================
# 2. Seleccionar / crear Path y Curso (SOLO estos dos)
# =========================================================
echo -e "
${C_AZUL}--- Selecciona o crea el contexto para los contenidos ---${C_RESET}"

# Path
id_path=$(seleccionar_o_crear paths nombre_path id_path "Path")
[ -z "$id_path" ] && { advertencia "Cancelado."; exit 1; }

# Curso
id_curso=$(seleccionar_o_crear cursos nombre_curso id_curso "Curso" "" "" "orden")
[ -z "$id_curso" ] && { advertencia "Cancelado."; exit 1; }

db_exec "INSERT OR IGNORE INTO path_cursos (id_path, id_curso) VALUES ($id_path, $id_curso);"

# =========================================================
# 2.5 Estado inicial
# =========================================================
echo -e "
${C_AZUL}--- Selecciona el Estado inicial para todos los registros ---${C_RESET}"
echo "1) Pendiente"
echo "2) En Progreso"
echo "3) Completado"
echo "-----------------------------------------"
read -p "Selecciona [1-3] (por defecto 1): " opcion_estado

case "$opcion_estado" in
    2) estado_inicial="En Progreso" ;;
    3) estado_inicial="Completado" ;;
    *) estado_inicial="Pendiente" ;;
esac

info_msg "Estado inicial: $estado_inicial"

# =========================================================
# 3. Obtener IDs de tipos de contenido para auto-detección
# =========================================================
id_video=$(db_scalar "SELECT id_tipo FROM tipos_contenido WHERE nombre_tipo='Video';")
id_lectura=$(db_scalar "SELECT id_tipo FROM tipos_contenido WHERE nombre_tipo='Lectura';")
id_lab=$(db_scalar "SELECT id_tipo FROM tipos_contenido WHERE nombre_tipo='Laboratorio';")
id_simulacro=$(db_scalar "SELECT id_tipo FROM tipos_contenido WHERE nombre_tipo='Simulacro';")

# =========================================================
# 3.1 Función para detectar tipo de contenido por título
# =========================================================
detectar_tipo() {
    local titulo_lower=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$titulo_lower" =~ lab[:\ -] ]] || [[ "$titulo_lower" =~ lab$ ]]; then
        echo "$id_lab"
        return
    fi
    
    if [[ "$titulo_lower" =~ quiz ]]; then
        echo "$id_simulacro"
        return
    fi
    
    if [[ "$titulo_lower" =~ article ]]; then
        echo "$id_lectura"
        return
    fi
    
    echo "$id_video"
}

# =========================================================
# 3.2 Función para obtener/crear módulo automáticamente
# =========================================================
obtener_o_crear_modulo() {
    local nombre_modulo="$1"
    local nombre_safe=$(escapar_sql "$nombre_modulo")
    
    # Buscar si ya existe
    local id_existente=$(db_scalar "SELECT id_modulo FROM modulos WHERE id_curso=$id_curso AND nombre_modulo='$nombre_safe';")
    
    if [ -n "$id_existente" ]; then
        echo "$id_existente"
        return
    fi
    
    # Crear nuevo módulo
    local siguiente_orden=$(db_scalar "SELECT COALESCE(MAX(orden),0)+1 FROM modulos WHERE id_curso=$id_curso;")
    local tags_curso=$(db_scalar "SELECT tags FROM cursos WHERE id_curso=$id_curso;")
    
    db_exec "INSERT INTO modulos (id_curso, nombre_modulo, tags, orden) VALUES ($id_curso, '$nombre_safe', '$tags_curso', $siguiente_orden);"
    
    local id_nuevo=$(db_scalar "SELECT id_modulo FROM modulos WHERE id_curso=$id_curso AND nombre_modulo='$nombre_safe';")
    echo "$id_nuevo"
}

# =========================================================
# 4. Obtener IDs de propiedades
# =========================================================
id_dificultad=$(db_scalar "SELECT id_propiedad FROM propiedades_catalogo WHERE nombre_propiedad='dificultad';")
id_level=$(db_scalar "SELECT id_propiedad FROM propiedades_catalogo WHERE nombre_propiedad='Level Scalation';")
id_minutos=$(db_scalar "SELECT id_propiedad FROM propiedades_catalogo WHERE nombre_propiedad='minutos';")
id_fecha=$(db_scalar "SELECT id_propiedad FROM propiedades_catalogo WHERE nombre_propiedad='fecha';")
id_tags=$(db_scalar "SELECT id_propiedad FROM propiedades_catalogo WHERE nombre_propiedad='tags';")

for id in "$id_dificultad" "$id_level" "$id_minutos" "$id_fecha"; do
    if [ -z "$id" ]; then
        error_msg "Falta una propiedad necesaria en el catálogo."
        exit 1
    fi
done

# =========================================================
# 5. Función auxiliar para parsear CSV
# =========================================================
parsear_campo() {
    local linea="$1"
    local campo="$2"
    echo "$linea" | awk -v FPAT='([^,]*)|("[^"]*")' -v n="$campo" '{
        val = $n
        gsub(/^"|"$/, "", val)
        gsub(/""/, "\"", val)
        print val
    }'
}

# =========================================================
# 6. Leer el CSV línea por línea (6 columnas ahora)
# =========================================================
total=0
importados=0
errores=0
modulo_actual=""
id_modulo_actual=""
modulos_creados=0
modulos_usados=0
# String delimitado para trackear módulos visitados (evita problemas con espacios)
modulos_visitados="|"

info_msg "Auto-detección: Módulo desde CSV | Tipo por título (Lab/Quiz/Article/Video)"
echo ""

while IFS= read -r line; do
    [ -z "$line" ] && continue
    
    # CSV con 6 columnas: Module,Title,Difficulty,Level,Duration,Date
    nombre_modulo=$(parsear_campo "$line" 1)
    titulo=$(parsear_campo "$line" 2)
    dificultad=$(parsear_campo "$line" 3)
    nivel=$(parsear_campo "$line" 4)
    minutos=$(parsear_campo "$line" 5)
    fecha=$(parsear_campo "$line" 6)
    
    # Limpiar espacios
    nombre_modulo=$(echo "$nombre_modulo" | xargs)
    titulo=$(echo "$titulo" | xargs)
    dificultad=$(echo "$dificultad" | xargs)
    nivel=$(echo "$nivel" | xargs)
    minutos=$(echo "$minutos" | xargs)
    fecha=$(echo "$fecha" | xargs)
    
    [ -z "$titulo" ] && { ((errores++)); continue; }
    
    # Validar minutos
    if ! [[ "$minutos" =~ ^[0-9]+$ ]]; then
        minutos=0
    fi
    
        # 🎯 Detectar cambio de módulo
    if [ "$nombre_modulo" != "$modulo_actual" ]; then
        modulo_actual="$nombre_modulo"
        
        # Verificar si este módulo ya fue procesado en esta ejecución
        # IMPORTANTE: Antes de crear/obtener, verificar si tiene contenidos
        local ya_existe_en_db=$(db_scalar "SELECT id_modulo FROM modulos WHERE id_curso=$id_curso AND nombre_modulo='$(escapar_sql "$nombre_modulo")';")
        
        id_modulo_actual=$(obtener_o_crear_modulo "$nombre_modulo")
        
        # Mostrar encabezado del nuevo módulo
        echo -e "
${C_AMARILLO}📁 Módulo: $nombre_modulo (ID: $id_modulo_actual)${C_RESET}"
        
        # Contar si es nuevo o reutilizado (solo la primera vez que aparece en el CSV)
        if [[ "$modulos_visitados" != *"|$nombre_modulo|"* ]]; then
            modulos_visitados="${modulos_visitados}${nombre_modulo}|"
            
            # Si no existía antes en la DB, es nuevo; si existía, es reutilizado
            if [ -z "$ya_existe_en_db" ]; then
                ((modulos_creados++))
            else
                ((modulos_usados++))
            fi
        fi
    fi
    
    # 🎯 Auto-detección del tipo de contenido
    id_tipo=$(detectar_tipo "$titulo")
    
    # Insertar contenido
    siguiente_orden=$(db_scalar "SELECT COALESCE(MAX(orden),0)+1 FROM contenidos WHERE id_modulo=$id_modulo_actual;")
    titulo_safe=$(escapar_sql "$titulo")
    
    output=$(db_exec "INSERT INTO contenidos (id_modulo, id_tipo, titulo, orden, estado) VALUES ($id_modulo_actual, $id_tipo, '$titulo_safe', $siguiente_orden, '$estado_inicial');" 2>&1)
    if [ $? -ne 0 ]; then
        error_msg "  ✗ Error al insertar '$titulo': $output"
        ((errores++))
        continue
    fi
    
    id_contenido=$(db_scalar "SELECT id_contenido FROM contenidos WHERE id_modulo=$id_modulo_actual AND titulo='$titulo_safe' ORDER BY id_contenido DESC LIMIT 1;")
    
    if [ -z "$id_contenido" ]; then
        error_msg "  ✗ No se pudo obtener ID para '$titulo'"
        ((errores++))
        continue
    fi
    
    # Insertar propiedades
    [ -n "$dificultad" ] && db_exec "INSERT OR REPLACE INTO contenido_propiedades (id_contenido, id_propiedad, valor) VALUES ($id_contenido, $id_dificultad, '$dificultad');"
    [ -n "$nivel" ] && db_exec "INSERT OR REPLACE INTO contenido_propiedades (id_contenido, id_propiedad, valor) VALUES ($id_contenido, $id_level, '$nivel');"
    [ "$minutos" -gt 0 ] && db_exec "INSERT OR REPLACE INTO contenido_propiedades (id_contenido, id_propiedad, valor) VALUES ($id_contenido, $id_minutos, '$minutos');"
    [ -n "$fecha" ] && db_exec "INSERT OR REPLACE INTO contenido_propiedades (id_contenido, id_propiedad, valor) VALUES ($id_contenido, $id_fecha, '$fecha');"
    
    # Heredar tags del módulo
    tags_heredados=$(db_scalar "SELECT tags FROM modulos WHERE id_modulo=$id_modulo_actual;")
    if [ -n "$tags_heredados" ] && [ -n "$id_tags" ]; then
        db_exec "INSERT OR REPLACE INTO contenido_propiedades (id_contenido, id_propiedad, valor) VALUES ($id_contenido, $id_tags, '$tags_heredados');"
    fi
    
    ((importados++))
    ((total++))
    echo -e "  ${C_VERDE}✅ $titulo (${minutos} min)${C_RESET}"
    
done < <(tail -n +2 "$csv_path")

echo ""
exito "=========================================="
echo "  Importación completada"
echo "=========================================="
echo "  - Total registros:     $total"
echo "  - Importados:          $importados"
echo "  - Estado asignado:     $estado_inicial"
echo "  - Módulos creados:     $modulos_creados"
echo "  - Módulos reutilizados:$modulos_usados"
[ "$errores" -gt 0 ] && advertencia "  - Errores: $errores"
echo ""
