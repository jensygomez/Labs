#!/bin/bash
DB="lab.db"

echo "🗄️ Creando base de datos $DB en ~/Labs/lab_ejercicios..."

# Crear tabla principal
sqlite3 "$DB" "
CREATE TABLE IF NOT EXISTS ejercicios (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    bloque INTEGER NOT NULL,
    tema TEXT NOT NULL,
    nivel TEXT NOT NULL CHECK(nivel IN ('BÁSICO','INTERMEDIO','AVANZADO','TROUBLESHOOTING')),
    orden INTEGER NOT NULL,
    enunciado TEXT NOT NULL,
    completado INTEGER DEFAULT 0 CHECK(completado IN (0,1)),
    fecha_completado TEXT,
    notas TEXT,
    UNIQUE(bloque, tema, nivel, orden)
);
"

# Crear índices
sqlite3 "$DB" "
CREATE INDEX IF NOT EXISTS idx_bloque_completado ON ejercicios(bloque, completado);
CREATE INDEX IF NOT EXISTS idx_orden ON ejercicios(orden);
"

echo "✅ Base de datos creada: ~/Labs/lab_ejercicios/lab.db"
echo "📋 Tabla lista (0 ejercicios por ahora)"
