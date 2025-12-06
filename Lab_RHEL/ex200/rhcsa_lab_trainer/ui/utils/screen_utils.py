import os
import platform
def clear_screen():
    os.system('cls' if platform.system() == 'Windows' else 'clear')
def pause(msg="Presiona Enter para continuar..."):
    input(f"\n{msg}")
