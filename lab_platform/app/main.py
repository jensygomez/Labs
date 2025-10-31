
import sys, os

# 🔧 Asegura que la carpeta raíz esté en sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.utils.db_utils import init_db
from app.services.user_service import create_user, select_user, list_users, delete_user, edit_user
from app.services.lab_service import list_labs


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

        # Elegir especialización
        especializaciones = ["network", "linux", "security", "cloud", "kubernetes"]
        print("\n--- Selección de laboratorio ---")
        idx2 = elegir_opcion(especializaciones, "Selecciona la especialización por número:")
        specialization = especializaciones[idx2]

        # Listar laboratorios disponibles
        labs = list_labs(level, specialization)
        if labs:
            print("\n📦 Laboratorios disponibles:")
            idx3 = elegir_opcion(labs, "Selecciona un laboratorio por número:")
            lab_elegido = labs[idx3]
            print(f"\n✅ Laboratorio seleccionado: {lab_elegido}")
        else:
            print("⚠️ No hay laboratorios disponibles en esa categoría.")


if __name__ == "__main__":
    main()
