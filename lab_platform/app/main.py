# lab_platform/app/main.py
import sys, os

# 🔧 Asegura que la carpeta raíz esté en sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.utils.db_utils import init_db
from app.services.user_service import create_user, list_users, delete_user, edit_user
from app.services.lab_service import get_available_lab, mark_lab_completed

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
        especializaciones = ["network", "linux", "security", "cloud", "kubernetes"]
        lab_elegido = None
        lab_specialization = None
        for specialization in especializaciones:
            lab_elegido = get_available_lab(user_id, level, specialization)
            if lab_elegido:
                lab_specialization = specialization
                break

        if lab_elegido:
            print(f"\n✅ Laboratorio asignado automáticamente: {lab_elegido} ({lab_specialization})")
            # ⚠️ Descomentar la siguiente línea cuando el usuario termine el laboratorio
            # mark_lab_completed(user_id, lab_elegido)
        else:
            print("⚠️ Ya completaste todos los laboratorios disponibles en este nivel.")

if __name__ == "__main__":
    main()
