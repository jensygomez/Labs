import yaml
import sqlite3
import base64
import os

YAML_FILE = 'ejercicios.yaml'
DB_FILE = 'ejercicios.db'

def menu_carga():
    if not os.path.exists(YAML_FILE):
        print(f"❌ Error: No existe {YAML_FILE}")
        return

    print("\n--- 🛠️ GESTIÓN DE BASE DE DATOS ---")
    print("1) ⚠️ REINICIAR: Borrar todo y cargar desde cero (Se pierde el progreso)")
    print("2) 📥 ACTUALIZAR: Solo agregar ejercicios nuevos (Mantiene tu progreso)")
    print("0) 🔙 Cancelar")
    
    opcion = input("\nElige una opción: ")

    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()

    if opcion == '1':
        confirmar = input("❗ ¿ESTÁS SEGURO? Perderás todos los ejercicios completados (s/n): ")
        if confirmar.lower() == 's':
            cursor.execute("DELETE FROM ejercicios;")
            conn.commit()
            print("🧹 Base de datos vaciada.")
        else:
            return

    elif opcion == '2':
        print("🔍 Buscando novedades en el YAML...")
    else:
        return

    # Proceso de carga común
    with open(YAML_FILE, 'r', encoding='utf-8') as f:
        ejercicios = yaml.safe_load(f)

    nuevos = 0
    for ej in ejercicios:
        enunciado_b64 = base64.b64encode(ej['enunciado'].strip().encode('utf-8')).decode('utf-8')
        # Usamos INSERT OR IGNORE para la opción 2
        cursor.execute('''
            INSERT OR IGNORE INTO ejercicios 
            (bloque, tema, nivel, orden, enunciado, dificultad, completado)
            VALUES (?, ?, ?, ?, ?, ?, 0)
        ''', (ej['bloque'], ej['tema'], ej['nivel'], ej['orden'], enunciado_b64, ej['dificultad']))
        if cursor.rowcount > 0:
            nuevos += 1

    conn.commit()
    conn.close()
    print(f"✅ Proceso terminado. Se añadieron {nuevos} ejercicios.")

if __name__ == "__main__":
    menu_carga()