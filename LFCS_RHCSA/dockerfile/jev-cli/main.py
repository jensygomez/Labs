#!/usr/bin/env python3
"""
main.py - Router principal de jev-cli.
Muestra el menú y delega la ejecución a los módulos correspondientes.
"""
import sys
import os

# Asegurar que podemos importar los módulos locales
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from noul import run_noul
# from choice import run_choice  # Próximamente
# from score import run_score    # Próximamente

def main():
    print("\n" + "="*70)
    print(" 🤖 JEV-CLI: Interfaz Modular para TypeSafe System One")
    print("="*70)
    print(" 1. Noul  (Validación Sí/No con probabilidad)")
    print(" 2. Choice (Elegir la mejor opción entre varias) [Próximamente]")
    print(" 3. Score  (Evaluar nivel/escala de algo) [Próximamente]")
    print(" 0. Salir")
    print("="*70)
    
    choice = input("\nSelecciona el tipo de evaluación (0-3): ").strip()
    
    if choice == "1":
        run_noul()
    elif choice == "2":
        print("\n🚧 Módulo Choice en construcción. Próximamente.")
    elif choice == "3":
        print("\n🚧 Módulo Score en construcción. Próximamente.")
    elif choice == "0":
        print("👋 Saliendo de jev-cli. ¡Hasta pronto!")
        sys.exit(0)
    else:
        print("❌ Opción no válida. Inténtalo de nuevo.")
        sys.exit(1)

if __name__ == "__main__":
    main()
