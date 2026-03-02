#!/bin/bash
# db.sh - Funciones de base de datos para laboratorios Linux
# Ubicación: ~/Labs/data_base_SqLite/db.sh

DB="ejercicios.db"

# Colores (los mismos que en menu.sh)
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Inicializar la base de datos (crear tablas si no existen)
inicializar_db() {
    sqlite3 "$DB" <<EOF
CREATE TABLE IF NOT EXISTS ejercicios (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    bloque INTEGER NOT NULL CHECK (bloque BETWEEN 1 AND 10),
    tema TEXT NOT NULL,
    nivel TEXT NOT NULL CHECK (nivel IN ('Basico', 'Intermedio', 'Avanzado', 'Troubleshooting')),
    orden INTEGER NOT NULL CHECK (orden BETWEEN 1 AND 10),
    enunciado TEXT NOT NULL,
    dificultad INTEGER NOT NULL CHECK (dificultad BETWEEN 1 AND 5),
    completado INTEGER NOT NULL DEFAULT 0 CHECK (completado IN (0, 1)),
    ultima_vez TEXT,
    notas TEXT,
    UNIQUE(bloque, nivel, orden)
);

CREATE INDEX IF NOT EXISTS idx_bloque_nivel ON ejercicios(bloque, nivel);
CREATE INDEX IF NOT EXISTS idx_completado ON ejercicios(completado);
EOF
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Base de datos inicializada correctamente${NC}"
    else
        echo -e "${RED}❌ Error al inicializar la base de datos${NC}"
        exit 1
    fi
}

obtener_siguiente_ejercicio() {
    local bloque=$1
    local nivel=$2
    
    # El uso de -list y -separator '|' garantiza que 'read' en ejercicio.sh 
    # reciba exactamente 10 campos, incluso si hay celdas vacías.
    sqlite3 -list -separator '|' "$DB" <<EOF
SELECT 
    id, bloque, tema, nivel, orden, enunciado, 
    dificultad, completado, IFNULL(ultima_vez, ''), IFNULL(notas, '')
FROM ejercicios 
WHERE bloque = $bloque 
  AND nivel = '$nivel' 
  AND completado = 0 
ORDER BY orden ASC 
LIMIT 1;
EOF
}

# Marcar ejercicio como completado
# Uso: completar_ejercicio "id"
completar_ejercicio() {
    local id=$1
    local fecha=$(date +%Y-%m-%d)
    
    sqlite3 "$DB" "UPDATE ejercicios SET completado = 1, ultima_vez = '$fecha' WHERE id = $id;"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Ejercicio $id completado${NC}"
        return 0
    else
        echo -e "${RED}❌ Error al completar ejercicio${NC}"
        return 1
    fi
}

# Añadir nota a un ejercicio
# Uso: agregar_nota "id" "nota"
agregar_nota() {
    local id=$1
    local nota=$2
    
    sqlite3 "$DB" "UPDATE ejercicios SET notas = '$nota' WHERE id = $id;"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Nota guardada${NC}"
        return 0
    else
        echo -e "${RED}❌ Error al guardar nota${NC}"
        return 1
    fi
}

# Obtener contadores para el menú de niveles
# Uso: obtener_contadores "bloque"
obtener_contadores() {
    local bloque=$1
    
    sqlite3 "$DB" <<EOF
SELECT 
    nivel,
    COUNT(*) as total,
    SUM(completado) as completados
FROM ejercicios 
WHERE bloque = $bloque 
GROUP BY nivel
ORDER BY 
    CASE nivel
        WHEN 'Basico' THEN 1
        WHEN 'Intermedio' THEN 2
        WHEN 'Avanzado' THEN 3
        WHEN 'Troubleshooting' THEN 4
    END;
EOF
}

# Verificar si un bloque+nivel está completamente terminado
# Uso: bloque_completado "bloque" "nivel"
bloque_completado() {
    local bloque=$1
    local nivel=$2
    
    local pendientes=$(sqlite3 "$DB" "SELECT COUNT(*) FROM ejercicios WHERE bloque = $bloque AND nivel = '$nivel' AND completado = 0;")
    
    if [ "$pendientes" -eq 0 ]; then
        return 0  # True: completado
    else
        return 1  # False: hay pendientes
    fi
}

# Exportar funciones para que otros scripts puedan usarlas
export -f inicializar_db
export -f obtener_siguiente_ejercicio
export -f completar_ejercicio
export -f agregar_nota
export -f obtener_contadores
export -f bloque_completado