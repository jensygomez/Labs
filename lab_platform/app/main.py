# lab_platform/app/main.py
import sys, os
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
    """Detecta la distro y versión de Linux y actualiza paquetes e instala Docker si hace falta"""
    distro_info = {}
    if os.path.exists("/etc/os-release"):
        with open("/etc/os-release") as f:
            for line in f:
                if "=" in line:
                    key, val = line.strip().split("=", 1)
                    distro_info[key] = val.strip('"')
    nombre = distro_info.get("NAME", platform.system())
    version = distro_info.get("VERSION_ID", platform.release())

    print(f"🔍 Sistema detectado: {nombre} {version}")

    if "Ubuntu" in nombre or "Debian" in nombre:
        print("⚙️ Actualizando sistema y dependencias...")
        subprocess.run(["sudo", "apt", "update"])
        subprocess.run(["sudo", "apt", "upgrade", "-y"])

        # Instalar Docker si no está
        if subprocess.run(["which", "docker"], capture_output=True).returncode != 0:
            print("🐳 Docker no encontrado. Instalando Docker...")
            subprocess.run(["sudo", "apt", "install", "-y", "docker.io"])

        # Instalar Docker Compose si no está
        if subprocess.run(["docker", "compose", "version"], capture_output=True).returncode != 0:
            print("🔧 Docker Compose no encontrado. Instalando plugin...")
            subprocess.run(["sudo", "apt", "install", "-y", "docker-compose-plugin"])
    else:
        print("⚠️ Sistema no reconocido. Asegúrate de tener Docker y Docker Compose instalados.")

def iniciar_lab_docker(lab_path):
    """Inicia docker-compose del laboratorio y espera a que el usuario finalice"""
    preparar_sistema()  # <-- Detecta Linux y asegura dependencias
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

        # Buscar laboratorio disponible en cualquier carpeta de level_X
        lab_elegido, lab_specialization = get_available_lab_general(user_id, level)

        if lab_elegido:
            print(f"\n✅ Laboratorio asignado automáticamente: {lab_elegido} ({', '.join(lab_specialization)})")
            lab_path = os.path.join("labs", level, lab_elegido)

            # Iniciar Docker del laboratorio
            terminado = iniciar_lab_docker(lab_path)

            # Si finalizó correctamente, marcar como completado
            if terminado:
                mark_lab_completed(user_id, lab_elegido)
                print(f"\n🎉 Laboratorio '{lab_elegido}' marcado como completado para el usuario.")
        else:
            print("⚠️ Ya completaste todos los laboratorios disponibles en este nivel.")

if __name__ == "__main__":
    main()
