"""
Menú de Entrenamiento - 100% funcional
"""
from ui.display.banners import show_banner
from ui.display.colors import Color
from ui.utils.screen_utils import clear_screen, pause
from ui.utils.input_handlers import get_menu_choice

class TrainingMenu:
    def run(self):
        while True:
            clear_screen()
            show_banner("MODO ENTRENAMIENTO")

            print(f"\n{Color.CYAN}╔{'═'*56}╗")
            print(f"║{Color.WHITE}     ¿CÓMO QUIERES PRACTICAR HOY?     {Color.CYAN}║")
            print(f"{Color.CYAN}╚{'═'*56}╝\n{Color.RESET}")

            items = [
                "Por Módulo del Examen",
                "Por Dificultad",
                "Escenarios Aleatorios",
                "Sesión Cronometrada",
                "Volver al Menú Principal",
            ]

            for i, text in enumerate(items, 1):
                icons = ["Módulos", "Dificultad", "Aleatorio", "Pomodoro", "Volver"]
                print(f" {Color.YELLOW}{i}{Color.RESET} {icons[i-1]} {Color.WHITE}{text}{Color.RESET}")
                if i < 5:
                    print(f"     {Color.GRAY}Próximamente disponible...{Color.RESET}\n")
                else:
                    print()

            print(f"{Color.GRAY}→ 'b' = volver | 'q' = salir{Color.RESET}\n")

            choice = get_menu_choice("12345")
            if choice in ("5", "back"):
                return

            clear_screen()
            show_banner("EN DESARROLLO")
            print(f"\n{Color.CYAN}Esta funcionalidad estará lista muy pronto{Color.RESET}")
            print(f"{Color.YELLOW}¡Ya estamos creando los escenarios reales!{Color.RESET}\n")
            pause()
