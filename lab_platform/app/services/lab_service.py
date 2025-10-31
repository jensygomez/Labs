# lab_platform/app/services/lab_service.py
import os, random
from app.utils.db_utils import get_connection

LABS_PATH = os.path.join(os.path.dirname(__file__), "../../labs")

def list_labs(level, specialization):
    labs_dir = os.path.join(LABS_PATH, level, specialization)
    if not os.path.exists(labs_dir):
        print("⚠️ No existen laboratorios en esa categoría.")
        return []

    labs = [d for d in os.listdir(labs_dir) if os.path.isdir(os.path.join(labs_dir, d))]
    return labs


def get_available_lab(user_id, level, specialization):
    """Devuelve un laboratorio aleatorio que el usuario aún no ha completado"""
    labs = list_labs(level, specialization)
    if not labs:
        return None

    # Labs ya completados por el usuario
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT lab_name FROM user_labs WHERE user_id=? AND completed=1", (user_id,))
    done = [r[0] for r in cur.fetchall()]
    conn.close()

    # Filtra los labs ya completados
    remaining = [lab for lab in labs if lab not in done]

    if not remaining:
        return None  # No hay labs disponibles
    return random.choice(remaining)


# lab_platform/app/services/lab_service.py
def mark_lab_completed(user_id, level, lab_name):
    """Marca un laboratorio como completado por el usuario"""
    conn = get_connection()
    cur = conn.cursor()
    
    lab_code = f"{level}_{lab_name}"  # Ej: level_1_001_problema_de_disco

    cur.execute(
        "INSERT OR IGNORE INTO user_labs (user_id, lab_code, lab_name, completed) VALUES (?, ?, ?, 1)",
        (user_id, lab_code, lab_name)
    )
    conn.commit()
    conn.close()



import os
import json
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
    cur.execute("SELECT lab_code FROM user_labs WHERE user_id = ? AND completed = 1", (user_id,))
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
