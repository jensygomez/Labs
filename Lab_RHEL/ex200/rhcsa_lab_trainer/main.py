#!/usr/bin/env python3
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
    print("\n\n¡Hasta luego! Sigue practicando RHCSA")
except Exception as e:
    print(f"\nError: {e}")
    print("Ejecuta: pip install -r requirements.txt")
