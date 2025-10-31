#!/usr/bin/env python3
import os
import json

def create_lab(level, lab_number, lab_name, specializations):
    base_path = os.path.join("labs", level)
    lab_folder_name = f"{lab_number:03d}_{lab_name.replace(' ', '_').lower()}"
    lab_path = os.path.join(base_path, lab_folder_name)

    # Crear carpetas
    os.makedirs(lab_path, exist_ok=True)
    os.makedirs(os.path.join(lab_path, "configs"), exist_ok=True)

    # Crear lab_meta.json
    meta = {
        "lab_code": lab_folder_name,
        "name": lab_name,
        "level": level,
        "specializations": specializations
    }
    with open(os.path.join(lab_path, "lab_meta.json"), "w") as f:
        json.dump(meta, f, indent=4)

    # Crear README.md
    readme_content = f"""# {lab_folder_name}

## Objetivo
Explicación del laboratorio: {lab_name}

## Tareas
- Tarea 1
- Tarea 2
"""
    with open(os.path.join(lab_path, "README.md"), "w") as f:
        f.write(readme_content)

    # Crear setup.sh
    setup_content = """#!/bin/bash
# =================================================
# Setup inicial para el laboratorio
# =================================================

# Actualizar sistema
apt update && apt upgrade -y

# Crear carpeta de prueba
mkdir -p /tmp/lab
cd /tmp/lab

# Archivos de prueba
touch file1 file2
chmod 600 file1

echo "✅ Setup completado."
"""
    with open(os.path.join(lab_path, "setup.sh"), "w") as f:
        f.write(setup_content)
    os.chmod(os.path.join(lab_path, "setup.sh"), 0o755)

    # Crear Dockerfile
    dockerfile_content = f"""FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

COPY setup.sh /setup.sh
RUN chmod +x /setup.sh
RUN /setup.sh

CMD ["/bin/bash"]
"""
    with open(os.path.join(lab_path, "Dockerfile"), "w") as f:
        f.write(dockerfile_content)

    print(f"✅ Laboratorio '{lab_folder_name}' creado correctamente en {lab_path}")

# Ejemplo de uso
if __name__ == "__main__":
    # Nivel: level_1
    # Número: 1
    # Nombre: Problema de disco
    # Especializaciones: linux y security
    create_lab("level_1", 1, "Problema de disco", ["linux", "security"])
