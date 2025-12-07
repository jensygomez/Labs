# migrate_db.py - EJECUTAR UNA SOLA VEZ
import sqlite3
from pathlib import Path

db_path = Path("data/database/rhcsa_trainer.db")
conn = sqlite3.connect(db_path)
c = conn.cursor()

# Añadir columnas si no existen
c.execute("PRAGMA table_info(scenarios)")
columns = [row[1] for row in c.fetchall()]

if "type" not in columns:
    c.execute("ALTER TABLE scenarios ADD COLUMN type TEXT DEFAULT 'classic'")
if "path" not in columns:
    c.execute("ALTER TABLE scenarios ADD COLUMN path TEXT")

conn.commit()
conn.close()
print("Base de datos lista para ejercicios dinámicos con archivo único")
