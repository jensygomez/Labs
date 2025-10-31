
# lab_platform/create_lab.py
#!/usr/bin/env python3
import os
import json
import sqlite3

DB_PATH = os.path.join("data", "database", "lab_platform.db")

def connect_db():
    return sqlite3.connect(DB_PATH)

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
Diagnosticar problemas de performance en un servidor Linux. Identificar procesos que consumen excesivos recursos del sistema.

## Especializaciones
{', '.join(specializations)}

## Tareas
- Identificar el proceso que consume 100% de CPU
- Detectar alta latencia en operaciones de disco
- Encontrar procesos zombies en el sistema
- Verificar uso excesivo de memoria swap
- Documentar cada problema encontrado

## Comandos Útiles
```bash
# Monitoreo general
top
htop
uptime

# Diagnóstico de disco
iostat -x 1
iotop

# Diagnóstico de memoria
free -h
vmstat 1 5

# Procesos
ps aux --sort=-%cpu | head -5
ps aux --sort=-%mem | head -5
ps aux | grep defunct