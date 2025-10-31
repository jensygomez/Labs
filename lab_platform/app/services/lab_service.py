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


def mark_lab_completed(user_id, lab_name):
    """Marca un laboratorio como completado por el usuario"""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO user_labs (user_id, lab_name, completed) VALUES (?, ?, 1)",
        (user_id, lab_name)
    )
    conn.commit()
    conn.close()

