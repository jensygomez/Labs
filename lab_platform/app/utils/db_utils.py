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

    cursor.execute('''CREATE TABLE IF NOT EXISTS labs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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
