#!/usr/bin/env python3
import subprocess
from pathlib import Path
import os


# Definimos ruta de los archivos de notas y logs
NOTAS = Path("/root/lab-notes.txt")
LOGS = Path("/root/lastlogs.txt")


# Funcion para ejecutar comando BASH sin mostrar salida
def ejecutar_comando(comando):
    resultado = subprocess.run(comando,shell=True,capture_output=True,text=True,executable="/bin/bash")
    return resultado.stdout.strip()

# Funcion para añadir texto a un archivo
def anadir_a_archivo(texto):
    with open(NOTAS, "a") as archivo:
        archivo.write(texto + "\n")  

# Definiendo el main
def main():
    anadir_a_archivo("=== Inicio de la Laboratorio 1 ===\n")
    ruta_script = os.path.abspath(__file__)
    anadir_a_archivo(f"Ruta absoluta del script: {ruta_script}")
    
    # cambiar al /usr/shaere usando ruta absoluta y validar
    os.chdir("/usr/share")
    ruta_actual = ejecutar_comando("pwd")
    anadir_a_archivo(f"cambié a: {ruta_actual}")
    
    # Volver al directorio HOME usando ruta relativa y validar
    usuario = ejecutar_comando("echo $USER")
    os.chdir(f"../../home/{usuario}")
    ruta_home = ejecutar_comando("pwd")
    anadir_a_archivo(f"volvi al HOME usando ruta relativa : {ruta_home}\n")
    
if __name__ == "__main__":
    main()
    

