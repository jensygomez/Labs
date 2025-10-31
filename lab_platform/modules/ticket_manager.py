# lab_platform/modules/ticket_manager.py
import os
import json
from datetime import datetime

def crear_ticket(lab_elegido, usuario, email, nivel, container_id, container_name):
    ticket = {
        "ticket_id": lab_elegido,
        "fecha_creacion": datetime.utcnow().isoformat() + "Z",
        "colaborador": {
            "nombre": usuario,
            "email": email,
            "nivel": nivel
        },
        "descripcion": "En el servidor de archivos tenemos un error de permisos que impide el acceso al archivo important_file. El técnico debe corregir los permisos para restaurar el servicio.",
        "tipo_equipo": "servidor de archivos Docker",
        "datos_acceso": {
            "contenedor_id": container_id,
            "nombre_contenedor": container_name,
            "comando_acceso": f"sudo docker exec -it {container_name} /bin/bash"
        },
        "estado": "abierto",
        "prioridad": "alta"
    }

    dir_tickets = os.path.join("tickets", "active_tickets")
    os.makedirs(dir_tickets, exist_ok=True)
    ruta_ticket = os.path.join(dir_tickets, f"{lab_elegido}_ticket.json")
    with open(ruta_ticket, "w") as f:
        json.dump(ticket, f, indent=4)

    print(f"🎫 Ticket generado en {ruta_ticket}")
