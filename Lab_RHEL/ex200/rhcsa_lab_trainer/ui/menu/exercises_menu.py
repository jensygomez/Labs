# Lab_RHEL/ex200/rhcsa_lab_trainer/ui/menu/exercises_menu.py
#!/usr/bin/env python3
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
            print(f"{Color.RED}b{Color.RESET} → Volver\n")

            choice = get_menu_choice(["1", "2", "b"])

            if choice == "b":
                return
            elif choice == "1":
                self.new_exercise_full()
            elif choice == "2":
                self.list_exercises()

    def new_exercise_full(self):
        """1️⃣ Elige módulo → 2️⃣ Abre nano → 3️⃣ Auto-import DB"""
        # 1. LISTA MÓDULOS RHCSA
        modules = {
            "1": ("01_essential_tools", "Essential Tools"),
            "2": ("02_running_systems", "Running Systems"), 
            "3": ("03_local_storage", "Local Storage"),
            "4": ("04_file_systems", "File Systems"),
            "5": ("05_deploy_systems", "Deploy Systems"),
            "6": ("06_networking", "Networking")
        }
        
        clear_screen()
        print(f"{Color.CYAN}📂 Elige módulo RHCSA:{Color.RESET}")
        for num, (path, name) in modules.items():
            print(f" {num}. {name}")
        
        mod_choice = get_menu_choice(list(modules.keys()))
        module_path, module_name = modules[mod_choice]
        
        # 2. NOMBRE ARCHIVO
        exercise_id = input(f"{Color.YELLOW}{module_name} → ID (ej: lvm-001) → {Color.RESET}").strip()
        if not exercise_id:
            pause("ID requerido")
            return
            
        yaml_path = Path(f"scenarios/{module_path}/{exercise_id}.yaml")
        
        # 3. CREAR CARPETA + ABRIR NANO
        yaml_path.parent.mkdir(parents=True, exist_ok=True)
        print(f"{Color.GREEN}✅ {yaml_path} creado{Color.RESET}")
        
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
