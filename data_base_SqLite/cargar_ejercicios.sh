#!/bin/bash
# cargar_ejercicios.sh - Versión mejorada con importación directa de SQLite
# Ubicación: ~/Labs/data_base_SqLite/cargar_ejercicios.sh

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

DB="ejercicios.db"
CSV="ejercicios.csv"

# Cargar funciones de base de datos
source ./db.sh

# Mostrar banner
echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  CARGADOR DE EJERCICIOS - BLOQUE 1: Fundamentos del sistema${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"

# Verificar que existe el archivo CSV
if [ ! -f "$CSV" ]; then
    echo -e "${RED}❌ Error: No se encuentra el archivo $CSV${NC}"
    exit 1
fi

# Inicializar base de datos
echo -e "\n${YELLOW}📦 Inicializando base de datos...${NC}"
inicializar_db

# Preguntar qué hacer con datos existentes
echo -e "\n${YELLOW}¿Qué quieres hacer con los ejercicios existentes?${NC}"
echo "1) Mantener los actuales y añadir nuevos (recomendado)"
echo "2) Reemplazar todo (borrar y cargar de nuevo)"
echo "3) Cancelar"
read -rp "Elige [1-3]: " opcion

case $opcion in
    1)
        MODO="mantener"
        echo -e "${GREEN}📝 Modo: Añadir/Actualizar ejercicios${NC}"
        # Crear tabla temporal para importación
        sqlite3 "$DB" "DROP TABLE IF EXISTS ejercicios_temp;"
        sqlite3 "$DB" "CREATE TABLE ejercicios_temp (bloque INTEGER, tema TEXT, nivel TEXT, orden INTEGER, enunciado TEXT, dificultad INTEGER);"
        ;;
    2)
        MODO="reemplazar"
        echo -e "${YELLOW}⚠️  ATENCIÓN: Se borrarán TODOS los ejercicios existentes${NC}"
        read -rp "¿Estás seguro? (escribe 'BORRAR' para confirmar): " confirmacion
        if [ "$confirmacion" != "BORRAR" ]; then
            echo -e "${RED}Cancelado${NC}"
            exit 0
        fi
        # Vaciar la tabla principal y crear temporal
        sqlite3 "$DB" "DELETE FROM ejercicios;"
        sqlite3 "$DB" "DELETE FROM sqlite_sequence WHERE name='ejercicios';"
        sqlite3 "$DB" "DROP TABLE IF EXISTS ejercicios_temp;"
        sqlite3 "$DB" "CREATE TABLE ejercicios_temp (bloque INTEGER, tema TEXT, nivel TEXT, orden INTEGER, enunciado TEXT, dificultad INTEGER);"
        echo -e "${GREEN}🗑️  Tabla vaciada. Listo para cargar nuevos datos.${NC}"
        ;;
    3)
        echo -e "${YELLOW}Cancelado${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Opción inválida${NC}"
        exit 1
        ;;
esac

# Importar CSV a tabla temporal usando el importador de SQLite
echo -e "\n${YELLOW}📤 Importando datos desde $CSV...${NC}"

# SQLite puede importar CSV directamente con .mode csv y .import
sqlite3 "$DB" <<EOF
.mode csv
.separator ","
.import $CSV ejercicios_temp
EOF

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error al importar CSV${NC}"
    exit 1
fi

# Contar registros importados
total_importados=$(sqlite3 "$DB" "SELECT COUNT(*) FROM ejercicios_temp WHERE bloque IS NOT NULL AND bloque != 'bloque';")
echo -e "${GREEN}✅ Importados $total_importados registros desde CSV${NC}"

# Eliminar la cabecera si se importó como dato
sqlite3 "$DB" "DELETE FROM ejercicios_temp WHERE bloque = 'bloque' OR bloque IS NULL;"

# Validar y transferir datos a la tabla principal
echo -e "\n${YELLOW}🔍 Validando y transfiriendo datos...${NC}"

# Crear tabla temporal para errores
sqlite3 "$DB" "DROP TABLE IF EXISTS errores_importacion;"
sqlite3 "$DB" "CREATE TABLE errores_importacion (linea TEXT, error TEXT);"

# Transferir registros válidos
sqlite3 "$DB" <<EOF
INSERT OR REPLACE INTO ejercicios (bloque, tema, nivel, orden, enunciado, dificultad, completado)
SELECT 
    bloque, 
    tema, 
    nivel, 
    orden, 
    enunciado, 
    dificultad, 
    0
FROM ejercicios_temp
WHERE 
    bloque BETWEEN 1 AND 10
    AND nivel IN ('Basico', 'Intermedio', 'Avanzado', 'Troubleshooting')
    AND orden BETWEEN 1 AND 10
    AND dificultad BETWEEN 1 AND 5
    AND enunciado IS NOT NULL AND enunciado != '';
EOF

transferidos=$?

# Contar resultados
totales=$(sqlite3 "$DB" "SELECT COUNT(*) FROM ejercicios WHERE bloque=1;")
basicos=$(sqlite3 "$DB" "SELECT COUNT(*) FROM ejercicios WHERE bloque=1 AND nivel='Basico';")
intermedios=$(sqlite3 "$DB" "SELECT COUNT(*) FROM ejercicios WHERE bloque=1 AND nivel='Intermedio';")
avanzados=$(sqlite3 "$DB" "SELECT COUNT(*) FROM ejercicios WHERE bloque=1 AND nivel='Avanzado';")
troubles=$(sqlite3 "$DB" "SELECT COUNT(*) FROM ejercicios WHERE bloque=1 AND nivel='Troubleshooting';")

# Limpiar tabla temporal
sqlite3 "$DB" "DROP TABLE IF EXISTS ejercicios_temp;"

# Mostrar resumen
echo -e "\n${BLUE}══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  RESUMEN DE CARGA${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
echo -e "  📖 Ejercicios en DB:    $totales"
echo -e "  🟢 Básicos:             $basicos"
echo -e "  🟡 Intermedios:         $intermedios"
echo -e"  🔴 Avanzados:            $avanzados"
echo -e "  🔥 Troubleshooting:     $troubles"

# Mostrar distribución por dificultad
echo -e "\n${YELLOW}📊 Distribución por dificultad (1-5 estrellas):${NC}"
sqlite3 "$DB" <<EOF
.mode table
SELECT 
    dificultad,
    COUNT(*) as total
FROM ejercicios 
WHERE bloque = 1
GROUP BY dificultad
ORDER BY dificultad;
EOF

# Mostrar algunos ejercicios como muestra
echo -e "\n${CYAN}📋 Primeros 3 ejercicios cargados:${NC}"
sqlite3 "$DB" <<EOF
.mode line
SELECT id, bloque, nivel, orden, substr(enunciado, 1, 60) || '...' as enunciado_resumido
FROM ejercicios 
WHERE bloque = 1 
ORDER BY 
    CASE nivel
        WHEN 'Basico' THEN 1
        WHEN 'Intermedio' THEN 2
        WHEN 'Avanzado' THEN 3
        WHEN 'Troubleshooting' THEN 4
    END,
    orden
LIMIT 3;
EOF

echo -e "\n${GREEN}✅ Proceso completado exitosamente${NC}"
echo -e "${YELLOW}💡 Ahora puedes ejecutar ./menu.sh para comenzar a practicar${NC}"