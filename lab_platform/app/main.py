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
    """Permite elegir una opción de la lista por número"""
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


def preparar_sistema():
    """Detecta el gestor de paquetes y asegura que Docker y Docker Compose estén instalados"""
    # Detectar gestor de paquetes
    if shutil.which("apt"):
        pkg_mgr = "apt"
        update_cmd = ["sudo", "apt", "update"]
        upgrade_cmd = ["sudo", "apt", "upgrade", "-y"]
        install_cmd = lambda pkg: ["sudo", "apt", "install", "-y", pkg]
    elif shutil.which("dnf"):
        pkg_mgr = "dnf"
        update_cmd = ["sudo", "dnf", "check-update"]
        upgrade_cmd = ["sudo", "dnf", "upgrade", "-y"]
        install_cmd = lambda pkg: ["sudo", "dnf", "install", "-y", pkg]
    elif shutil.which("yum"):
        pkg_mgr = "yum"
        update_cmd = ["sudo", "yum", "check-update"]
        upgrade_cmd = ["sudo", "yum", "update", "-y"]
        install_cmd = lambda pkg: ["sudo", "yum", "install", "-y", pkg]
    elif shutil.which("pacman"):
        pkg_mgr = "pacman"
        update_cmd = ["sudo", "pacman", "-Sy"]
        upgrade_cmd = ["sudo", "pacman", "-Syu", "--noconfirm"]
        install_cmd = lambda pkg: ["sudo", "pacman", "-S", pkg, "--noconfirm"]
    else:
        print("⚠️ No se detectó un gestor de paquetes conocido. Instala Docker y Docker Compose manualmente.")
        return

    print(f"🔍 Gestor de paquetes detectado: {pkg_mgr}")
    subprocess.run(update_cmd)
    subprocess.run(upgrade_cmd)

    # Instalar Docker si no está
    if shutil.which("docker") is None:
        print("🐳 Docker no encontrado. Instalando Docker...")
        subprocess.run(install_cmd("docker.io" if pkg_mgr == "apt" else "docker"))

    # Instalar Docker Compose si no está
    if subprocess.run(["docker", "compose", "version"], capture_output=True).returncode != 0:
        print("🔧 Docker Compose no encontrado. Instalando plugin...")
        subprocess.run(install_cmd("docker-compose-plugin" if pkg_mgr == "apt" else "docker-compose"))





def iniciar_lab_docker(lab_path):
    """Inicia docker-compose del laboratorio y espera a que el usuario finalice"""
    preparar_sistema()  # Detecta Linux y asegura dependencias
    dc_file = os.path.join(lab_path, "docker-compose.yml")
    if os.path.exists(dc_file):
        print(f"\n🚀 Iniciando laboratorio en {lab_path}...")
        print("⚠️ Para salir del laboratorio, presiona Ctrl+C o finaliza la sesión dentro de Docker.\n")
        try:
            subprocess.run(["docker", "compose", "-f", dc_file, "up"])
        except KeyboardInterrupt:
            print("\n⏹️ Laboratorio detenido por el usuario.")
        finally:
            opcion = input("¿Deseas detener y eliminar los contenedores de este laboratorio? (s/n): ").lower()
            if opcion == "s":
                subprocess.run(["docker", "compose", "-f", dc_file, "down"])
            return True
    else:
        print("⚠️ No se encontró docker-compose.yml en este laboratorio")
        return False

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
                    idx = elegir_opcion([f"{u['name']} - {u['email']}" for u in usuarios],
                                        "Selecciona usuario a editar:")
                    if idx is not None:
                        edit_user(usuarios[idx]['id'])
                    continue
                elif opcion == n+3:
                    idx = elegir_opcion([f"{u['name']} - {u['email']}" for u in usuarios],
                                        "Selecciona usuario a eliminar:")
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

        # Asignar laboratorio automáticamente en cualquier especialización disponible
        lab_elegido, lab_specializations = get_available_lab_general(user_id, level)

        if lab_elegido:
            print(f"\n✅ Laboratorio asignado automáticamente: {lab_elegido} ({', '.join(lab_specializations)})")

            # Construir ruta completa del lab
            lab_path = os.path.join("labs", level, lab_elegido)

            # Iniciar Docker del laboratorio
            terminado = iniciar_lab_docker(lab_path)

            # Si finalizó correctamente, marcar como completado
            if terminado:
                mark_lab_completed(user_id, level, lab_elegido)
                print(f"\n🎉 Laboratorio '{lab_elegido}' marcado como completado.")

        else:
            print("⚠️ Ya completaste todos los laboratorios disponibles en este nivel.")

if __name__ == "__main__":
    main()
