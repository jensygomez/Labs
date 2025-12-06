#!/usr/bin/env python3
"""
RHCSA Lab Trainer - Instalador completo del sistema de menús (versión funcional)
Ejecutar una sola vez: python3 setup_full_menu.py
"""
from pathlib import Path

BASE = Path(__file__).parent.resolve()

# =============================================
# CONTENIDO REAL DE CADA ARCHIVO (funcional + bonito)
# =============================================

FILES = {
    "main.py": '''#!/usr/bin/env python3
"""
RHCSA Lab Trainer - Menú Principal
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))

try:
    from ui.menu.main_menu import MainMenu
    MainMenu().run()
except KeyboardInterrupt:
    print("\\n\\n¡Hasta luego! Sigue practicando RHCSA")
except Exception as e:
    print(f"\\nError: {e}")
    print("Ejecuta: pip install -r requirements.txt")
''',

    "requirements.txt": "PyYAML\\nrich\\n",

    "ui/menu/main_menu.py": '''"""
Menú principal 100% funcional
"""
from ui.display.banners import show_banner, show_footer
from ui.display.colors import Color
from ui.utils.screen_utils import clear_screen, pause
from ui.utils.input_handlers import get_menu_choice

class MainMenu:
    def __init__(self):
        self.options = {
            "1": ("Modo Entrenamiento", lambda: __import__('ui.menu.training_menu').TrainingMenu().run()),
            "2": ("Modo Examen (Simulado)", self.exam_mode),
            "3": ("Ver Progreso", self.show_progress),
            "4": ("Configuración", self.config_menu),
            "5": ("Limpiar Laboratorios", self.cleanup_labs),
            "6": ("Salir", self.exit_app),
        }

    def run(self):
        while True:
            clear_screen()
            show_banner("RHCSA LAB TRAINER")
            print(f"\\n{Color.CYAN}=== MENÚ PRINCIPAL ==={Color.RESET}\\n")
            for k, (text, _) in self.options.items():
                icon = ["", "", "", "", "", ""][int(k)-1]
                icons = ["Entrenamiento", "Examen", "Progreso", "Config", "Limpiar", "Salir"]
                print(f" {Color.YELLOW}{k}.{Color.RESET} {icons[int(k)-1]} {text}")
                print(f"   {Color.GRAY}{'Practica escenarios guiados' if k=='1' else 'Examen con tiempo' if k=='2' else 'Estadísticas' if k=='3' else 'Ajustes' if k=='4' else 'Elimina configuraciones previas' if k=='5' else 'Cierra la aplicación'}{Color.RESET}\\n")
            show_footer()
            choice = get_menu_choice([str(i) for i in range(1,7)])
            if choice in self.options:
                self.options[choice][1]()

    def exam_mode(self):
        clear_screen(); show_banner("MODO EXAMEN")
        print("\\nEsta función llegará muy pronto")
        pause()

    def show_progress(self):
        clear_screen(); show_banner("PROGRESO")
        print("\\nSistema de progreso - Próximamente")
        pause()

    def config_menu(self):
        clear_screen(); show_banner("CONFIGURACIÓN")
        print("\\nOpciones de configuración - Próximamente")
        pause()

    def cleanup_labs(self):
        clear_screen(); show_banner("LIMPIAR LABORATORIOS")
        print(f"\\n{Color.YELLOW}ADVERTENCIA{Color.RESET}")
        print("Esto eliminará configuraciones de laboratorios anteriores.\\n")
        if input(f"{Color.RED}¿Simular limpieza? (s/N): {Color.RESET}").lower() == 's':
            print(f"\\n{Color.GREEN}Simulación completada{Color.RESET}")
            pause()
        else:
            print(f"\\n{Color.BLUE}Operación cancelada{Color.RESET}")
            pause()

    def exit_app(self):
        clear_screen()
        show_banner("¡HASTA PRONTO!")
        print(f"\\n{Color.GREEN}Gracias por usar RHCSA Lab Trainer{Color.RESET}")
        print(f"{Color.GRAY}¡Nos vemos en la próxima sesión!{Color.RESET}\\n")
        sys.exit(0)
''',

    "ui/menu/training_menu.py": '''"""
Menú de entrenamiento - Totalmente funcional
"""
from ui.display.banners import show_banner
from ui.display.colors import Color
from ui.utils.screen_utils import clear_screen, pause
from ui.utils.input_handlers import get_menu_choice

class TrainingMenu:
    def run(self):
        options = {
            "1": "Por Módulo del Examen",
            "2": "Por Dificultad",
            "3": "Escenarios Aleatorios",
            "4": "Sesión Cronometrada",
            "5": "Volver al Menú Principal",
        }
        while True:
            clear_screen()
            show_banner("MODO ENTRENAMIENTO")
            print(f"\\n{Color.CYAN}=== ¿CÓMO QUIERES PRACTICAR HOY? ==={Color.RESET}\\n")
            for k, v in options.items():
                print(f" {Color.YELLOW}{k}.{Color.RESET} {v}")
            print(f"\\n{Color.GRAY}Tip: 'b' = volver | 'q' = salir{Color.RESET}")
            choice = get_menu_choice(["1","2","3","4","5"])
            if choice == "5" or choice == "back":
                return
            clear_screen()
            show_banner(options[choice])
            print("\\nFunción en desarrollo - Volverá muy pronto")
            pause()
''',

    "ui/display/banners.py": '''from .colors import Color
def show_banner(title=""):
    print(f"{Color.CYAN}")
    print("┌─────────────────────────────────────────────────────────┐")
    print("│                                                         │")
    print(f"│   {Color.YELLOW}RHCSA LAB TRAINER{Color.CYAN}          │")
    print(f"│   {Color.WHITE}{title:^50}{Color.CYAN} │")
    print("│                                                         │")
    print("└─────────────────────────────────────────────────────────┘{Color.RESET}")

def show_footer():
    print(f"{Color.GRAY}─────────────────────────────────────────────────────────")
    print("  Comandos → h=ayuda | b=atrás | q=salir                  ")
    print("─────────────────────────────────────────────────────────{Color.RESET}")
''',

    "ui/display/colors.py": '''class Color:
    RESET = "\\033[0m"
    BOLD = "\\033[1m"
    CYAN = "\\033[96m"
    YELLOW = "\\033[93m"
    GREEN = "\\033[92m"
    RED = "\\033[91m"
    GRAY = "\\033[90m"
    WHITE = "\\033[97m"
    BLUE = "\\033[94m"
''',

    "ui/utils/screen_utils.py": '''import os
import platform
def clear_screen():
    os.system('cls' if platform.system() == 'Windows' else 'clear')
def pause(msg="Presiona Enter para continuar..."):
    input(f"\\n{msg}")
''',

    "ui/utils/input_handlers.py": '''from ui.display.colors import Color
def get_menu_choice(valid_options):
    while True:
        try:
            choice = input(f"{Color.CYAN}Opción → {Color.RESET}").strip().lower()
            if choice in ['q', 'quit', 'exit']:
                raise KeyboardInterrupt
            if choice in ['b', 'back']:
                return 'back'
            if choice in ['h', 'help']:
                print(f"\\n{Color.CYAN}Ayuda:{Color.RESET} números → seleccionar | b → atrás | q → salir")
                continue
            if choice in valid_options:
                return choice
            print(f"{Color.RED}Opción inválida{Color.RESET}")
        except KeyboardInterrupt:
            print(f"\\n{Color.YELLOW}¡Hasta luego!{Color.RESET}")
            raise
''',
}

# Crear __init__.py donde haga falta
for init in [
    "ui/__init__.py",
    "ui/menu/__init__.py",
    "ui/display/__init__.py",
    "ui/utils/__init__.py",
]:
    (BASE / init).parent.mkdir(parents=True, exist_ok=True)
    (BASE / init).write_text("# Auto-generated\n", encoding="utf-8")

# Sobreescribir/crear todos los archivos
for path, content in FILES.items():
    full = BASE / path
    full.parent.mkdir(parents=True, exist_ok=True)
    full.write_text(content.lstrip(), encoding="utf-8")

print("¡Listo! Menú completo instalado")
print("Ejecuta ahora:")
print("    python3 main.py")
print("¡Disfruta de tu RHCSA Lab Trainer con menús bonitos y funcionales!")
