import os

LABS_PATH = os.path.join(os.path.dirname(__file__), "../../labs")

def list_labs(level, specialization):
    labs_dir = os.path.join(LABS_PATH, level, specialization)
    if not os.path.exists(labs_dir):
        print("⚠️ No existen laboratorios en esa categoría.")
        return []

    labs = [d for d in os.listdir(labs_dir) if os.path.isdir(os.path.join(labs_dir, d))]
    return labs
