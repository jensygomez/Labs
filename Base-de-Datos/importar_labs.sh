#!/bin/bash

# Configuración de rutas
RUTA_LABS="/home/jensyg/Labs/KodeKloud/01 - Linux/01 - Linux Foundation Certified System Administrator (LFCS) Certification/Playgrounds/"
DB_NAME="progreso.db"

# Verificar que la base de datos exista
if [ ! -f "$DB_NAME" ]; then
    echo "Error: No se encuentra la base de datos $DB_NAME en este directorio."
    exit 1
fi

# Verificar que la ruta de los laboratorios exista
if [ ! -d "$RUTA_LABS" ]; then
    echo "Error: La ruta de los laboratorios no existe o no es accesible."
    exit 1
fi

echo "=========================================================="
echo "   INICIANDO IMPORTACIÓN AUTOMÁTICA DE INFRAESTRUCTURA   "
echo "=========================================================="

# 1. Asegurar que exista el Curso Madre
sqlite3 "$DB_NAME" "INSERT OR IGNORE INTO cursos (nombre_curso) VALUES ('LFCS Certification Playgrounds');"
ID_CURSO=$(sqlite3 "$DB_NAME" "SELECT id_curso FROM cursos WHERE nombre_curso='LFCS Certification Playgrounds';")

# Intentar asociarlo automáticamente al Path 1 (System Administrator) si existe
sqlite3 "$DB_NAME" "INSERT OR IGNORE INTO path_cursos (id_path, id_curso) VALUES (1, $ID_CURSO);"

# Función auxiliar para extraer bloques multi-línea (YAML-like) de los archivos Markdown
extraer_bloque_yaml() {
    local archivo="$1"
    local clave="$2"
    # Busca la clave y extrae todo el texto indentado que le sigue hasta que cambie la indentación o empiece otra clave
    sed -n "/^${clave}:/ , /^[A-Za-z]/ { /^${clave}:/d; /^[A-Za-z]/d; p; }" "$archivo" | sed 's/^ *//'
}

# Función auxiliar para extraer valores de una sola línea
extraer_linea_yaml() {
    local archivo="$1"
    local clave="$2"
    grep -i "^${clave}:" "$archivo" | head -n 1 | cut -d':' -f2- | sed 's/^ *//;s/ *$//'
}

# 2. Caminar por el árbol de directorios usando find
# Buscamos archivos .md excluyendo archivos de lista genéricos
find "$RUTA_LABS" -type f -name "*.md" ! -name "*Lista de Laboratorios*" ! -name "*lista de*" | while read -r archivo_md; do
    
    # Extraer el nombre de la subcarpeta para usarlo como Nombre del Módulo
    nombre_carpeta=$(basename "$(dirname "$archivo_md")")
    # Limpiar prefijos numéricos si existen (ej. "001 - Essential Commands" -> "Essential Commands")
    nombre_modulo=$(echo "$nombre_carpeta" | sed 's/^[0-9]* *-[ *]//')
    
    # Crear el módulo en la DB si no existe
    sqlite3 "$DB_NAME" "INSERT OR IGNORE INTO modulos (id_curso, nombre_modulo) VALUES ($ID_CURSO, '$nombre_modulo');"
    ID_MODULO=$(sqlite3 "$DB_NAME" "SELECT id_modulo FROM modulos WHERE id_curso=$ID_CURSO AND nombre_modulo='$nombre_modulo';")
    
    # Extraer el Título o usar el nombre del archivo si no viene explícito
    titulo=$(extraer_linea_yaml "$archivo_md" "Titulo")
    if [ -z "$titulo" ]; then
        titulo=$(basename "$archivo_md" .md)
    fi
    
    # Insertar en contenidos (Evitando duplicar por título en el mismo módulo)
    sqlite3 "$DB_NAME" "INSERT INTO contenidos (id_modulo, tipo, titulo) VALUES ($ID_MODULO, 'Laboratorio', '$titulo');" 2>/dev/null
    ID_CONTENIDO=$(sqlite3 "$DB_NAME" "SELECT id_contenido FROM contenidos WHERE id_modulo=$ID_MODULO AND titulo='$titulo';")
    
    echo "Procesando: [$nombre_modulo] -> $titulo"

    # 3. EXTRAER E INYECTAR PROPIEDADES DINÁMICAS (KEY-VALUE)
    
    # Propiedades Simples (Línea única)
    playground=$(extraer_linea_yaml "$archivo_md" "Playground")
    [ -n "$playground" ] && sqlite3 "$DB_NAME" "INSERT OR REPLACE INTO propiedades_dinamicas (id_contenido, clave, valor) VALUES ($ID_CONTENIDO, 'Playground', '$playground');"
    
    fecha=$(extraer_linea_yaml "$archivo_md" "Fecha de Inicio")
    [ -n "$fecha" ] && sqlite3 "$DB_NAME" "INSERT OR REPLACE INTO propiedades_dinamicas (id_contenido, clave, valor) VALUES ($ID_CONTENIDO, 'Fecha_Inicio', '$fecha');"
    
    dificultad=$(extraer_linea_yaml "$archivo_md" "Dificultad")
    [ -n "$dificultad" ] && sqlite3 "$DB_NAME" "INSERT OR REPLACE INTO propiedades_dinamicas (id_contenido, clave, valor) VALUES ($ID_CONTENIDO, 'Dificultad', '$dificultad');"
    
    level=$(extraer_linea_yaml "$archivo_md" "Level Escalation")
    [ -n "$level" ] && sqlite3 "$DB_NAME" "INSERT OR REPLACE INTO propiedades_dinamicas (id_contenido, clave, valor) VALUES ($ID_CONTENIDO, 'Level_Escalation', '$level');"
    
    # Propiedades Complejas (Bloques de texto multi-línea)
    objetivo=$(extraer_bloque_yaml "$archivo_md" "Objetivo")
    [ -n "$objetivo" ] && sqlite3 "$DB_NAME" "INSERT OR REPLACE INTO propiedades_dinamicas (id_contenido, clave, valor) VALUES ($ID_CONTENIDO, 'Objetivo', '$objetivo');"
    
    temas=$(extraer_bloque_yaml "$archivo_md" "Temas")
    [ -n "$temas" ] && sqlite3 "$DB_NAME" "INSERT OR REPLACE INTO propiedades_dinamicas (id_contenido, clave, valor) VALUES ($ID_CONTENIDO, 'Temas', '$temas');"
    
    competencias=$(extraer_bloque_yaml "$archivo_md" "Competencias")
    [ -n "$competencias" ] && sqlite3 "$DB_NAME" "INSERT OR REPLACE INTO propiedades_dinamicas (id_contenido, clave, valor) VALUES ($ID_CONTENIDO, 'Competencias', '$competencias');"
    
    escenario=$(extraer_bloque_yaml "$archivo_md" "Escenario")
    [ -n "$escenario" ] && sqlite3 "$DB_NAME" "INSERT OR REPLACE INTO propiedades_dinamicas (id_contenido, clave, valor) VALUES ($ID_CONTENIDO, 'Escenario', '$escenario');"
    
    # Inicializar por defecto el estado en las propiedades dinámicas de control si no existe
    sqlite3 "$DB_NAME" "INSERT OR IGNORE INTO propiedades_dinamicas (id_contenido, clave, valor) VALUES ($ID_CONTENIDO, 'Estado', 'Pendiente');"
    sqlite3 "$DB_NAME" "INSERT OR IGNORE INTO propiedades_dinamicas (id_contenido, clave, valor) VALUES ($ID_CONTENIDO, 'Tiempo_Real', '0');"

done

echo "=========================================================="
echo "   ¡IMPORTACIÓN COMPLETADA CON ÉXITO!                     "
echo "=========================================================="
