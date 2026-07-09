#!/bin/bash

# 1. Definir el nombre del directorio principal
PROYECTO="mi-progreso"

echo "=== Iniciando la creación del entorno vivo de estudio: $PROYECTO ==="

# 2. Crear estructura de directorios
mkdir -p "$PROYECTO/funciones"

# 3. CREAR: funciones/db_init.sh
# Este script inicializa la DB con soporte para llaves foráneas y tablas relacionales
cat << 'EOF' > "$PROYECTO/funciones/db_init.sh"
#!/bin/bash

DB_NAME="progreso.db"

inicializar_db() {
    # Habilitar soporte de llaves foráneas en SQLite y crear tablas si no existen
    sqlite3 "$DB_NAME" << 'SQL'
    PRAGMA foreign_keys = ON;

    CREATE TABLE IF NOT EXISTS paths (
        id_path INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre_path TEXT NOT NULL UNIQUE
    );

    CREATE TABLE IF NOT EXISTS cursos (
        id_curso INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre_curso TEXT NOT NULL UNIQUE
    );

    -- Tabla intermedia: Un curso puede pertenecer a múltiples paths
    CREATE TABLE IF NOT EXISTS path_cursos (
        id_path INTEGER,
        id_curso INTEGER,
        PRIMARY KEY (id_path, id_curso),
        FOREIGN KEY (id_path) REFERENCES paths(id_path) ON DELETE CASCADE,
        FOREIGN KEY (id_curso) REFERENCES cursos(id_curso) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS modulos (
        id_modulo INTEGER PRIMARY KEY AUTOINCREMENT,
        id_curso INTEGER,
        nombre_modulo TEXT NOT NULL,
        FOREIGN KEY (id_curso) REFERENCES cursos(id_curso) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS contenidos (
        id_contenido INTEGER PRIMARY KEY AUTOINCREMENT,
        id_modulo INTEGER,
        tipo TEXT CHECK(tipo IN ('Video', 'Lectura', 'Laboratorio')),
        titulo TEXT NOT NULL,
        estado TEXT DEFAULT 'Pendiente' CHECK(estado IN ('Pendiente', 'En Progreso', 'Completado')),
        FOREIGN KEY (id_modulo) REFERENCES modulos(id_modulo) ON DELETE CASCADE
    );
SQL
}
EOF

# 4. CREAR: funciones/menu_progreso.sh
cat << 'EOF' > "$PROYECTO/funciones/menu_progreso.sh"
#!/bin/bash

mostrar_menu_progreso() {
    clear
    echo "========================================="
    echo "       SUBMENÚ: MI PROGRESO ACTUAL       "
    echo "========================================="
    echo "1) Ver todas mis Rutas (Paths)"
    echo "2) Ver estado de un Curso"
    echo "3) Actualizar Estado de un Contenido (Lab/Video/Lectura)"
    echo "4) Volver al Menú Principal"
    echo "========================================="
    read -p "Selecciona una opción: " opt_progreso
    
    case $opt_progreso in
        4) return ;;
        *) echo "Función en desarrollo... Presiona ENTER para continuar"; read ;;
    esac
}
EOF

# 5. CREAR: funciones/menu_crud.sh
cat << 'EOF' > "$PROYECTO/funciones/menu_crud.sh"
#!/bin/bash

mostrar_menu_crud() {
    clear
    echo "========================================="
    echo "   SUBMENÚ: GESTIÓN DE CONTENIDO (CRUD)  "
    echo "========================================="
    echo "1) Agregar nuevo Path / Curso / Módulo"
    echo "2) Asociar Curso existente a un Path (Multi-path)"
    echo "3) Editar un registro existente"
    echo "4) Eliminar un registro"
    echo "5) Volver al Menú Principal"
    echo "========================================="
    read -p "Selecciona una opción: " opt_crud
    
    case $opt_crud in
        5) return ;;
        *) echo "Función en desarrollo... Presiona ENTER para continuar"; read ;;
    esac
}
EOF

# 6. CREAR: funciones/menu_schema.sh
cat << 'EOF' > "$PROYECTO/funciones/menu_schema.sh"
#!/bin/bash

mostrar_menu_schema() {
    clear
    echo "========================================="
    echo "   SUBMENÚ: EVOLUCIÓN DINÁMICA (SCHEMA)  "
    echo "========================================="
    echo "1) Agregar nueva columna a una tabla"
    echo "2) Ver estructura actual de las tablas"
    echo "3) Volver al Menú Principal"
    echo "========================================="
    read -p "Selecciona una opción: " opt_schema
    
    case $opt_schema in
        3) return ;;
        1)
            clear
            echo "--- Agregar Columna Dinámica ---"
            read -p "Nombre de la tabla (ej. contenidos): " tabla
            read -p "Nombre del nuevo atributo/columna: " columna
            
            # Ejecución del ALTER TABLE dinámico
            sqlite3 progreso.db "ALTER TABLE $tabla ADD COLUMN $columna TEXT;" 2>/dev/null
            if [ $? -eq 0 ]; then
                echo "¡Columna '$columna' añadida con éxito a la tabla '$tabla'!"
            else
                echo "Error: Verifica que la tabla exista y la columna no esté repetida."
            fi
            read -p "Presiona ENTER para continuar..."
            ;;
        2)
            clear
            echo "--- Estructura de la Base de Datos ---"
            sqlite3 progreso.db ".schema"
            read -p "Presiona ENTER para continuar..."
            ;;
        *) echo "Opción inválida"; sleep 1 ;;
    esac
}
EOF

# 7. CREAR: progreso.sh (El Orquestador Principal)
cat << 'EOF' > "$PROYECTO/progreso.sh"
#!/bin/bash

# Cambiar al directorio del script para evitar fallos de rutas relativas
cd "$(dirname "$0")"

# Importar módulos y lógica secundaria
source ./funciones/db_init.sh
source ./funciones/menu_progreso.sh
source ./funciones/menu_crud.sh
source ./funciones/menu_schema.sh

# Asegurar que la base de datos exista y tenga la estructura inicial
inicializar_db

while true; do
    clear
    echo "========================================="
    echo "    SISTEMA DE SEGUIMIENTO DE ESTUDIO    "
    echo "========================================="
    echo "1) Mi Progreso (Rutas y Avances)"
    echo "2) Gestión de Contenido (Agregar/Editar/Borrar)"
    echo "3) Configuración Avanzada (Evolución de DB)"
    echo "4) Salir del Sistema"
    echo "========================================="
    read -p "Selecciona una opción [1-4]: " opcion

    case $opcion in
        1) mostrar_menu_progreso ;;
        2) mostrar_menu_crud ;;
        3) mostrar_menu_schema ;;
        4) echo "¡Buen entrenamiento! Sigue dándole duro a los laboratorios."; exit 0 ;;
        *) echo "Opción no válida, intenta de nuevo."; sleep 1 ;;
    esac
done
EOF

# 8. Otorgar permisos de ejecución a los scripts generados
chmod +x "$PROYECTO/progreso.sh"
chmod +x "$PROYECTO"/funciones/*.sh

echo "========================================="
echo "¡Entorno creado con éxito en: ./$PROYECTO!"
echo "Para arrancar el sistema, ejecuta:"
echo "cd $PROYECTO && ./progreso.sh"
echo "========================================="
