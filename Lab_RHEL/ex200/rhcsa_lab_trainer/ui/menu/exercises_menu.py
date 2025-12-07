# Lab_RHEL/ex200/rhcsa_lab_trainer/ui/menu/exercises_menu.py
#!/usr/bin/env python3
"""
Gestión de Ejercicios RHCSA - YAML → DB Automático
"""
from ui.display.banners import show_banner
from ui.display.colors import Color
from ui.utils.screen_utils import clear_screen, pause
from ui.utils.input_handlers import get_menu_choice
from core.database_manager import DatabaseManager
from pathlib import Path
import subprocess
import os


class ExercisesMenu:
    def run(self):
        while True:
            clear_screen()
            show_banner("GESTIÓN DE EJERCICIOS RHCSA")
            
            print(f"{Color.CYAN}1.{Color.RESET} Nuevo ejercicio (elige módulo)")
            print(f"{Color.CYAN}2.{Color.RESET} Lista ejercicios")
            print(f"{Color.RED}b{Color.RESET} → Volver al menú principal")
            print()
            
            choice = input(f"{Color.CYAN}Opción → {Color.RESET}").strip().lower()

            if choice in ("b", "back"):
                return
            elif choice == "1":
                self.new_exercise_full()
            elif choice == "2":
                self.list_exercises()
            else:
                pause(f"{Color.RED}Opción inválida{Color.RESET}")

    def new_exercise_full(self):
        """1️⃣ Módulo → 2️⃣ ID auto → 3️⃣ nano → 4️⃣ DB"""
        # 1. LISTA MÓDULOS RHCSA
        modules = {
            "1": ("01_essential_tools", "Essential Tools"),
            "2": ("02_running_systems", "Running Systems"), 
            "3": ("03_local_storage", "Local Storage"),
            "4": ("04_file_systems", "File Systems"),
            "5": ("05_deploy_systems", "Deploy Systems"),
            "6": ("06_networking", "Networking")
        }
        
        while True:  # ← LOOP hasta elegir válido
            clear_screen()
            print(f"{Color.CYAN}📂 Elige módulo RHCSA:{Color.RESET}")
            print(f"{Color.RED}b{Color.RESET} → Volver")
            print()
            for num, (path, name) in modules.items():
                print(f" {num}. {name}")
            
            choice = input(f"{Color.CYAN}Opción → {Color.RESET}").strip().lower()

            if choice in ("b", "back"):
                return  # ← REGRESA a menú principal
            
            if choice in modules:
                module_path, module_name = modules[choice]
                break  # ← SALE del loop
            else:
                pause(f"{Color.RED}Opción inválida{Color.RESET}")
        
        # 🔥 2. ID AUTOMÁTICO (nuevo)
        db = DatabaseManager()
        c = db.cursor
        c.execute("SELECT COUNT(*) FROM scenarios WHERE module = ?", (module_path,))
        count = c.fetchone()[0] + 1
        exercise_id = f"{module_path.split('_')[-1][:3]}-{count:03d}"  # lvm-001
        db.close()
        
        print(f"{Color.YELLOW}{module_name} → {Color.GREEN}{exercise_id}{Color.RESET}")
        yaml_path = Path(f"scenarios/{module_path}/{exercise_id}.yaml")
        
        # 3. CREAR CARPETA + ABRIR NANO
        yaml_path.parent.mkdir(parents=True, exist_ok=True)
        print(f"{Color.GREEN}✅ {yaml_path} listo para editar{Color.RESET}")
        
        editor = os.getenv("EDITOR", "nano")
        subprocess.call([editor, str(yaml_path)])
        
        # 4. AUTO-IMPORT DB
        print(f"{Color.CYAN}📥 Importando a DB...{Color.RESET}")
        db = DatabaseManager()
        success = db.import_yaml_scenario(yaml_path)
        db.close()
        
        if success:
            print(f"{Color.GREEN}🎉 {exercise_id} listo en Entrenamiento!{Color.RESET}")
        pause()

    def list_exercises(self):
        """Lista todos los ejercicios"""
        db = DatabaseManager()
        c = db.cursor
        c.execute("SELECT id, name, module FROM scenarios WHERE type = 'dynamic' ORDER BY module, id")
        exercises = c.fetchall()
        db.close()
        
        if not exercises:
            print(f"{Color.YELLOW}No hay ejercicios{Color.RESET}")
            pause()
            return
            
        print(f"{Color.CYAN}{'ID':<12} {'NOMBRE':<35} {'MÓDULO'}{Color.RESET}")
        print(f"{Color.CYAN}{'-'*12} {'-'*35} {'-'*15}{Color.RESET}")
        for sid, name, module in exercises:
            print(f" {sid:<12} {name[:34]:<35} {module.replace('_', ' ').title()}")
        pause()
