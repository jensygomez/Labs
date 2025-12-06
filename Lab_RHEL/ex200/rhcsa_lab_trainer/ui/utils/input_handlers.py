from ui.display.colors import Color
def get_menu_choice(valid_options):
    while True:
        try:
            choice = input(f"{Color.CYAN}Opción → {Color.RESET}").strip().lower()
            if choice in ['q', 'quit', 'exit']:
                raise KeyboardInterrupt
            if choice in ['b', 'back']:
                return 'back'
            if choice in ['h', 'help']:
                print(f"\n{Color.CYAN}Ayuda:{Color.RESET} números → seleccionar | b → atrás | q → salir")
                continue
            if choice in valid_options:
                return choice
            print(f"{Color.RED}Opción inválida{Color.RESET}")
        except KeyboardInterrupt:
            print(f"\n{Color.YELLOW}¡Hasta luego!{Color.RESET}")
            raise
