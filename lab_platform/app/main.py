# lab_platform/app/main.py
# lab_platform/app/main.py
import shutil
import sys
import os
import subprocess
import platform

# 🔧 Asegura que la carpeta raíz esté en sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.utils.db_utils import init_db
from app.services.user_service import create_user, list_users, delete_user, edit_user
from app.services.lab_service import get_available_lab_general, mark_lab_completed

def elegir_opcion(lista, titulo="Selecciona una opción:"):
    if not lista:
        print("⚠️ No hay opciones disponibles.")
        return None
    while True:
        for idx, item in enumerate(lista, 1):
            print(f"[{idx}] {item}")
        eleccion = input(f"{titulo} ")
        if eleccion.isdigit() and 1 <= int(eleccion) <= len(lista):
            return int(eleccion) - 1
        else:
            print("❌ Opción no válida, intenta de nuevo.")

def detectar_gestor_paquetes():
    """Detecta el gestor de paquetes disponible en Linux"""
    if shutil.which("apt"):
        return "apt"
    elif shutil.which("dnf"):
        return "dnf"
    elif shutil.which("yum"):
        return "yum"
    elif shutil.which("pacman"):
        return "pacman"
    else:
        return None

def preparar_sistema():
    """Detecta Linux, actualiza repositorios e instala Docker y Docker Compose si hace falta"""
    print(f"🔍 Sistema detectado: {platform.system()} {platform.release()}")
    gestor = detectar_gestor_paquetes()
    if gestor is None:
        print("⚠️ No se detectó un gestor de paquetes conocido. Instala Docker y Docker Compose manualmente.")
        return None

    print(f"🔧 Gestor de paquetes detectado: {gestor}")

    # Comandos según gestor de paquetes
    if gestor == "apt":
        subprocess.run(["sudo", "apt", "update"])
        subprocess.run(["sudo", "apt", "upgrade", "-y"])
        install = lambda pkg: subprocess.run(["sudo", "apt", "install", "-y", pkg])
    elif gestor in ["dnf", "yum"]:
        subprocess.run(["sudo", gestor, "check-update"])
        subprocess.run(["sudo", gestor, "upgrade", "-y"])
        install = lambda pkg: subprocess.run(["sudo", gestor, "install", "-y", pkg])
    elif gestor == "pacman":
        subprocess.run(["sudo", "pacman", "-Syu", "--noconfirm"])
        install = lambda pkg: subprocess.run(["sudo", "pacman", "-S", pkg, "--noconfirm"])

    # Instalar Docker si no existe
    if shutil.which("docker") is None:
        print("🐳 Docker no encontrado. Instalando...")
        install("docker.io" if gestor == "apt" else "docker")

    # Detectar Docker Compose
    dc_path = "/usr/local/bin/docker-compose"
    compose_cmd = None
    if shutil.which("docker-compose"):
        compose_cmd = ["docker-compose"]
    elif shutil.which("docker") and subprocess.run(
        ["docker", "compose", "version"], capture_output=True
    ).returncode == 0:
        compose_cmd = ["docker", "compose"]

    # Instalar Docker Compose si no existe
    if compose_cmd is None:
        print("⚠️ Docker Compose no encontrado. Instalando versión oficial...")
        if os.path.exists(dc_path):
            os.remove(dc_path)

        url = f"https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)"
        subprocess.run(f"sudo curl -L {url} -o {dc_path}", shell=True, check=True)
        subprocess.run(f"sudo chmod +x {dc_path}", shell=True, check=True)

        # Verificar instalación
        result = subprocess.run([dc_path, "version"], capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ Docker Compose instalado correctamente: {result.stdout.strip()}")
            compose_cmd = [dc_path]
        else:
            print("❌ Error al instalar Docker Compose. Instálalo manualmente.")
            compose_cmd = None
    else:
        print(f"✅ Docker Compose detectado: {' '.join(compose_cmd)}")

    return compose_cmd

def iniciar_lab_docker(lab_path):
    """Inicia Docker Compose del laboratorio y espera a que el usuario finalice"""
    compose_cmd = preparar_sistema()
    if compose_cmd is None:
        print("❌ No se puede iniciar el laboratorio sin Docker Compose.")
        return False

    dc_file = os.path.join(lab_path, "docker-compose.yml")
    if not os.path.exists(dc_file):
        print("⚠️ No se encontró docker-compose.yml en este laboratorio")
        return False

    print(f"\n🚀 Iniciando laboratorio en {lab_path}...")
    print("⚠️ Para salir del laboratorio, presiona Ctrl+C o finaliza la sesión dentro de Docker.\n")

    try:
        subprocess.run(compose_cmd + ["-f", dc_file, "up"])
    except KeyboardInterrupt:
        print("\n⏹️ Laboratorio detenido por el usuario.")
    finally:
        opcion = input("¿Deseas detener y eliminar los contenedores de este laboratorio? (s/n): ").lower()
        if opcion == "s":
            subprocess.run(compose_cmd + ["-f", dc_file, "down"])
        return True

def main():
    init_db()
    print("===================================")
    print("  🧠 Plataforma de Laboratorios IT ")
    print("===================================")

    while True:
        usuarios = list_users()
        n = len(usuarios)

        if usuarios:
            print("\nUsuarios registrados:")
            for idx, u in enumerate(usuarios, 1):
                print(f"[{idx}] {u['name']} - {u['email']}")

            print(f"[{n+1}] Crear nuevo usuario")
            print(f"[{n+2}] Editar usuario")
            print(f"[{n+3}] Eliminar usuario")
            print(f"[{n+4}] Salir del sistema")

            opcion = input("\nSelecciona una opción: ")
            if opcion.isdigit():
                opcion = int(opcion)
                if 1 <= opcion <= n:
                    user_id = usuarios[opcion-1]['id']
                elif opcion == n+1:
                    name = input("Nombre del usuario: ")
                    email = input("Email: ")
                    create_user(name, email)
                    continue
                elif opcion == n+2:
                    idx = elegir_opcion([f"{u['name']} - {u['email']}" for u in usuarios], "Selecciona usuario a editar:")
                    if idx is not None:
                        edit_user(usuarios[idx]['id'])
                    continue
                elif opcion == n+3:
                    idx = elegir_opcion([f"{u['name']} - {u['email']}" for u in usuarios], "Selecciona usuario a eliminar:")
                    if idx is not None:
                        delete_user(usuarios[idx]['id'])
                    continue
                elif opcion == n+4:
                    print("👋 Saliendo del sistema. ¡Hasta luego!")
                    break
                else:
                    print("❌ Opción no válida.")
                    continue
            else:
                print("❌ Opción no válida.")
                continue
        else:
            print("\n⚠️ No hay usuarios registrados. Debes crear uno primero.")
            name = input("Nombre del usuario: ")
            email = input("Email: ")
            create_user(name, email)
            continue

        # Elegir nivel
        niveles = ["level_1", "level_2", "level_3"]
        print("\n--- Selección de nivel ---")
        idx = elegir_opcion(niveles, "Selecciona el nivel por número:")
        level = niveles[idx]

        # Asignar laboratorio automáticamente
        lab_elegido, lab_specializations = get_available_lab_general(user_id, level)
        if lab_elegido:
            print(f"\n✅ Laboratorio asignado automáticamente: {lab_elegido} ({', '.join(lab_specializations)})")
            lab_path = os.path.join("labs", level, lab_elegido)
            terminado = iniciar_lab_docker(lab_path)
            if terminado:
                mark_lab_completed(user_id, lab_elegido)
                print(f"\n🎉 Laboratorio '{lab_elegido}' marcado como completado.")
        else:
            print("⚠️ Ya completaste todos los laboratorios disponibles en este nivel.")

if __name__ == "__main__":
    main()
