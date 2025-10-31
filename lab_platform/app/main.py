# lab_platform/app/main.py
import sys
import os

# Añade la ruta absoluta de la carpeta 'modules' al sys.path
modules_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'modules'))
if modules_path not in sys.path:
    sys.path.insert(0, modules_path)

# Ahora puedes importar tu módulo
import ticket_manager as tm

import subprocess
import shutil
import platform
from app.utils.db_utils import init_db
from app.utils.db_utils import init_db, agregar_columna_si_falta
from app.services.user_service import create_user, list_users, delete_user, edit_user
from app.services.lab_service import get_available_lab_general, mark_lab_completed
from app.services.docker_service import obtener_contenedor_id
from app.services.docker_service import obtener_contenedor_id


from app.services import docker_service

# Luego usas
#docker_service.obtener_contenedor_id(nombre_contenedor)





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
    # (Este método lo mantienes igual con la lógica para instalar docker si hace falta)
    pass

def llamar_run_lab(lab_path):
    script_path = os.path.join("scripts", "run_lab.py")
    try:
        subprocess.run(["python3", script_path, lab_path], check=True)
        return True
    except subprocess.CalledProcessError:
        print("❌ Error ejecutando la apertura del laboratorio.")
        return False

import json

def mostrar_ticket_en_pantalla(ticket_path):
    try:
        with open(ticket_path, "r") as f:
            ticket = json.load(f)
        print("\n===== Información del Ticket =====")
        print(f"Ticket ID: {ticket.get('ticket_id')}")
        print(f"Fecha creación: {ticket.get('fecha_creacion')}")
        colaborador = ticket.get('colaborador', {})
        print(f"Colaborador: {colaborador.get('nombre')} ({colaborador.get('email')})")
        print(f"Nivel: {colaborador.get('nivel')}")
        print(f"Descripción: {ticket.get('descripcion')}")
        print(f"Tipo equipo simulado: {ticket.get('tipo_equipo_simulado')}")
        acceso = ticket.get('datos_acceso', {})
        print(f"Contenedor ID: {acceso.get('contenedor_id')}")
        print(f"Nombre contenedor: {acceso.get('nombre_contenedor')}")
        print(f"Comando acceso: {acceso.get('comando_acceso')}")
        print(f"Estado: {ticket.get('estado')}")
        print(f"Prioridad: {ticket.get('prioridad')}")
        print("================================\n")
    except Exception as e:
        print(f"No se pudo cargar o mostrar el ticket: {e}")




def main():
    init_db()
    nombre_contenedor = f"{lab_elegido}_container"
    container_id = obtener_contenedor_id(nombre_contenedor)
    agregar_columna_si_falta()
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

        # Seleccionar nivel y laboratorio
        niveles = ["level_1", "level_2", "level_3"]
        print("\n--- Selección de nivel ---")
        idx = elegir_opcion(niveles, "Selecciona el nivel por número:")
        level = niveles[idx]

        # Aquí llamamos a tu función para ejecutar el script del laboratorio
        lab_elegido, lab_specializations = get_available_lab_general(user_id, level)
        if lab_elegido is None:
            print("⚠️ Ya completaste todos los laboratorios disponibles en este nivel.")
            continue

        lab_path = os.path.join("labs", level, lab_elegido)
        print(f"\n✅ Laboratorio asignado automáticamente: {lab_elegido} ({', '.join(lab_specializations)})")

        exito = llamar_run_lab(lab_path)        
        
        if exito:
            nombre_contenedor = f"{lab_elegido}_container"
            container_id = obtener_contenedor_id(nombre_contenedor)

            # Crear ticket JSON en carpeta tickets/active_tickets
            tm.crear_ticket(
                lab_elegido,
                usuario=user_name,
                email=user_email,
                nivel=level,
                container_id=container_id or "Desconocido",
                container_name=nombre_contenedor
            )

            # Mostrar el contenido del ticket en pantalla
            ticket_path = os.path.join("tickets", "active_tickets", f"{lab_elegido}_ticket.json")
            mostrar_ticket_en_pantalla(ticket_path)

            # Marcar laboratorio como completado
            mark_lab_completed(user_id, level, lab_elegido)
            print(f"\n🎉 Laboratorio '{lab_elegido}' marcado como completado y ticket generado.")

        
        
        
       

if __name__ == "__main__":
    main()
