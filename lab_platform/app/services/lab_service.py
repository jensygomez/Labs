# lab_platform/app/services/lab_service.py
import os
import json
import random
from app.utils.db_utils import get_connection


def get_available_lab_general(user_id, level):
    """
    Busca laboratorios disponibles directamente en labs/level_X/
    y retorna un lab aleatorio que el usuario no haya completado,
    junto con sus especializaciones.
    """
    level_path = os.path.join("labs", level)
    if not os.path.exists(level_path):
        return None, []

    labs = [d for d in os.listdir(level_path)
            if os.path.isdir(os.path.join(level_path, d))]

    # Conectar a la DB para saber qué labs ya completó el usuario
    conn = get_connection()
    cur = conn.cursor()
    # Consulta JOIN para obtener lab_code de labs completados por el usuario
    cur.execute("""
        SELECT labs.lab_code
        FROM user_labs
        JOIN labs ON user_labs.lab_id = labs.id
        WHERE user_labs.user_id = ? AND user_labs.completed = 1
    """, (user_id,))
    labs_completados = {row[0] for row in cur.fetchall()}
    conn.close()

    # Filtrar labs no completados
    labs_disponibles = []
    for lab in labs:
        if lab in labs_completados:
            continue
        meta_file = os.path.join(level_path, lab, "lab_meta.json")
        if os.path.exists(meta_file):
            with open(meta_file) as f:
                meta = json.load(f)
            specializations = meta.get("specializations", [])
        else:
            specializations = []
        labs_disponibles.append((lab, specializations))

    if not labs_disponibles:
        return None, []

    # Elegir uno al azar
    return random.choice(labs_disponibles)

import subprocess

def obtener_contenedor_id(nombre_contenedor):
    """
    Devuelve el ID completo de un contenedor Docker dado su nombre.
    Retorna None si no encuentra el contenedor.
    """
    try:
        resultado = subprocess.run(
            ["docker", "ps", "-q", "-f", f"name={nombre_contenedor}"],
            capture_output=True,
            text=True,
            check=True
        )
        container_id = resultado.stdout.strip()
        return container_id if container_id else None
    except subprocess.CalledProcessError:
        return None




def mark_lab_completed(user_id, lab_id):
    """
    Marca un laboratorio como completado por el usuario.
    user_id: ID del usuario
    lab_id: ID del laboratorio (entero, referencia a la tabla labs)
    """
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        INSERT OR IGNORE INTO user_labs (user_id, lab_id, completed)
        VALUES (?, ?, 1)
    """, (user_id, lab_id))

    # Si ya existía la fila y no estaba completada, la actualizamos a completada
    cur.execute("""
        UPDATE user_labs SET completed = 1
        WHERE user_id = ? AND lab_id = ?
    """, (user_id, lab_id))

    conn.commit()
    conn.close()
