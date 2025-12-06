#!/usr/bin/env python3
"""
SCRIPT ÚNICO - Crea COMPLETA la base de datos RHCSA Lab Trainer
"""
import sqlite3
from pathlib import Path

def create_complete_database():
    db_path = Path("data/database/rhcsa_trainer.db")
    db_path.parent.mkdir(parents=True, exist_ok=True)
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    print("🗄️  Creando base de datos RHCSA Lab Trainer...")
    
    # Tabla scenarios
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS scenarios (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            module TEXT NOT NULL,
            difficulty INTEGER NOT NULL CHECK (difficulty IN (1,2,3)),
            points INTEGER NOT NULL,
            description TEXT,
            repetitions_required INTEGER DEFAULT 1,
            created_at TEXT DEFAULT (datetime('now'))
        )
    ''')
    
    # Tabla progress
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS progress (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            scenario_id TEXT NOT NULL,
            completed_at TEXT NOT NULL DEFAULT (datetime('now')),
            time_seconds INTEGER NOT NULL,
            attempts INTEGER DEFAULT 1,
            score INTEGER NOT NULL CHECK (score >= 0 AND score <= 100),
            FOREIGN KEY (scenario_id) REFERENCES scenarios(id)
        )
    ''')
    
    # Índices
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_progress_scenario ON progress(scenario_id)')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_progress_date ON progress(completed_at)')
    
    conn.commit()
    conn.close()
    
    print(f"✅ ¡BASE DE DATOS CREADA EXITOSAMENTE!")
    print(f"📁 Ubicación: {db_path.absolute()}")

if __name__ == "__main__":
    create_complete_database()
