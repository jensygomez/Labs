import os
import yaml  # Para leer YAMLs de forma segura
import sqlite3  # Para leer la DB si existe
from pathlib import Path

# Directorio raíz (asumiendo que se ejecuta desde ahí)
root_dir = '.'

def print_directory_structure(startpath):
    print("\n=== ESTRUCTURA DE DIRECTORIOS ===")
    for root, dirs, files in os.walk(startpath):
        level = root.replace(startpath, '').count(os.sep)
        indent = ' ' * 4 * level
        print(f"{indent}{os.path.basename(root)}/")
        subindent = ' ' * 4 * (level + 1)
        for f in files:
            print(f"{subindent}- {f}")

def read_yaml_file(filepath):
    try:
        with open(filepath, 'r') as file:
            data = yaml.safe_load(file)
            return yaml.dump(data, sort_keys=False)  # Devuelve como string bonito
    except Exception as e:
        return f"Error al leer {filepath}: {str(e)}"

def summarize_file_content(filepath):
    ext = Path(filepath).suffix
    if ext == '.yaml':
        return read_yaml_file(filepath)
    elif ext == '.py':
        try:
            with open(filepath, 'r') as file:
                lines = file.readlines()
                # Muestra las primeras 20 líneas (cabecera) y últimas 10 (final)
                summary = "Primeras 20 líneas:\n" + ''.join(lines[:20])
                summary += "\nÚltimas 10 líneas:\n" + ''.join(lines[-10:])
                return summary
        except Exception as e:
            return f"Error al leer {filepath}: {str(e)}"
    elif ext == '.db':
        try:
            conn = sqlite3.connect(filepath)
            cursor = conn.cursor()
            # Lista tablas
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
            tables = cursor.fetchall()
            summary = "Tablas en la DB:\n" + '\n'.join([t[0] for t in tables])
            # Para cada tabla, muestra esquema y primeras 5 filas
            for table in tables:
                table_name = table[0]
                cursor.execute(f"PRAGMA table_info({table_name});")
                schema = cursor.fetchall()
                summary += f"\n\nEsquema de {table_name}:\n" + '\n'.join([str(col) for col in schema])
                cursor.execute(f"SELECT * FROM {table_name} LIMIT 5;")
                rows = cursor.fetchall()
                summary += f"\nPrimeras 5 filas de {table_name}:\n" + '\n'.join([str(row) for row in rows])
            conn.close()
            return summary
        except Exception as e:
            return f"Error al leer DB {filepath}: {str(e)}"
    else:
        return f"Archivo {filepath} no es YAML, PY o DB – saltando resumen detallado."

def print_key_files_info(startpath):
    print("\n=== INFORMACIÓN IMPORTANTE DE ARCHIVOS CLAVE ===")
    key_files = []
    for root, _, files in os.walk(startpath):
        for file in files:
            if file.endswith(('.yaml', '.py', '.db')):
                key_files.append(os.path.join(root, file))
    
    for filepath in key_files:
        print(f"\n--- {filepath} ---")
        print(summarize_file_content(filepath))

# Ejecutar todo
print("DIAGNÓSTICO DEL PROYECTO RHCSA TRAINER")
print_directory_structure(root_dir)
print_key_files_info(root_dir)
