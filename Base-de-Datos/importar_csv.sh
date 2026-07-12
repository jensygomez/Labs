#!/bin/bash
# =========================================================
# importar_csv.sh - Importador dinámico desde CSV a SQLite
# =========================================================
# Requiere estar en el directorio del sistema (con ./funciones/)
# Uso: ./importar_csv.sh
# =========================================================

cd "$(dirname "$0")"

# Cargar funciones comunes (incluye db_exec, db_scalar, seleccionar_o_crear, etc.)
source ./funciones/common.sh
source ./funciones/db_init.sh   # solo para asegurar que existan tablas (es idempotente)

# =========================================================
# 1. Preguntar ruta del CSV
# =========================================================
echo -e "\n${C_AZUL}=== IMPORTADOR DESDE CSV ===${C_RESET}"
read -p "Ruta del archivo CSV a importar: " csv_path
if [ ! -f "$csv_path" ]; then
    error_msg "Archivo no encontrado: $csv_path"
    exit 1
fi
info_msg "Usando: $csv_path"

# =========================================================
# 2. Seleccionar / crear Path, Curso y Módulo
# =========================================================
echo -e "\n${C_AZUL}--- Selecciona o crea el contexto para los contenidos ---${C_RESET}"

# Path
id_path=$(seleccionar_o_crear paths nombre_path id_path "Path")
if [ -z "$id_path" ]; then
    advertencia "Cancelado por el usuario."
    exit 1
fi

# Curso (no filtrado por path, pero luego se vincula)
id_curso=$(seleccionar_o_crear cursos nombre_curso id_curso "Curso" "" "" "orden")
if [ -z "$id_curso" ]; then
    advertencia "Cancelado por el usuario."
    exit 1
fi

# Vincular curso al path (si no existe)
db_exec "INSERT OR IGNORE INTO path_cursos (id_path, id_curso) VALUES ($id_path, $id_curso);"

# Módulo (filtrado por curso)
id_modulo=$(seleccionar_o_crear modulos nombre_modulo id_modulo "Módulo" id_curso "$id_curso" "orden")
if [ -z "$id_modulo" ]; then
    advertencia "Cancelado por el usuario."
    exit 1
fi

# =========================================================
# 3. Obtener IDs de propiedades (una sola vez)
# =========================================================
id_dificultad=$(db_scalar "SELECT id_propiedad FROM propiedades_catalogo WHERE nombre_propiedad='dificultad';")
id_level=$(db_scalar "SELECT id_propiedad FROM propiedades_catalogo WHERE nombre_propiedad='Level Scalation';")
id_minutos=$(db_scalar "SELECT id_propiedad FROM propiedades_catalogo WHERE nombre_propiedad='minutos';")
id_fecha=$(db_scalar "SELECT id_propiedad FROM propiedades_catalogo WHERE nombre_propiedad='fecha';")
id_tags=$(db_scalar "SELECT id_propiedad FROM propiedades_catalogo WHERE nombre_propiedad='tags';")

# Verificar que existan las propiedades necesarias
for id in "$id_dificultad" "$id_level" "$id_minutos" "$id_fecha"; do
    if [ -z "$id" ]; then
        error_msg "Falta una propiedad necesaria en el catálogo. Ejecuta la inicialización."
        exit 1
    fi
done

# =========================================================
# 4. Leer el CSV línea por línea (saltando cabecera)
# =========================================================
total=0
importados=0
errores=0

# Usamos awk con FPAT para manejar comillas internas
tail -n +2 "$csv_path" | while IFS= read -r line; do
    # Si la línea está vacía, saltar
    [ -z "$line" ] && continue

    # Extraer las columnas 4 a 8 (Título, Dificultad, Nivel, Duración, Fecha)
    # Usamos awk con FPAT para separar respetando comillas
    titulo=$(echo "$line" | awk -v FPAT='[^,]*|"[^"]*"' '{
        gsub(/^"|"$/, "", $4); print $4
    }')
    dificultad=$(echo "$line" | awk -v FPAT='[^,]*|"[^"]*"' '{
        gsub(/^"|"$/, "", $5); print $5
    }')
    nivel=$(echo "$line" | awk -v FPAT='[^,]*|"[^"]*"' '{
        gsub(/^"|"$/, "", $6); print $6
    }')
    duracion_raw=$(echo "$line" | awk -v FPAT='[^,]*|"[^"]*"' '{
        gsub(/^"|"$/, "", $7); print $7
    }')
    fecha=$(echo "$line" | awk -v FPAT='[^,]*|"[^"]*"' '{
        gsub(/^"|"$/, "", $8); print $8
    }')

    # Limpiar espacios
    titulo=$(echo "$titulo" | xargs)
    dificultad=$(echo "$dificultad" | xargs)
    nivel=$(echo "$nivel" | xargs)
    duracion_raw=$(echo "$duracion_raw" | xargs)
    fecha=$(echo "$fecha" | xargs)

    # Saltar si el título está vacío
    if [ -z "$titulo" ]; then
        echo "Línea vacía o mal formada, saltando: $line"
        ((errores++))
        continue
    fi

    # Extraer minutos de la duración (ej. "30 min" -> 30)
    minutos=$(echo "$duracion_raw" | grep -oE '^[0-9]+')
    if [ -z "$minutos" ]; then
        minutos=0
    fi

    # -- Insertar en contenidos --
    siguiente_orden=$(db_scalar "SELECT COALESCE(MAX(orden),0)+1 FROM contenidos WHERE id_modulo=$id_modulo;")
    titulo_safe=$(escapar_sql "$titulo")
    db_exec "INSERT INTO contenidos (id_modulo, titulo, orden) VALUES ($id_modulo, '$titulo_safe', $siguiente_orden);"
    id_contenido=$(db_scalar "SELECT last_insert_rowid();")

    if [ -z "$id_contenido" ] || [ "$id_contenido" = "0" ]; then
        error_msg "Error al insertar '$titulo'"
        ((errores++))
        continue
    fi

    # -- Insertar propiedades --
    # Dificultad
    if [ -n "$dificultad" ]; then
        db_exec "INSERT OR REPLACE INTO contenido_propiedades (id_contenido, id_propiedad, valor)
                 VALUES ($id_contenido, $id_dificultad, '$dificultad');"
    fi

    # Nivel (Level Scalation)
    if [ -n "$nivel" ]; then
        db_exec "INSERT OR REPLACE INTO contenido_propiedades (id_contenido, id_propiedad, valor)
                 VALUES ($id_contenido, $id_level, '$nivel');"
    fi

    # Minutos
    if [ "$minutos" -gt 0 ]; then
        db_exec "INSERT OR REPLACE INTO contenido_propiedades (id_contenido, id_propiedad, valor)
                 VALUES ($id_contenido, $id_minutos, '$minutos');"
    fi

    # Fecha (convertir formato DD/MM/YYYY a YYYY-MM-DD si es necesario)
    if [ -n "$fecha" ]; then
        # Si viene en formato DD/MM/YYYY, convertirlo
        if [[ "$fecha" =~ ^[0-9]{2}/[0-9]{2}/[0-9]{4}$ ]]; then
            fecha=$(echo "$fecha" | awk -F'/' '{print $3"-"$2"-"$1}')
        fi
        db_exec "INSERT OR REPLACE INTO contenido_propiedades (id_contenido, id_propiedad, valor)
                 VALUES ($id_contenido, $id_fecha, '$fecha');"
    fi

    # Heredar tags del módulo (si existen)
    tags_heredados=$(db_scalar "SELECT tags FROM modulos WHERE id_modulo=$id_modulo;")
    if [ -n "$tags_heredados" ] && [ -n "$id_tags" ]; then
        db_exec "INSERT OR REPLACE INTO contenido_propiedades (id_contenido, id_propiedad, valor)
                 VALUES ($id_contenido, $id_tags, '$tags_heredados');"
    fi

    echo "✅ Importado: $titulo"
    ((importados++))
    ((total++))
done

# =========================================================
# 5. Resumen final
# =========================================================
echo ""
exito "Importación completada:"
echo "  - Registros procesados: $total"
echo "  - Importados con éxito: $importados"
if [ "$errores" -gt 0 ]; then
    advertencia "Errores: $errores"
fi
