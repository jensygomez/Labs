#!/usr/bin/env python3
"""
RHCSA Lab Trainer - Script de creación de estructura inicial
Solo crea carpetas y archivos básicos (placeholders)
Ejecutar: python create_structure.py
"""
import os
from pathlib import Path

BASE = Path("rhcsa_lab_trainer")

# =============================================
# ESTRUCTURA DE DIRECTORIOS
# =============================================
DIRS = [
    ".",
    
    # UI
    "ui",
    "ui/menu",
    "ui/display",
    "ui/navigation",
    "ui/utils",
    
    # Core
    "core",
    
    # Futuros módulos
    "scenarios",
    "scenarios/01_essential_tools",
    "scenarios/02_running_systems",
    "scenarios/03_local_storage",
    "scenarios/04_file_systems",
    "scenarios/05_deploy_systems",
    "scenarios/06_networking",
    
    "data",
    "data/database",
    "logs",
    "modules",
    "tests",
    
    "config",
]

# =============================================
# ARCHIVOS CON CONTENIDO MÍNIMO
# =============================================
FILES = {
    # Raíz
    "main.py": '#!/usr/bin/env python3\nfrom ui.menu.main_menu import MainMenu\n\nif __name__ == "__main__":\n    MainMenu().run()\n',
    "requirements.txt": "# rich\n# pyyaml\n# questionary\n",
    "README.md": "# RHCSA Lab Trainer\nEntrenador interactivo para el examen RHCSA (EX200)\n",
    ".gitignore": "__pycache__/\n*.pyc\nconfig/\ndata/\nlogs/\n",
    
    # UI - Menús (solo estructura)
    "ui/__init__.py": '# UI Package\n',
    "ui/menu/__init__.py": '# Menús\n',
    "ui/menu/main_menu.py": '"""\nMenú Principal\n"""\nclass MainMenu:\n    def run(self):\n        print("Menú Principal - Próximamente")\n        input("Enter para continuar...")\n',
    "ui/menu/training_menu.py": '"""\nMenú de Entrenamiento\n"""\nclass TrainingMenu:\n    def run(self):\n        print("Modo Entrenamiento")\n        input("Enter para volver...")\n',

    # UI - Módulos de apoyo
    "ui/display/__init__.py": '# Display utilities\n',
    "ui/display/banners.py": 'def show_banner(title=""):\n    print(f"=== {title} ===\\n")\n',
    "ui/display/colors.py": 'class Color:\n    RESET = ""\n    CYAN = ""\n    YELLOW = ""\n    GREEN = ""\n',

    "ui/utils/__init__.py": '# Utils\n',
    "ui/utils/screen_utils.py": 'import os\ndef clear_screen():\n    os.system("cls" if os.name == "nt" else "clear")\n',
    "ui/utils/input_handlers.py": 'def get_choice(options):\n    return input("Opción: ")\n',

    "ui/navigation/__init__.py": '# Navigation\n',
    "ui/navigation/menu_navigator.py": 'class MenuNavigator:\n    def __init__(self):\n        self.history = []\n',

    # Core
    "core/__init__.py": '# Core\n',
    "core/scenario_loader.py": 'class ScenarioLoader:\n    @staticmethod\n    def list_all():\n        return []\n',
    "core/config_manager.py": 'class Config:\n    def get(self, key):\n        return None\n',

    # Config
    "config/settings.json": '{}\n',
}

print("RHCSA Lab Trainer - Creando estructura de proyecto...\n")

# Crear directorios
for d in DIRS:
    path = BASE / d
    path.mkdir(parents=True, exist_ok=True)
    if d != ".":
        print(f"Created folder: {path}")

# Crear archivos
for filepath, content in FILES.items():
    fullpath = BASE / filepath
    fullpath.parent.mkdir(parents=True, exist_ok=True)
    
    if not fullpath.exists():
        fullpath.write_text(content, encoding="utf-8")
        print(f"Created file: {fullpath}")
    else:
        print(f"Already exists: {fullpath}")

print("\n¡Estructura creada con éxito!")
print(f"\nCarpeta base: {BASE.resolve()}")
print("\nPara iniciar:")
print("   cd rhcsa_lab_trainer")
print("   python main.py")
print("\n¡Listo para desarrollar!")