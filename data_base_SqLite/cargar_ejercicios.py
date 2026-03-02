import yaml
import sqlite3
import base64
import os

# Configuración
YAML_FILE = 'ejercicios.yaml'
DB_FILE = 'ejercicios.db'

def cargar():
    if not os.path.exists(YAML_FILE):
        print(f"❌ Error: No se encuentra {YAML_FILE}")
        return

    # Conectar a la DB
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()

    # Leer YAML
    with open(YAML_FILE, 'r', encoding='utf-8') as f:
        ejercicios = yaml.safe_load(f)

    print(f"🚀 Procesando {len(ejercicios)} ejercicios...")

    for ej in ejercicios:
        # Convertir enunciado a Base64
        enunciado_raw = ej['enunciado'].strip()
        enunciado_b64 = base64.b64encode(enunciado_raw.encode('utf-8')).decode('utf-8')

        # Insertar o Reemplazar
        try:
            cursor.execute('''
                INSERT OR REPLACE INTO ejercicios 
                (bloque, tema, nivel, orden, enunciado, dificultad, completado)
                VALUES (?, ?, ?, ?, ?, ?, 0)
            ''', (ej['bloque'], ej['tema'], ej['nivel'], ej['orden'], enunciado_b64, ej['dificultad']))
        except Exception as e:
            print(f"❌ Error insertando ejercicio {ej['orden']}: {e}")

    conn.commit()
    conn.close()
    print("✅ Base de datos actualizada con enunciados en Base64.")

if __name__ == "__main__":
    cargar()