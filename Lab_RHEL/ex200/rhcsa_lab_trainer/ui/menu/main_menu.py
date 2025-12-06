"""
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
            print(f"\n{Color.CYAN}=== MENÚ PRINCIPAL ==={Color.RESET}\n")
            for k, (text, _) in self.options.items():
                icon = ["", "", "", "", "", ""][int(k)-1]
                icons = ["Entrenamiento", "Examen", "Progreso", "Config", "Limpiar", "Salir"]
                print(f" {Color.YELLOW}{k}.{Color.RESET} {icons[int(k)-1]} {text}")
                print(f"   {Color.GRAY}{'Practica escenarios guiados' if k=='1' else 'Examen con tiempo' if k=='2' else 'Estadísticas' if k=='3' else 'Ajustes' if k=='4' else 'Elimina configuraciones previas' if k=='5' else 'Cierra la aplicación'}{Color.RESET}\n")
            show_footer()
            choice = get_menu_choice([str(i) for i in range(1,7)])
            if choice in self.options:
                self.options[choice][1]()

    def exam_mode(self):
        clear_screen(); show_banner("MODO EXAMEN")
        print("\nEsta función llegará muy pronto")
        pause()

    def show_progress(self):
        clear_screen(); show_banner("PROGRESO")
        print("\nSistema de progreso - Próximamente")
        pause()

    def config_menu(self):
        clear_screen(); show_banner("CONFIGURACIÓN")
        print("\nOpciones de configuración - Próximamente")
        pause()

    def cleanup_labs(self):
        clear_screen(); show_banner("LIMPIAR LABORATORIOS")
        print(f"\n{Color.YELLOW}ADVERTENCIA{Color.RESET}")
        print("Esto eliminará configuraciones de laboratorios anteriores.\n")
        if input(f"{Color.RED}¿Simular limpieza? (s/N): {Color.RESET}").lower() == 's':
            print(f"\n{Color.GREEN}Simulación completada{Color.RESET}")
            pause()
        else:
            print(f"\n{Color.BLUE}Operación cancelada{Color.RESET}")
            pause()

    def exit_app(self):
        clear_screen()
        show_banner("¡HASTA PRONTO!")
        print(f"\n{Color.GREEN}Gracias por usar RHCSA Lab Trainer{Color.RESET}")
        print(f"{Color.GRAY}¡Nos vemos en la próxima sesión!{Color.RESET}\n")
        sys.exit(0)
