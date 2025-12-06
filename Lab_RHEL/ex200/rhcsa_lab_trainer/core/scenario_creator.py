#!/usr/bin/env python3
"""
Creador Interactivo de Escenarios YAML + DB
"""
import yaml
from pathlib import Path
from datetime import datetime
from ui.display.banners import show_banner
from ui.display.colors import Color
from ui.utils.screen_utils import clear_screen, pause
from ui.utils.input_handlers import get_menu_choice
from core.database_manager import DatabaseManager

MODULES = {
    "1": "01_essential_tools",
    "2": "02_running_systems", 
    "3": "03_local_storage",
    "4": "04_file_systems",
    "5": "05_deploy_systems",
    "6": "06_networking"
}

DIFFICULTY_MAP = {"1": 1, "2": 2, "3": 3}

class ScenarioCreator:
    def run(self):
        while True:
            clear_screen()
            show_banner("🆕 NUEVO EJERCICIO")
            print(f"{Color.CYAN}📝 Crea tu ejercicio RHCSA en 30 segundos{Color.RESET}\n")

            # 1. SELECCIONAR MÓDULO
            print(f"{Color.YELLOW}1. MÓDULO:{Color.RESET}")
            for k, v in MODULES.items():
                print(f"   {Color.CYAN}{k}{Color.RESET} → {v.replace('_', ' ').title()}")
            
            module_choice = get_menu_choice("123456")
            module_dir = MODULES[module_choice]
            module_name = module_dir.replace('_', ' ').title()

            # 2. GENERAR ID AUTOMÁTICO
            scenario_id = self.get_next_id(module_dir)
            
            # 3. DATOS BÁSICOS
            print()
            name = input(f"{Color.CYAN}📛 Nombre del ejercicio: {Color.RESET}").strip()
            if not name:
                pause("❌ Nombre requerido"); continue

            difficulty = self.get_difficulty()
            repetitions = self.get_repetitions()
            points = self.get_points()

            # 4. RESUMEN Y CONFIRMAR
            print(f"\n{Color.GREEN}📋 RESUMEN:{Color.RESET}")
            print(f"   🆔 ID: {scenario_id}")
            print(f"   📛 Nombre: {name}")
            print(f"   📂 Módulo: {module_name}")
            print(f"   📊 Dificultad: {difficulty}")
            print(f"   🔄 Repeticiones: {repetitions}")
            print(f"   ⭐ Puntos: {points}")

            if input(f"\n{Color.YELLOW}¿Crear ejercicio? (s/N): {Color.RESET}").lower() == 's':
                self.create_scenario(scenario_id, name, module_dir, module_name, difficulty, repetitions, points)
                pause(f"{Color.GREEN}✅ ¡Ejercicio creado exitosamente!{Color.RESET}")
                break

    def get_next_id(self, module_dir):
        """001, 002, 003..."""
        path = Path(f"scenarios/{module_dir}")
        existing = list(path.glob("*.yaml"))
        count = len(existing) + 1
        return f"{count:03d}"

    def get_difficulty(self):
        """Selecciona dificultad"""
        print(f"\n{Color.YELLOW}📊 DIFICULTAD:{Color.RESET}")
        print("1 → Básico")
        print("2 → Intermedio")
        print("3 → Avanzado")
        choice = get_menu_choice("123")
        return {1: "Básico", 2: "Intermedio", 3: "Avanzado"}[int(choice)]

    def get_repetitions(self):
        """Repeticiones requeridas"""
        while True:
            try:
                reps = input(f"{Color.CYAN}🔄 Repeticiones [1-10]: {Color.RESET}").strip()
                return int(reps) if reps else 3
            except ValueError:
                print(f"{Color.RED}Número entre 1-10{Color.RESET}")

    def get_points(self):
        """Puntos del ejercicio"""
        while True:
            try:
                pts = input(f"{Color.CYAN}⭐ Puntos [5-50]: {Color.RESET}").strip()
                return int(pts) if pts else 15
            except ValueError:
                print(f"{Color.RED}Número entre 5-50{Color.RESET}")

    def create_scenario(self, scenario_id, name, module_dir, module_name, difficulty_text, repetitions, points):
        """Crea YAML + DB"""
        # 1. Crear estructura
        path = Path(f"scenarios/{module_dir}")
        path.mkdir(parents=True, exist_ok=True)
        
        # 2. Crear YAML
        yaml_data = {
            "id": scenario_id,
            "name": name,
            "module": module_name,
            "difficulty": difficulty_text.lower(),
            "points": points,
            "repetitions_required": repetitions,
            "description": f"Ejercicio RHCSA {module_name} - {name}",
            "tasks": [
                "# PASO 1: Comando 1",
                "# PASO 2: Comando 2", 
                "# PASO 3: Comando 3"
            ]
        }
        
        yaml_path = path / f"{scenario_id}.yaml"
        with open(yaml_path, 'w', encoding='utf-8') as f:
            yaml.dump(yaml_data, f, allow_unicode=True, default_flow_style=False)
        
        # 3. Guardar en DB
        try:
            db = DatabaseManager()
            cursor = db.conn.cursor()
            difficulty_num = {"Básico": 1, "Intermedio": 2, "Avanzado": 3}[difficulty_text]
            
            cursor.execute('''
                INSERT OR REPLACE INTO scenarios 
                (id, name, module, difficulty, points, description, repetitions_required)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (scenario_id, name, module_name, difficulty_num, points, 
                  yaml_data["description"], repetitions))
            db.conn.commit()
            db.conn.close()
            
            print(f"{Color.GREEN}📄 YAML creado: {yaml_path.absolute()}{Color.RESET}")
            print(f"{Color.GREEN}🗄️  Guardado en base de datos{Color.RESET}")
        except Exception as e:
            print(f"{Color.RED}❌ Error DB: {e}{Color.RESET}")

if __name__ == "__main__":
    ScenarioCreator().run()