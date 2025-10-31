import os

def print_file_content(path, max_lines=10):
    try:
        with open(path, 'r', encoding='utf-8', errors='ignore') as f:
            print(f"--- Contenido de {path} (primeros {max_lines} líneas) ---")
            for i, line in enumerate(f):
                if i >= max_lines:
                    print("[...]")
                    break
                print(line.rstrip())
            print()
    except Exception as e:
        print(f"No se pudo leer {path}: {e}")

def explore_and_show(path, indent=0):
    if not os.path.exists(path):
        print(f"Ruta no encontrada: {path}")
        return
    entries = sorted(os.listdir(path))
    for entry in entries:
        full_path = os.path.join(path, entry)
        prefix = ' ' * indent
        if os.path.isdir(full_path):
            print(f"{prefix}[DIR]  {entry}/")
            explore_and_show(full_path, indent + 4)
        else:
            print(f"{prefix}[FILE] {entry}")
            # Mostrar contenido para archivos pequeños o específicos
            if entry.endswith(('.sh', '.json', '.yml', '.md', 'Dockerfile')):
                print_file_content(full_path, max_lines=15)

if __name__ == "__main__":
    base_path = "lab_platform/labs"
    print(f"Explorando y mostrando contenido en: {base_path}\n")
    explore_and_show(base_path)
