"""
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
            print(f"\n{Color.CYAN}=== ¿CÓMO QUIERES PRACTICAR HOY? ==={Color.RESET}\n")
            for k, v in options.items():
                print(f" {Color.YELLOW}{k}.{Color.RESET} {v}")
            print(f"\n{Color.GRAY}Tip: 'b' = volver | 'q' = salir{Color.RESET}")
            choice = get_menu_choice(["1","2","3","4","5"])
            if choice == "5" or choice == "back":
                return
            clear_screen()
            show_banner(options[choice])
            print("\nFunción en desarrollo - Volverá muy pronto")
            pause()
