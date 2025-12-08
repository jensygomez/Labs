import os
import sqlite3

DB_PATH = './data/database/rhcsa_trainer.db'

def create_database():
    # Elimina DB anterior si existe
    if os.path.exists(DB_PATH):
        print(f"Eliminando base de datos existente: {DB_PATH}")
        os.remove(DB_PATH)

    # Crear nueva DB y tablas
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # Crear tabla labs
    cursor.execute("""
    CREATE TABLE labs (
      id TEXT PRIMARY KEY,
      module TEXT,
      submodule TEXT,
      title TEXT,
      subtitle TEXT,
      difficulty INTEGER,
      points INTEGER,
      repetitions_required INTEGER,
      repetitions_completed INTEGER DEFAULT 0,
      
      last_reviewed DATETIME,
      next_review DATE,
      interval_days INTEGER DEFAULT 1,
      ease_factor REAL DEFAULT 2.5,
      
      best_score REAL DEFAULT 0,
      avg_time_seconds INTEGER DEFAULT 0,
      total_attempts INTEGER DEFAULT 0,
      mastery_level TEXT DEFAULT 'novato',
      streak INTEGER DEFAULT 0,
      badges TEXT,
      
      scenario_text TEXT,
      expected_text TEXT,
      setup_ssh TEXT,
      
      vm_ip TEXT DEFAULT '192.168.1.100',
      vm_user TEXT DEFAULT 'rhcsa_lab',
      
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
    """)

    # Crear tabla modules para jerarquía
    cursor.execute("""
    CREATE TABLE modules (
      id TEXT PRIMARY KEY,
      name TEXT,
      order_num REAL,
      labs_count INTEGER
    )
    """)

    conn.commit()
    conn.close()
    print("Base de datos creada correctamente.")

if __name__ == "__main__":
    create_database()

