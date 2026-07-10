#!/bin/bash
# =========================================================
# db_init.sh - Esquema de la base de datos
# =========================================================

DB_NAME="progreso.db"

inicializar_db() {
    sqlite3 "$DB_NAME" << 'SQL'
    PRAGMA foreign_keys = ON;

    -- Rutas de aprendizaje (ej: Sysadmin Linux, DevOps, Kubernetes)
    CREATE TABLE IF NOT EXISTS paths (
        id_path INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre_path TEXT NOT NULL UNIQUE
    );

    -- Cursos (un curso puede pertenecer a varios paths, ej: Docker en Sysadmin y DevOps)
    -- tags: se define al crear el curso y se hereda a todos sus módulos y lecciones
    CREATE TABLE IF NOT EXISTS cursos (
        id_curso INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre_curso TEXT NOT NULL UNIQUE,
        tags TEXT DEFAULT '',
        orden INTEGER DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS path_cursos (
        id_path INTEGER,
        id_curso INTEGER,
        PRIMARY KEY (id_path, id_curso),
        FOREIGN KEY (id_path) REFERENCES paths(id_path) ON DELETE CASCADE,
        FOREIGN KEY (id_curso) REFERENCES cursos(id_curso) ON DELETE CASCADE
    );

    -- tags: hereda las del curso padre + las propias del módulo
    -- orden: posición dentro del curso, usada para mostrar/mover Nº en vez de ID
    CREATE TABLE IF NOT EXISTS modulos (
        id_modulo INTEGER PRIMARY KEY AUTOINCREMENT,
        id_curso INTEGER,
        nombre_modulo TEXT NOT NULL,
        tags TEXT DEFAULT '',
        orden INTEGER DEFAULT 0,
        FOREIGN KEY (id_curso) REFERENCES cursos(id_curso) ON DELETE CASCADE
    );

    -- Tipos de contenido dinámicos (Video, Lectura, Laboratorio, Simulacro, PDF...)
    -- en vez de un CHECK fijo, así se puede extender sin ALTER TABLE
    CREATE TABLE IF NOT EXISTS tipos_contenido (
        id_tipo INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre_tipo TEXT NOT NULL UNIQUE
    );

    -- orden: posición dentro del módulo, usada para mostrar/mover Nº en vez de ID
    CREATE TABLE IF NOT EXISTS contenidos (
        id_contenido INTEGER PRIMARY KEY AUTOINCREMENT,
        id_modulo INTEGER,
        id_tipo INTEGER,
        titulo TEXT NOT NULL,
        estado TEXT DEFAULT 'Pendiente' CHECK(estado IN ('Pendiente', 'En Progreso', 'Completado')),
        orden INTEGER DEFAULT 0,
        fecha_creacion TEXT DEFAULT (date('now')),
        FOREIGN KEY (id_modulo) REFERENCES modulos(id_modulo) ON DELETE CASCADE,
        FOREIGN KEY (id_tipo) REFERENCES tipos_contenido(id_tipo)
    );

    -- Catálogo unificado de propiedades: cada propiedad se define UNA vez
    -- con su tipo de dato, y se reutiliza en cualquier contenido.
    CREATE TABLE IF NOT EXISTS propiedades_catalogo (
        id_propiedad INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre_propiedad TEXT NOT NULL UNIQUE,
        tipo_dato TEXT NOT NULL CHECK(tipo_dato IN ('numero','fecha','tags','texto','base64'))
    );

    CREATE TABLE IF NOT EXISTS contenido_propiedades (
        id_contenido INTEGER,
        id_propiedad INTEGER,
        valor TEXT,
        PRIMARY KEY (id_contenido, id_propiedad),
        FOREIGN KEY (id_contenido) REFERENCES contenidos(id_contenido) ON DELETE CASCADE,
        FOREIGN KEY (id_propiedad) REFERENCES propiedades_catalogo(id_propiedad) ON DELETE CASCADE
    );

    -- Índices para que las queries de progreso no se pongan lentas con el tiempo
    CREATE INDEX IF NOT EXISTS idx_modulos_curso ON modulos(id_curso);
    CREATE INDEX IF NOT EXISTS idx_contenidos_modulo ON contenidos(id_modulo);
    CREATE INDEX IF NOT EXISTS idx_contprop_contenido ON contenido_propiedades(id_contenido);

    -- Datos base: tipos de contenido más comunes (podés agregar más desde el menú)
    INSERT OR IGNORE INTO tipos_contenido (nombre_tipo) VALUES ('Video');
    INSERT OR IGNORE INTO tipos_contenido (nombre_tipo) VALUES ('Lectura');
    INSERT OR IGNORE INTO tipos_contenido (nombre_tipo) VALUES ('Laboratorio');
    INSERT OR IGNORE INTO tipos_contenido (nombre_tipo) VALUES ('Simulacro');

    -- Propiedades sugeridas relevantes a tu objetivo (LFCS/RHCSA, benchmark de tiempos)
    -- fecha: al asignarla, el sistema marca automáticamente el contenido como Completado
    INSERT OR IGNORE INTO propiedades_catalogo (nombre_propiedad, tipo_dato) VALUES ('codigo_lab', 'texto');
    INSERT OR IGNORE INTO propiedades_catalogo (nombre_propiedad, tipo_dato) VALUES ('dificultad', 'numero');
    INSERT OR IGNORE INTO propiedades_catalogo (nombre_propiedad, tipo_dato) VALUES ('minutos', 'numero');
    INSERT OR IGNORE INTO propiedades_catalogo (nombre_propiedad, tipo_dato) VALUES ('fecha', 'fecha');
    INSERT OR IGNORE INTO propiedades_catalogo (nombre_propiedad, tipo_dato) VALUES ('ruta_repo', 'texto');
    INSERT OR IGNORE INTO propiedades_catalogo (nombre_propiedad, tipo_dato) VALUES ('tags', 'tags');
    INSERT OR IGNORE INTO propiedades_catalogo (nombre_propiedad, tipo_dato) VALUES ('notas', 'base64');
SQL
}