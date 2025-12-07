#!/usr/bin/env python3
"""
UniversalEngine RHCSA - Motor definitivo para TODOS los niveles
Lee levels dinámicos del YAML • Pre_setup automático • Escenarios aleatorios
"""
import yaml
import re
from pathlib import Path
from random import choice, randint
from datetime import datetime
from subprocess import check_output, CalledProcessError
from core.database_manager import DatabaseManager
from ui.display.colors import Color
from ui.utils.screen_utils import clear_screen, pause
from ui.utils.input_handlers import get_menu_choice

class UniversalEngine:
    def __init__(self, exercise_id):
        self.id = exercise_id
        self.level = None
        self.load_exercise()

    def load_exercise(self):
        """Carga YAML desde DB y valida estructura levels"""
        db = DatabaseManager()
        c = db.cursor
        c.execute("SELECT path FROM scenarios WHERE id = ?", (self.id,))
        row = c.fetchone()
        db.close()
        
        if not row:
            raise ValueError(f"❌ Ejercicio '{self.id}' no encontrado en DB")
        
        yaml_path = Path(row[0])
        if not yaml_path.exists():
            raise ValueError(f"❌ Archivo YAML no encontrado: {yaml_path}")
            
        with open(yaml_path, "r", encoding="utf-8") as f:
            self.exercise = yaml.safe_load(f)
        
        # Validar estructura levels
        if "levels" not in self.exercise:
            raise ValueError("❌ YAML sin estructura 'levels'")

    def select_level(self):
        """Selecciona nivel interactivamente"""
        clear_screen()
        print(f"{Color.CYAN}🚀 {self.exercise['name']} — Elige dificultad{Color.RESET}")
        print(f"{Color.YELLOW}📊 Total reps requeridas: {self.exercise['repetitions_required']}{Color.RESET}\n")
        
        levels = ["basic", "intermediate", "advanced"]
        level_names = ["🔵 Básico", "🟡 Intermedio", "🔴 Avanzado"]
        
        for i, lvl in enumerate(levels):
            level_data = self.exercise["levels"][lvl]
            reps = level_data["repetitions"]
            print(f"   {i+1}. {level_names[i]} ({reps} reps, {level_data['points_per_rep']}pts/rep)")
        
        choice = get_menu_choice(["1", "2", "3"])
        self.level = levels[int(choice)-1]
        print(f"{Color.GREEN}✓ Nivel {level_names[int(choice)-1]} seleccionado{Color.RESET}")

    def generate(self):
        """Genera tarea aleatoria del nivel seleccionado"""
        level_data = self.exercise["levels"][self.level]
        allowed_scenarios = level_data.get("allowed_scenarios", list(range(len(self.exercise["scenarios"]))))
        
        # Escenario aleatorio del nivel
        scenario_idx = choice(allowed_scenarios)
        template = self.exercise["scenarios"][scenario_idx]
        
        # Sustituir variables {{var}}
        placeholders = re.findall(r"{{([^}]+)}}", template)
        values = {}
        missing = []
        
        for var in placeholders:
            var = var.strip()
            if var in self.exercise["globals"] and self.exercise["globals"][var]:
                values[var] = choice(self.exercise["globals"][var])
            else:
                missing.append(var)
                values[var] = f"❓{var}❓"
        
        # Texto final
        task = template
        for var, val in values.items():
            task = task.replace(f"{{{{{var}}}}}", str(val))
        
        if missing:
            print(f"{Color.YELLOW}⚠️ Variables faltantes: {', '.join(missing)}{Color.RESET}")
        
        return task, values, level_data

    def execute_pre_setup(self, values):
        """Ejecuta pre_setup del nivel (intermedio/avanzado)"""
        level_data = self.exercise["levels"][self.level]
        pre_setup = level_data.get("pre_setup", [])
        
        if not pre_setup:
            return
            
        print(f"{Color.CYAN}🔧 Ejecutando pre_setup ({len(pre_setup)} comandos)...{Color.RESET}")
        for i, cmd_tmpl in enumerate(pre_setup, 1):
            cmd = cmd_tmpl
            for var, val in values.items():
                cmd = cmd.replace(f"{{{{{var}}}}}", str(val))
            
            try:
                print(f"   {i}. {Color.GREEN}{cmd}{Color.RESET}")
                check_output(cmd, shell=True, executable="/bin/bash", timeout=10)
                print(f"   {Color.GREEN}✓{Color.RESET}")
            except CalledProcessError as e:
                print(f"   {Color.YELLOW}⚠️ (continúa: {e.returncode}){Color.RESET}")
            except Exception:
                print(f"   {Color.RED}✗ (ignorado){Color.RESET}")

    def run(self):
        """Ejecuta entrenamiento completo"""
        self.select_level()
        clear_screen()
        
        print(f"{Color.CYAN}🎯 ENTRENAMIENTO RHCSA{Color.RESET}")
        print(f"{Color.YELLOW}📋 {self.exercise['name']}{Color.RESET}")
        print(f"{Color.BLUE}📂 Nivel: {self.level.title()} | Reps: {self.exercise['levels'][self.level]['repetitions']}{Color.RESET}\n")
        
        start = datetime.now()
        task, values, level_data = self.generate()
        
        print(f"{Color.CYAN}📝 TAREA ALEATORIA:{Color.RESET}")
        print(f"{Color.WHITE}{task}{Color.RESET}\n")
        
        # Pre_setup
        self.execute_pre_setup(values)
        print()
        
        # Tiempo de ejecución
        input(f"{Color.GREEN}⏱️ Ejecuta y presiona Enter → {Color.RESET}")
        elapsed = (datetime.now() - start).total_seconds()
        
        # Guardar progreso
        db = DatabaseManager()
        c = db.conn.cursor()
        c.execute("""
            INSERT INTO progress (scenario_id, completed_at, time_seconds, attempts, score)
            VALUES (?, datetime('now'), ?, 1, ?)
        """, (self.id, elapsed, level_data["points_per_rep"]))
        db.conn.commit()
        db.close()
        
        print(f"\n{Color.GREEN}✅ Completado!")
        print(f"   ⏱️ Tiempo: {elapsed:.1f}s")
        print(f"   ⭐ Puntos: {level_data['points_per_rep']}pts")
        pause("\nEnter para continuar...")

# Prueba interactiva
if __name__ == "__main__":
    clear_screen()
    print(f"{Color.CYAN}🧪 MODO PRUEBA UniversalEngine{Color.RESET}")
    engine = UniversalEngine("users-001")
    engine.run()
