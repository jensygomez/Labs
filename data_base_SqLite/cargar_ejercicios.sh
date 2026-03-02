#!/bin/bash
# cargar_ejercicios.sh - Carga los ejercicios desde CSV a la base de datos
# Ubicación: ~/Labs/data_base_SqLite/cargar_ejercicios.sh

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
    echo -e "Debes crear el archivo con los ejercicios primero."
    exit 1
fi

# Inicializar base de datos (crear tablas si no existen)
echo -e "\n${YELLOW}📦 Inicializando base de datos...${NC}"
inicializar_db

# Preguntar qué hacer con datos existentes
echo -e "\n${YELLOW}¿Qué quieres hacer con los ejercicios existentes?${NC}"
echo "1) Mantener los actuales y añadir nuevos (si no existen)"
echo "2) Reemplazar todo (borrar y cargar de nuevo)"
echo "3) Cancelar"
read -rp "Elige [1-3]: " opcion

case $opcion in
    1)
        MODO="insert"
        echo -e "${GREEN}📝 Modo: Añadir nuevos ejercicios (sin borrar existentes)${NC}"
        ;;
    2)
        MODO="reemplazar"
        echo -e "${YELLOW}⚠️  ATENCIÓN: Se borrarán TODOS los ejercicios existentes${NC}"
        read -rp "¿Estás seguro? (escribe 'BORRAR' para confirmar): " confirmacion
        if [ "$confirmacion" != "BORRAR" ]; then
            echo -e "${RED}Cancelado${NC}"
            exit 0
        fi
        # Vaciar la tabla
        sqlite3 "$DB" "DELETE FROM ejercicios;"
        sqlite3 "$DB" "DELETE FROM sqlite_sequence WHERE name='ejercicios';"  # Resetear autoincrement
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

# Contadores para estadísticas
total_leidos=0
total_insertados=0
total_omitidos=0
errores=0

echo -e "\n${BLUE}Procesando ejercicios desde $CSV...${NC}\n"

# Leer CSV línea por línea (saltando la cabecera)
tail -n +2 "$CSV" | while IFS=',' read -r bloque tema nivel orden enunciado dificultad; do
    total_leidos=$((total_leidos + 1))
    
    # Limpiar el enunciado (quitar comillas si las hay)
    enunciado=$(echo "$enunciado" | sed 's/^"//;s/"$//')
    
    # Mostrar progreso
    printf "  [%02d] Bloque %d | %-12s | Orden %2d | " "$total_leidos" "$bloque" "$nivel" "$orden"
    
    # Validar datos básicos
    if [[ ! "$bloque" =~ ^[0-9]+$ ]] || [ "$bloque" -lt 1 ] || [ "$bloque" -gt 10 ]; then
        echo -e "${RED}❌ Bloque inválido${NC}"
        errores=$((errores + 1))
        continue
    fi
    
    if [[ ! "$nivel" =~ ^(Basico|Intermedio|Avanzado|Troubleshooting)$ ]]; then
        echo -e "${RED}❌ Nivel inválido: $nivel${NC}"
        errores=$((errores + 1))
        continue
    fi
    
    if [[ ! "$orden" =~ ^[0-9]+$ ]] || [ "$orden" -lt 1 ] || [ "$orden" -gt 10 ]; then
        echo -e "${RED}❌ Orden inválido: $orden${NC}"
        errores=$((errores + 1))
        continue
    fi
    
    if [[ ! "$dificultad" =~ ^[0-9]+$ ]] || [ "$dificultad" -lt 1 ] || [ "$dificultad" -gt 5 ]; then
        echo -e "${RED}❌ Dificultad inválida: $dificultad${NC}"
        errores=$((errores + 1))
        continue
    fi
    
    if [ -z "$enunciado" ]; then
        echo -e "${RED}❌ Enunciado vacío${NC}"
        errores=$((errores + 1))
        continue
    fi
    
    # Verificar si ya existe el ejercicio
    existe=$(sqlite3 "$DB" "SELECT COUNT(*) FROM ejercicios WHERE bloque=$bloque AND nivel='$nivel' AND orden=$orden;")
    
    if [ "$existe" -gt 0 ] && [ "$MODO" = "insert" ]; then
        echo -e "${YELLOW}⏩ Ya existe, omitido${NC}"
        total_omitidos=$((total_omitidos + 1))
        continue
    fi
    
    # Insertar o reemplazar
    if [ "$existe" -gt 0 ] && [ "$MODO" = "reemplazar" ]; then
        # Actualizar existente
        sqlite3 "$DB" "UPDATE ejercicios SET 
            tema='$tema',
            enunciado='$enunciado',
            dificultad=$dificultad,
            completado=0,
            ultima_vez=NULL,
            notas=NULL
            WHERE bloque=$bloque AND nivel='$nivel' AND orden=$orden;"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Actualizado${NC}"
            total_insertados=$((total_insertados + 1))
        else
            echo -e "${RED}❌ Error al actualizar${NC}"
            errores=$((errores + 1))
        fi
    else
        # Insertar nuevo
        sqlite3 "$DB" "INSERT INTO ejercicios 
            (bloque, tema, nivel, orden, enunciado, dificultad, completado)
            VALUES 
            ($bloque, '$tema', '$nivel', $orden, '$enunciado', $dificultad, 0);"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Insertado${NC}"
            total_insertados=$((total_insertados + 1))
        else
            echo -e "${RED}❌ Error al insertar${NC}"
            errores=$((errores + 1))
        fi
    fi
done

# Mostrar resumen final
echo -e "\n${BLUE}══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  RESUMEN DE CARGA${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
echo -e "  📖 Ejercicios leídos:     $total_leidos"
echo -e "  ✅ Insertados/Actualizados: $total_insertados"
echo -e "  ⏩ Omitidos (ya existen): $total_omitidos"
echo -e "  ❌ Errores:               $errores"

# Mostrar estadísticas por nivel
echo -e "\n${YELLOW}📊 Distribución en base de datos:${NC}"
sqlite3 "$DB" <<EOF
.mode table
SELECT 
    nivel,
    COUNT(*) as total,
    SUM(completado) as completados,
    ROUND(AVG(dificultad), 1) as dificultad_media
FROM ejercicios 
WHERE bloque = 1
GROUP BY nivel
ORDER BY 
    CASE nivel
        WHEN 'Basico' THEN 1
        WHEN 'Intermedio' THEN 2
        WHEN 'Avanzado' THEN 3
        WHEN 'Troubleshooting' THEN 4
    END;
EOF

echo -e "\n${GREEN}✅ Proceso completado${NC}"