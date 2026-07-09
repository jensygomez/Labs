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
