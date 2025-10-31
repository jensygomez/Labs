import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), "../../data/database/lab_platform.db")

def get_connection():
    return sqlite3.connect(DB_PATH)

def init_db():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute('''CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE,
        level TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )''')

    # tabla labs con lab_code incluido
    cursor.execute('''CREATE TABLE IF NOT EXISTS labs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lab_code TEXT NOT NULL,
        name TEXT,
        level TEXT,
        specialization TEXT,
        path TEXT
    )''')

    cursor.execute('''CREATE TABLE IF NOT EXISTS user_labs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        lab_id INTEGER,
        start_time DATETIME,
        end_time DATETIME,
        completed BOOLEAN DEFAULT 0
    )''')

    conn.commit()
    conn.close()

def agregar_columna_si_falta():
    # Intenta agregar la columna lab_code a labs si no existe
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("ALTER TABLE labs ADD COLUMN lab_code TEXT;")
        print("Columna 'lab_code' agregada a la tabla 'labs'.")
    except sqlite3.OperationalError as e:
        # Si ya existe la columna, no pasa nada
        if "duplicate column name" in str(e):
            pass
        else:
            print(f"Error al agregar columna: {e}")
    conn.commit()
    conn.close()


