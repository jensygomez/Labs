#!/usr/bin/env python3
"""
Creador definitivo de ejercicios RHCSA — UN SOLO ARCHIVO YAML
Versión final • 100% profesional • Base de datos sincronizada
"""
import yaml
from pathlib import Path
from ui.display.colors import Color
from ui.utils.screen_utils import clear_screen, pause
from core.database_manager import DatabaseManager

# Módulos del examen RHCSA
MODULES = {
    "1": ("01_essential_tools", "Essential Tools"),
    "2": ("02_running_systems", "Running Systems"),
    "3": ("03_local_storage", "Local Storage"),
    "4": ("04_file_systems", "File Systems"),
    "5": ("05_deploy_systems", "Deploy Systems"),
    "6": ("06_networking", "Networking"),
}

def create_dynamic_exercise():
    """Crea un ejercicio dinámico con UN SOLO archivo YAML perfecto"""
    clear_screen()
    print(f"{Color.CYAN}CREADOR DE EJERCICIOS DINÁMICOS — VERSIÓN FINAL{Color.RESET}")
    print(f"{Color.YELLOW}        Un archivo • Variaciones infinitas • Todo sincronizado{Color.RESET}\n")

    # 1. Seleccionar módulo
    print("Módulos RHCSA:")
    for k, (_, name) in MODULES.items():
        print(f"   {Color.CYAN}{k}{Color.RESET} → {name}")
    while True:
        mod_key = input(f"\n{Color.CYAN}Elige módulo (1-6) → {Color.RESET}").strip()
        if mod_key in MODULES:
            break
        print(f"{Color.RED}Opción inválida{Color.RESET}")
    module_path, module_name = MODULES[mod_key]

    # 2. Nombre y código
    name = input(f"\n{Color.CYAN}Nombre del ejercicio → {Color.RESET}").strip()
    if not name:
        pause("Nombre obligatorio")
        return

    code = input(f"{Color.CYAN}Código corto (ej: users-001, lvm-001) → {Color.RESET}").strip()
    if not code:
        pause("Código obligatorio")
        return

    yaml_path = Path("scenarios") / module_path / f"{code}.yaml"
    yaml_path.parent.mkdir(parents=True, exist_ok=True)

    if yaml_path.exists():
        if input(f"{Color.YELLOW}{code}.yaml ya existe. ¿Sobrescribir? (s/N) → {Color.RESET}").lower() != 's':
            pause("Operación cancelada")
            return

    # 3. Construir globals
    print(f"\n{Color.YELLOW}Construyendo 'globals' – añade todas las categorías que quieras{Color.RESET}")
    globals_data = {}
    while True:
        if input(f"\n¿Añadir categoría? (s/n) → ").strip().lower() != 's':
            break
        cat = input("   Nombre categoría → ").strip()
        if not cat:
            continue
        print("   Elementos (línea vacía = terminar):")
        items = []
        while True:
            item = input("   > ").strip()
            if not item:
                break
            items.append(item)
        if items:
            globals_data[cat] = items

    # 4. Escenarios textuales
    print(f"\n{Color.YELLOW}Escenarios (usa {{nombre_var}} para variables):{Color.RESET}")
    scenarios = []
    while True:
        s = input("   Escenario (vacío = terminar) → ").strip()
        if not s:
            break
        scenarios.append(s)

    if not scenarios:
        scenarios = ["Realiza la configuración requerida para {{var}}"]

    # 5. Estructura final del ejercicio (el YAML definitivo)
    exercise = {
        "id": code,
        "name": name,
        "module": module_name,
        "type": "dynamic",
        "description": f"Ejercicio dinámico RHCSA: {name}",
        "points": 150,
        "repetitions_required": 18,
        "globals": globals_data,
        "scenarios": scenarios,
        "levels": {
            "basic": {
                "repetitions": 4,
                "points_per_rep": 25,
                "pre_setup": [],
                "allowed_scenarios": list(range(len(scenarios)))
            },
            "intermediate": {
                "repetitions": 6,
                "points_per_rep": 35,
                "pre_setup": []
            },
            "advanced": {
                "repetitions": 8,
                "points_per_rep": 45,
                "pre_setup": []
            }
        }
    }

    # 6. Guardar archivo YAML
    with open(yaml_path, 'w', encoding='utf-8') as f:
        yaml.safe_dump(exercise, f, allow_unicode=True, sort_keys=False, width=1000)

    # 7. Registrar en base de datos
    try:
        db = DatabaseManager()
        c = db.conn.cursor()
        c.execute("""
            INSERT OR REPLACE INTO scenarios
            (id, name, module, difficulty, points, description, repetitions_required, type, path)
            VALUES (?, ?, ?, ?, ?, ?, ?, 'dynamic', ?)
        """, (code, name, module_name, 2, 150, exercise["description"], 18, str(yaml_path)))
        db.conn.commit()
        db.close()
    except Exception as e:
        print(f"{Color.YELLOW}Advertencia: No se pudo guardar en DB ({e}){Color.RESET}")

    print(f"\n{Color.GREEN}EJERCICIO CREADO PERFECTAMENTE{Color.RESET}")
    print(f"   Archivo → {yaml_path}")
    print(f"   Total repeticiones → 18 (4+6+8)")
    pause("Pulsa Enter para volver...")

# Esto es lo que se llama desde el menú
if __name__ == "__main__":
    create_dynamic_exercise()