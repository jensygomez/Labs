# app/services/docker_service.py
import subprocess

def obtener_contenedor_id(nombre_contenedor):
    try:
        resultado = subprocess.run(
            ["docker", "ps", "-q", "-f", f"name={nombre_contenedor}"],
            capture_output=True,
            text=True,
            check=True
        )
        return resultado.stdout.strip() or None
    except subprocess.CalledProcessError:
        return None
