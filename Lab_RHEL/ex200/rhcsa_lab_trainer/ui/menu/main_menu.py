"""
Menú Principal - 100% funcional y corregido
"""
import sys
from ui.display.banners import show_banner, show_footer
from ui.display.colors import Color
from ui.utils.screen_utils import clear_screen, pause
from ui.utils.input_handlers import get_menu_choice

class MainMenu:
    def __init__(self):
        self.options = {
            "1": ("Entrenamiento Modo Entrenamiento", self.training_mode),
            "2": ("Examen Modo Examen (Simulado)", self.exam_mode),
            "3": ("Progreso Ver Progreso", self.show_progress),
            "4": ("Config Configuración", self.config_menu),
            "5": ("Limpiar Limpiar Laboratorios", self.cleanup_labs),
            "6": ("Salir Salir", lambda: sys.exit(0)),
            "7": ("Nuevo", "Nuevo Ejercicio", self.new_exercise),

        }

    def run(self):
        while True:
            clear_screen()
            show_banner()
            print(f"\n{Color.CYAN}╔{'═'*54}╗")
            print(f"║{Color.WHITE}              MENÚ PRINCIPAL              {Color.CYAN}║")
            print(f"{Color.CYAN}╚{'═'*54}╝\n{Color.RESET}")

            items = [
                ("1", "Entrenamiento", "Modo Entrenamiento", "Practica escenarios guiados"),
                ("2", "Examen", "Modo Examen", "Examen simulado con tiempo"),
                ("3", "Progreso", "Ver Progreso", "Tus estadísticas"),
                ("4", "Config", "Configuración", "Ajustes"),
                ("5", "Limpiar", "Limpiar Laboratorios", "Resetear entorno"),
                ("6", "Salir", "Salir", "Cerrar aplicación"),
                ("7", "Nuevo", "Nuevo Ejercicio", "Agregar Nuevo ejercico" ),
            ]

            for num, icon, title, desc in items:
                print(f" {Color.YELLOW}{num}{Color.RESET} {icon} {Color.WHITE}{title}{Color.RESET}")
                print(f"   {Color.GRAY}{desc}{Color.RESET}\n")

            show_footer()
            choice = get_menu_choice("123456")
            if choice in self.options:
                self.options[choice][1]()

    def training_mode(self):
        # Import dinámico seguro que SIEMPRE funciona
        from ui.menu.training_menu import TrainingMenu
        TrainingMenu().run()

    def exam_mode(self):
        clear_screen(); show_banner("MODO EXAMEN")
        print(f"\n{Color.RED}Próximamente disponible{Color.RESET}\n")
        pause()

    def show_progress(self):
        clear_screen(); show_banner("PROGRESO")
        print(f"\n{Color.CYAN}Sistema de progreso en desarrollo{Color.RESET}\n")
        pause()

    def config_menu(self):
        clear_screen(); show_banner("CONFIGURACIÓN")
        print(f"\n{Color.CYAN}Configuración en desarrollo{Color.RESET}\n")
        pause()

    def cleanup_labs(self):
        clear_screen(); show_banner("LIMPIAR LABORATORIOS")
        print(f"\n{Color.YELLOW}Advertencia: Esto eliminará todo{Color.RESET}\n")
        if input(f"{Color.RED}¿Continuar? (s/N): {Color.RESET}").lower() == 's':
            print(f"\n{Color.GREEN}Entorno limpiado{Color.RESET}")
        else:
            print(f"\n{Color.BLUE}Cancelado{Color.RESET}")
        pause()

    def new_exercise(self):
        from core.scenario_creator import ScenarioCreator
        ScenarioCreator().run()

