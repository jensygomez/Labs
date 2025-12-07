#!/usr/bin/env python3
"""
UniversalEngine FINAL - Tu lógica PURA + 3 NIVELES dinámicos
NO inventa variables. Usa SOLO tus globals. Si falta → avisa.
"""
import yaml
import re
from pathlib import Path
from random import choice
from datetime import datetime
from subprocess import check_output
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
        db = DatabaseManager()
        c = db.cursor
        c.execute("SELECT path FROM scenarios WHERE id = ?", (self.id,))
        row = c.fetchone()
        db.close()
        if not row:
            raise ValueError(f"Ejercicio '{self.id}' no encontrado")
        with open(row[0], "r", encoding="utf-8") as f:
            self.exercise = yaml.safe_load(f)

    def select_level(self):
        """Menú interactivo de niveles"""
        clear_screen()
        print(f"{Color.CYAN}🚀 {self.exercise['name']} — Elige dificultad{Color.RESET}")
        print(f"{Color.YELLOW}📊 Total reps: {self.exercise['repetitions_required']}{Color.RESET}\n")
        
        levels = ["basic", "intermediate", "advanced"]
        for i, lvl in enumerate(levels, 1):
            level_data = self.exercise["levels"][lvl]
            print(f"   {i}. {lvl.title()} ({level_data['repetitions']} reps, {level_data['points_per_rep']}pts)")
        
        choice = get_menu_choice(["1", "2", "3"])
        self.level = levels[int(choice)-1]

    def generate(self):
        """TU LÓGICA ORIGINAL - SIN CAMBIOS"""
        level = self.exercise["levels"][self.level]  # ← CAMBIO: self.level
        
        # allowed_scenarios si existe, sino todos
        allowed = level.get("allowed_scenarios", list(range(len(self.exercise["scenarios"]))))
        template = choice([self.exercise["scenarios"][i] for i in allowed])

        # Extraer todas las variables {{...}}
        placeholders = re.findall(r"{{([^}]+)}}", template)
        values = {}

        missing = []
        for var in placeholders:
            var = var.strip()
            if var in self.exercise["globals"] and self.exercise["globals"][var]:
                values[var] = choice(self.exercise["globals"][var])
            else:
                missing.append(var)
                values[var] = f"???{var}???"

        # Texto final
        task = template
        for var, val in values.items():
            task = task.replace(f"{{{{{var}}}}}", str(val))

        # Avisar si faltó algo
        if missing:
            print(f"{Color.YELLOW}Advertencia: Variables no definidas en globals: {', '.join(missing)}{Color.RESET}")

        # pre_setup (opcional) - TU LÓGICA ORIGINAL
        for cmd_tmpl in level.get("pre_setup", []):
            cmd = cmd_tmpl
            for var, val in values.items():
                cmd = cmd.replace(f"{{{{{var}}}}}", str(val))
            try:
                check_output(cmd, shell=True, executable="/bin/bash")
            except:
                pass

        return task, values

    def run(self):
        """Flujo completo con selección de nivel"""
        self.select_level()  # ← NUEVO
        
        clear_screen()
        print(f"{Color.CYAN}🎯 ENTRENAMIENTO: {self.exercise['name']}{Color.RESET}")
        print(f"{Color.YELLOW}📂 Nivel: {self.level.title()} | Reps: {self.exercise['levels'][self.level]['repetitions']}{Color.RESET}\n")

        start = datetime.now()
        task, _ = self.generate()

        print(f"{Color.YELLOW}Tarea:{Color.RESET} {task}\n")
        input(f"{Color.GREEN}Realiza la tarea y pulsa Enter cuando termines →{Color.RESET}")

        elapsed = (datetime.now() - start).total_seconds()
        score = self.exercise["levels"][self.level]["points_per_rep"]  # ← Puntos por nivel

        # Guardar progreso - TU LÓGICA ORIGINAL
        db = DatabaseManager()
        c = db.conn.cursor()
        c.execute(
            "INSERT INTO progress (scenario_id, completed_at, time_seconds, attempts, score) VALUES (?, datetime('now'), ?, 1, ?)",
            (self.id, elapsed, score)
        )
        db.conn.commit()
        db.close()

        print(f"\n{Color.GREEN}Tiempo: {elapsed:.1f}s | ⭐ {score}pts{Color.RESET}")
        pause("\nEnter para continuar...")

# Prueba
if __name__ == "__main__":
    UniversalEngine("users-001").run()
