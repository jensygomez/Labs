# lab_platform/test_lab_flow.py
import os
from app.utils.db_utils import init_db
from app.services.user_service import create_user, list_users
from app.services.lab_service import get_available_lab_general, mark_lab_completed

def main():
    # Inicializar DB
    init_db()

    print("===================================")
    print("  🧪 Simulación de Plataforma IT  ")
    print("===================================")

    # Crear un usuario de prueba si no hay ninguno
    usuarios = list_users()
    if not usuarios:
        print("Creando usuario de prueba...")
        create_user("Test User", "test@example.com")
        usuarios = list_users()

    user = usuarios[0]
    user_id = user['id']
    print(f"\nUsuario seleccionado para prueba: {user['name']} ({user['email']})\n")

    # Niveles de prueba
    niveles = ["level_1", "level_2", "level_3"]

    for level in niveles:
        print(f"--- Probando nivel {level} ---")
        lab, specs = get_available_lab_general(user_id, level)
        if lab:
            print(f"✅ Laboratorio asignado: {lab} ({', '.join(specs)})")
            # Simular ejecución
            print(f"Simulando ejecución de {lab}...")
            # Marcar como completado
            mark_lab_completed(user_id, lab)
            print(f"🎉 Laboratorio '{lab}' marcado como completado.\n")
        else:
            print("⚠️ No hay laboratorios disponibles o ya completados.\n")

    print("Simulación completa.")

if __name__ == "__main__":
    main()
