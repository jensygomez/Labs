
# lab_platform/create_lab.py
#!/usr/bin/env python3
import os
import json
import sqlite3

DB_PATH = os.path.join("data", "database", "lab_platform.db")
TICKETS_PATH = os.path.join("tickets", "active_tickets")

def connect_db():
    return sqlite3.connect(DB_PATH)

def create_ticket(lab_code, level, description):
    # Asegurar carpeta de tickets
    os.makedirs(TICKETS_PATH, exist_ok=True)
    ticket = {
        "lab_code": lab_code,
        "level": level,
        "description": description,
        "status": "open"
    }
    ticket_filename = os.path.join(TICKETS_PATH, f"{lab_code}_ticket.json")
    with open(ticket_filename, "w") as f:
        json.dump(ticket, f, indent=4)
    print(f"🎫 Ticket creado en {ticket_filename}")

def create_lab(level, lab_number, lab_name, specializations, with_fault=False):
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

## Especializaciones
{', '.join(specializations)}

## Tareas
- Diagnosticar y resolver el problema reportado en el ticket.
"""
    with open(os.path.join(lab_path, "README.md"), "w") as f:
        f.write(readme_content)

    # Crear setup.sh con o sin fallo intencional
    if with_fault:
        # Falla de permiso erróneo para archivo crítico
        setup_content = """#!/bin/bash
# Setup con falla intencional: archivo con permiso incorrecto

apt update && apt upgrade -y

mkdir -p /tmp/lab
cd /tmp/lab

touch important_file
chmod 000 important_file  # Permisos que bloquean acceso

echo "✅ Setup completado con fallo intencional: archivo con permisos 000"
"""
        ticket_description = (
            "El servicio falla porque el archivo 'important_file' tiene permisos incorrectos "
            "(sin permiso de lectura o escritura). El técnico debe corregir estos permisos."
        )
    else:
        # Setup normal
        setup_content = """#!/bin/bash
# Setup inicial para el laboratorio

apt update && apt upgrade -y

mkdir -p /tmp/lab
cd /tmp/lab

touch file1 file2
chmod 600 file1

echo "✅ Setup completado."
"""
        ticket_description = None

    setup_path = os.path.join(lab_path, "setup.sh")
    with open(setup_path, "w") as f:
        f.write(setup_content)
    os.chmod(setup_path, 0o755)

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

    # Crear docker-compose minimalista
    docker_compose_content = f"""version: '3.9'
services:
  {lab_folder_name}:
    build: .
    container_name: {lab_folder_name}_container
    tty: true
"""
    with open(os.path.join(lab_path, "docker-compose.yml"), "w") as f:
        f.write(docker_compose_content)

    print(f"✅ Laboratorio '{lab_folder_name}' creado correctamente en {lab_path}")

    # Registrar laboratorio en base de datos
    conn = connect_db()
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS labs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            lab_code TEXT UNIQUE,
            name TEXT,
            level TEXT,
            specializations TEXT
        )
    """)
    cur.execute("""
        INSERT OR IGNORE INTO labs (lab_code, name, level, specializations)
        VALUES (?, ?, ?, ?)
    """, (lab_folder_name, lab_name, level, json.dumps(specializations)))
    conn.commit()
    conn.close()
    print(f"📚 Laboratorio '{lab_folder_name}' registrado en la base de datos.")

    # Crear ticket si lab con falla
    if with_fault:
        create_ticket(lab_folder_name, level, ticket_description)

# Ejemplo de uso
if __name__ == "__main__":
    create_lab("level_1", 1, "Problema de disco", ["linux", "security"], with_fault=True)
