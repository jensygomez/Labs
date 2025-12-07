# Lab_RHEL/ex200/rhcsa_lab_trainer/ui/menu/training_menu.py
#!/usr/bin/env python3

from ui.display.banners import show_banner
from ui.display.colors import Color
from ui.utils.screen_utils import clear_screen, pause
from ui.utils.input_handlers import get_menu_choice
from core.database_manager import DatabaseManager
from pathlib import Path

class ExercisesMenu:
    def run(self):
        while True:
            clear_screen()
            show_banner("GESTIÓN DE EJERCICIOS RHCSA")
            
            print(f"{Color.CYAN}1.{Color.RESET} Crear nuevo → scenarios/MODULO/id.yaml")
            print(f"{Color.CYAN}2.{Color.RESET} Importar YAML → Auto DB")
            print(f"{Color.CYAN}3.{Color.RESET} Editar existente")
            print(f"{Color.RED}4.{Color.RESET} Eliminar")
            print(f"{Color.RED}b{Color.RESET} → Volver al menú principal\n")

            choice = get_menu_choice(["1", "2", "3", "4"])

            if choice == "b":
                return
            
            if choice == "1":
                self.create_new()
            elif choice == "2":
                self.import_yaml()
            elif choice == "3":
                self.edit_existing()
            elif choice == "4":
                self.delete_exercise()

    def create_new(self):
        """Crea estructura nueva YAML"""
        clear_screen()
        print(f"{Color.CYAN}📁 Estructura nueva:{Color.RESET}")
        print(f"   Ejemplo: scenarios/02_storage/lvm-001.yaml")
        path = input(f"{Color.YELLOW}Ruta completa → {Color.RESET}").strip()
        
        full_path = Path(path)
        full_path.parent.mkdir(parents=True, exist_ok=True)
        
        print(f"{Color.GREEN}✅ Carpeta creada: {full_path.parent}{Color.RESET}")
        print(f"{Color.YELLOW}Copia/pega YAML completo en: {full_path}{Color.RESET}")
        pause()

    def import_yaml(self):
        """IMPORTA YAML → DB (FASE 2)"""
        clear_screen()
        print(f"{Color.CYAN}📥 Importar YAML → DB{Color.RESET}")
        yaml_path = input(f"{Color.YELLOW}Ruta al archivo YAML → {Color.RESET}").strip()
        
        db = DatabaseManager()
        success = db.import_yaml_scenario(yaml_path)
        db.close()
        
        if success:
            print(f"{Color.GREEN}🎉 Listo! Aparece en Entrenamiento automáticamente{Color.RESET}")
        pause()

    def edit_existing(self):
        """Lista ejercicios para editar"""
        db = DatabaseManager()
        c = db.cursor
        c.execute("SELECT id, name, path FROM scenarios WHERE type = 'dynamic'")
        exercises = c.fetchall()
        db.close()
        
        if not exercises:
            print(f"{Color.YELLOW}No hay ejercicios aún{Color.RESET}")
            pause()
            return
            
        for i, (sid, name, path) in enumerate(exercises):
            print(f"{i+1}. {sid} - {name} → {path}")
        
        choice = input(f"{Color.CYAN}Editar (número) → {Color.RESET}")
        pause(f"{Color.YELLOW}nano {exercises[int(choice)-1][2]}{Color.RESET}")

    def delete_exercise(self):
        """Elimina ejercicio"""
        print(f"{Color.YELLOW}Función pendiente{Color.RESET}")
        pause()

