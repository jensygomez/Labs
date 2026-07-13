#!/bin/bash
# =========================================================
# importar_csv.sh - Importador dinámico desde CSV a SQLite
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
# 2. Seleccionar / crear Path, Curso, Módulo y Tipo de Contenido
# =========================================================
echo -e "
${C_AZUL}--- Selecciona o crea el contexto para los contenidos ---${C_RESET}"

# Path
id_path=$(seleccionar_o_crear paths nombre_path id_path "Path")
if [ -z "$id_path" ]; then
    advertencia "Cancelado por el usuario."
    exit 1
fi

# Curso
id_curso=$(seleccionar_o_crear cursos nombre_curso id_curso "Curso" "" "" "orden")
if [ -z "$id_curso" ]; then
    advertencia "Cancelado por el usuario."
    exit 1
fi

# Vincular curso al path
db_exec "INSERT OR IGNORE INTO path_cursos (id_path, id_curso) VALUES ($id_path, $id_curso);"

# Módulo
id_modulo=$(seleccionar_o_crear modulos nombre_modulo id_modulo "Módulo" id_curso "$id_curso" "orden")
if [ -z "$id_modulo" ]; then
    advertencia "Cancelado por el usuario."
    exit 1
fi

# Tipo de contenido (obligatorio)
echo -e "
${C_AZUL}--- Selecciona el Tipo de Contenido para todos los registros ---${C_RESET}"
id_tipo=$(seleccionar_o_crear tipos_contenido nombre_tipo id_tipo "Tipo de Contenido")
if [ -z "$id_tipo" ]; then
    advertencia "Cancelado por el usuario."
    exit 1
fi

# =========================================================
# 2.5 Seleccionar ESTADO inicial
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
# 3. Obtener IDs de propiedades DINÁMICAMENTE
# =========================================================
id_dificultad=$(db_scalar "SELECT id_propiedad FROM propiedades_catalogo WHERE nombre_propiedad='dificultad';")
id_level=$(db_scalar "SELECT id_propiedad FROM propiedades_catalogo WHERE nombre_propiedad='Level Scalation';")
id_minutos=$(db_scalar "SELECT id_propiedad FROM propiedades_catalogo WHERE nombre_propiedad='minutos';")
id_fecha=$(db_scalar "SELECT id_propiedad FROM propiedades_catalogo WHERE nombre_propiedad='fecha';")
id_tags=$(db_scalar "SELECT id_propiedad FROM propiedades_catalogo WHERE nombre_propiedad='tags';")

# Verificar que existan las propiedades necesarias
for id in "$id_dificultad" "$id_level" "$id_minutos" "$id_fecha"; do
    if [ -z "$id" ]; then
        error_msg "Falta una propiedad necesaria en el catálogo."
        exit 1
    fi
done

# =========================================================
# 4. Función auxiliar para parsear CSV (respeta comillas)
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
# 5. Leer el CSV línea por línea (saltando cabecera)
# =========================================================
total=0
importados=0
errores=0

# IMPORTANTE: usar process substitution para evitar subshell
while IFS= read -r line; do
    [ -z "$line" ] && continue
    
    # CSV limpio: 5 columnas (1=Title, 2=Difficulty, 3=Level, 4=Duration, 5=Date)
    titulo=$(parsear_campo "$line" 1)
    dificultad=$(parsear_campo "$line" 2)
    nivel=$(parsear_campo "$line" 3)
    minutos=$(parsear_campo "$line" 4)
    fecha=$(parsear_campo "$line" 5)
    
    # Limpiar espacios
    titulo=$(echo "$titulo" | xargs)
    dificultad=$(echo "$dificultad" | xargs)
    nivel=$(echo "$nivel" | xargs)
    minutos=$(echo "$minutos" | xargs)
    fecha=$(echo "$fecha" | xargs)
    
    if [ -z "$titulo" ]; then
        echo "Línea vacía o mal formada, saltando: $line"
        ((errores++))
        continue
    fi
    
    # Validar que minutos sea un número
    if ! [[ "$minutos" =~ ^[0-9]+$ ]]; then
        minutos=0
    fi
    
    # Insertar contenido CON ESTADO
    siguiente_orden=$(db_scalar "SELECT COALESCE(MAX(orden),0)+1 FROM contenidos WHERE id_modulo=$id_modulo;")
    titulo_safe=$(escapar_sql "$titulo")
    
    output=$(db_exec "INSERT INTO contenidos (id_modulo, id_tipo, titulo, orden, estado) VALUES ($id_modulo, $id_tipo, '$titulo_safe', $siguiente_orden, '$estado_inicial');" 2>&1)
    if [ $? -ne 0 ]; then
        error_msg "Error al insertar '$titulo': $output"
        ((errores++))
        continue
    fi
    
    # Obtener ID del contenido recién insertado
    id_contenido=$(db_scalar "SELECT id_contenido FROM contenidos WHERE id_modulo=$id_modulo AND titulo='$titulo_safe' ORDER BY id_contenido DESC LIMIT 1;")
    
    if [ -z "$id_contenido" ]; then
        error_msg "No se pudo obtener ID para '$titulo'"
        ((errores++))
        continue
    fi
    
    # Insertar propiedades
    [ -n "$dificultad" ] && db_exec "INSERT OR REPLACE INTO contenido_propiedades (id_contenido, id_propiedad, valor) VALUES ($id_contenido, $id_dificultad, '$dificultad');"
    [ -n "$nivel" ] && db_exec "INSERT OR REPLACE INTO contenido_propiedades (id_contenido, id_propiedad, valor) VALUES ($id_contenido, $id_level, '$nivel');"
    [ "$minutos" -gt 0 ] && db_exec "INSERT OR REPLACE INTO contenido_propiedades (id_contenido, id_propiedad, valor) VALUES ($id_contenido, $id_minutos, '$minutos');"
    [ -n "$fecha" ] && db_exec "INSERT OR REPLACE INTO contenido_propiedades (id_contenido, id_propiedad, valor) VALUES ($id_contenido, $id_fecha, '$fecha');"
    
    # Heredar tags del módulo
    tags_heredados=$(db_scalar "SELECT tags FROM modulos WHERE id_modulo=$id_modulo;")
    if [ -n "$tags_heredados" ] && [ -n "$id_tags" ]; then
        db_exec "INSERT OR REPLACE INTO contenido_propiedades (id_contenido, id_propiedad, valor) VALUES ($id_contenido, $id_tags, '$tags_heredados');"
    fi
    
    ((importados++))
    ((total++))
    echo -e "${C_VERDE}✅ [$total] $titulo (${minutos} min) - $estado_inicial${C_RESET}"
    
done < <(tail -n +2 "$csv_path")

echo ""
exito "Importación completada:"
echo "  - Registros procesados: $total"
echo "  - Importados con éxito: $importados"
echo "  - Estado asignado: $estado_inicial"
if [ "$errores" -gt 0 ]; then
    advertencia "Errores: $errores"
fi
