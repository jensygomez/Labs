#!/usr/bin/env python3
import os
import sys
import subprocess

def run_lab(lab_path):
    if not os.path.exists(lab_path):
        print(f"❌ Ruta no encontrada: {lab_path}")
        sys.exit(1)

    print(f"🔨 Construyendo imagen Docker para laboratorio en {lab_path} ...")
    try:
        subprocess.run(["docker-compose", "build"], cwd=lab_path, check=True)
    except subprocess.CalledProcessError as e:
        print(f"❌ Error construyendo imagen Docker: {e}")
        sys.exit(1)

    print(f"🚀 Levantando contenedor Docker para laboratorio en {lab_path} ...")
    try:
        subprocess.run(["docker-compose", "up", "-d"], cwd=lab_path, check=True)
    except subprocess.CalledProcessError as e:
        print(f"❌ Error levantando contenedor Docker: {e}")
        sys.exit(1)

    print(f"✅ Laboratorio iniciado correctamente.")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Uso: python3 run_lab.py <ruta_al_laboratorio>")
        sys.exit(1)

    lab_path = sys.argv[1]
    run_lab(lab_path)
