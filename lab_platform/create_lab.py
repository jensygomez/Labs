
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
        "specializations": specializations,
        "lab_type": "performance_troubleshooting",
        "performance_issues": [
            "Alta latencia de disco (200ms simulados)",
            "Proceso consumiendo 100% CPU",
            "Memoria SWAP excesiva",
            "Procesos zombies"
        ]
    }
    with open(os.path.join(lab_path, "lab_meta.json"), "w") as f:
        json.dump(meta, f, indent=4)

    # Crear README.md - CORREGIDO
    readme_content = f"""# {lab_folder_name}

## Objetivo
Diagnosticar y resolver problemas de performance en un servidor Linux. Los usuarios reportan lentitud extrema, aplicaciones congeladas y inestabilidad del sistema después de una actualización reciente.

## Especializaciones
{', '.join(specializations)}

## Problemas Simulados
1. **Alta Latencia de Disco**: Disco configurado con 200ms de latencia (como HDD viejo)
2. **CPU Sobreutilizado**: Proceso mal comportado consumiendo 100% de CPU
3. **Memoria SWAP**: Consumo agresivo de memoria forzando swapping
4. **Procesos Zombies**: Procesos defuntos afectando el sistema

## Tareas
- Identificar el proceso que consume 100% CPU usando `top` y `ps`
- Detectar alta latencia de disco con `iostat -x 1`
- Encontrar procesos zombies con `ps aux | grep defunct`
- Verificar uso de swap con `free -h` y `vmstat`
- Documentar cada problema encontrado y su solución

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

# Logs del sistema
dmesg | tail -20