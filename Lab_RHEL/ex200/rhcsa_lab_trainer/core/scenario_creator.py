#!/usr/bin/env python3
"""
Creador Interactivo de Escenarios YAML + DB
"""
from ui.display.banners import show_banner
from ui.display.colors import Color
from ui.utils.screen_utils import clear_screen, pause
from ui.utils.input_handlers import get_menu_choice
from core.database_manager import DatabaseManager
import yaml
from pathlib import Path
from datetime import datetime

MODULES = {
    "1": "01_essential_tools",
    "2": "02_running_systems", 
    "3": "03_local_storage",
    "4": "04_file_systems",
    "5": "05_deploy_systems",
    "6": "06_networking"
}

class ScenarioCreator:
    def run(self):
        while True:
            clear_screen()
            show_banner("NUEVO EJERCICIO")
            
            print(f"{Color.CYAN}📝 Crea tu ejercicio RHCSA en 30 segundos{Color.RESET}")
            print()
            
            # 1. MÓDULO
            print(f"{Color.YELLOW}1. MÓDULO:{Color.RESET}")
            for k, v in MODULES.items():
                print(f"   {k} → {v.replace('_', ' ').title()}")
            
            module = get_menu_choice("123456")
            module_dir = MODULES[module]
            
            # 2. ID (automático)
            scenario_id = self.get_next_id(module_dir)
            
            # 3. DATOS BÁSICOS
            name = input(f"{Color.CYAN}Nombre del ejercicio: {Color.RESET}").strip()
            difficulty = self.get_difficulty()
            repetitions = int(input(f"{Color.CYAN}Repeticiones requeridas [1-10]: {Color.RESET}") or 3)
            points = int(input(f"{Color.CYAN}Puntos [5-50]: {Color.RESET}") or 15)
            
            # 4. CONFIRMACIÓN
            print(f"\n{Color.GREEN}📋 RESUMEN:{Color.RESET}")
            print(f"   ID: {scenario_id}")
            print(f"   Nombre: {name}")
            print(f"   Módulo: {module_dir.replace('_', ' ').title()}")
            print(f"   Dificultad: {difficulty}")
            print(f"   Repeticiones: {repetitions}")
            print(f"   Puntos: {points}")
            
            if input(f"\n{Color.YELLOW}¿Crear? (s/N): {Color.RESET}").lower() == 's':
                self.create_scenario(scenario_id, name, module_dir, difficulty, repetitions, points)
                pause("✅ ¡Ejercicio creado!")
                return
            else:
                pause("❌ Cancelado")

    def get_next_id(self, module_dir):
        """Genera ID secuencial: 001, 002..."""
        path = Path(f"scenarios/{module_dir}")
        count = len(list(path.glob("[0-9][0-9][0-9]-*.yaml"))) + 1
        return f"{count:03d}-{module_dir.split('_')[1]}".upper()

    def get_difficulty(self):
        """Selecciona dificultad"""
        clear_screen()
        print(f"{Color.YELLOW}Dificultad:{Color.RESET}")
        print("1 → Básico")
        print("2 → Intermedio") 
        print("3 → Avanzado")
        return {"1": "Básico", "2": "Intermedio", "3": "Avanzado"}[get_menu_choice("123")]

    def create_scenario(self, scenario_id, name, module_dir, difficulty, repetitions, points):
        """Crea YAML + guarda en DB"""
        # 1. Crear estructura
        path = Path(f"scenarios/{module_dir}")
        path.mkdir(parents=True, exist_ok=True)
        
        # 2. YAML básico
        yaml_data = {
            "id": scenario_id,
            "name": name,
            "module": module_dir.replace('_', ' ').title(),
            "difficulty": difficulty.lower(),
            "points": points,
            "repetitions_required": repetitions,
            "description": f"Ejercicio RHCSA - {name}",
            "tasks": ["# Agrega aquí los comandos paso a paso"]
        }
        
        yaml_path = path / f"{scenario_id}.yaml"
        with open(yaml_path, 'w', encoding='utf-8') as f:
            yaml.dump(yaml_data, f, allow_unicode=True, default_flow_style=False)
        
        # 3. Guardar en DB
        db = DatabaseManager()
        cursor = db.conn.cursor()
        cursor.execute('''
            INSERT OR REPLACE INTO scenarios 
            (id, name, module, difficulty, points, description, repetitions_required)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', (scenario_id, name, module_dir.replace('_', ' ').title(), 
              {"Básico":1, "Intermedio":2, "Avanzado":3}[difficulty],
              points, yaml_data["description"], repetitions))
        db.conn.commit()
        db.conn.close()
        
        print(f"📄 YAML: {yaml_path.absolute()}")
