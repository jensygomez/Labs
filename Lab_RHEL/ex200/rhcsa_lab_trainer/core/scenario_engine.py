#!/usr/bin/env python3

import yaml
import re
from pathlib import Path
from random import choice
from datetime import datetime
from subprocess import check_output
from core.database_manager import DatabaseManager
from ui.display.colors import Color
from ui.utils.screen_utils import clear_screen, pause

class UniversalEngine:
    def __init__(self, exercise_id):
        self.id = exercise_id
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

    def generate(self):
        level = self.exercise["levels"]["basic"]  # puedes cambiar a self.level después
        template = choice(self.exercise["scenarios"])

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

        # pre_setup (opcional)
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
        clear_screen()
        print(f"{Color.CYAN}ENTRENAMIENTO: {self.exercise['name']}{Color.RESET}\n")

        start = datetime.now()
        task, _ = self.generate()

        print(f"{Color.YELLOW}Tarea:{Color.RESET} {task}\n")
        input(f"{Color.GREEN}Realiza la tarea y pulsa Enter cuando termines →{Color.RESET}")

        elapsed = (datetime.now() - start).total_seconds()
        score = 100  # por ahora (validación futura por módulo)

        # Guardar progreso
        db = DatabaseManager()
        c = db.conn.cursor()
        c.execute(
            "INSERT INTO progress (scenario_id, completed_at, time_seconds, attempts, score) VALUES (?, datetime('now'), ?, 1, ?)",
            (self.id, elapsed, score)
        )
        db.conn.commit()
        db.close()

        print(f"\n{Color.GREEN}Tiempo: {elapsed:.1f}s{Color.RESET}")
        pause("\nEnter para continuar...")

# Prueba
if __name__ == "__main__":
    UniversalEngine("users-001").run()