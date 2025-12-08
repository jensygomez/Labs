import os

# Directorio raíz (asumiendo que se ejecuta desde ahí)
root_dir = '.'

def print_directory_structure(startpath):
    print("\n=== ESTRUCTURA DE DIRECTORIOS ===")
    exclude_dirs = {'.git', '__pycache__', '.venv', 'node_modules'}
    exclude_ext = {'.pyc', '.tmp', '.log'}
    
    for root, dirs, files in os.walk(startpath):
        # Filtrar directorios excluidos
        dirs[:] = [d for d in dirs if d not in exclude_dirs]
        
        level = root.replace(startpath, '').count(os.sep)
        indent = ' ' * 4 * level
        print(f"{indent}{os.path.basename(root)}/")
        subindent = ' ' * 4 * (level + 1)
        
        # Filtrar archivos por extensión
        for f in files:
            if not any(f.endswith(ext) for ext in exclude_ext):
                print(f"{subindent}- {f}")

# Ejecutar
print("DIAGNÓSTICO DEL PROYECTO RHCSA TRAINER")
print_directory_structure(root_dir)