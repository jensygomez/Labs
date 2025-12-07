#!/usr/bin/env python3
"""
Motor de escenarios RHCSA - Genera, valida y puntúa ejercicios dinámicos
"""
import yaml
from pathlib import Path
from random import choice, randint
from datetime import datetime
from subprocess import check_output, CalledProcessError
from core.database_manager import DatabaseManager
from ui.display.colors import Color
from ui.utils.screen_utils import clear_screen, pause

class ScenarioEngine:
    def __init__(self, exercise_id):
        self.id = exercise_id
        self.db = DatabaseManager()
        self.load_exercise()
        self.level = "basic"  # Empieza por básico, avanza según progreso

    def load_exercise(self):
        c = self.db.cursor
        c.execute("SELECT path FROM scenarios WHERE id = ?", (self.id,))
        path = c.fetchone()
        self.db.close()
        if not path:
            raise ValueError(f"Ejercicio {self.id} no encontrado")
        with open(path[0], 'r') as f:
            self.data = yaml.safe_load(f)

    def generate_scenario(self):
        level_data = self.data["levels"][self.level]
        scenario_text = choice(self.data["scenarios"])
        vars = {}
        for cat, items in self.data["globals"].items():
            vars[cat] = choice(items) if len(items) > 1 else items[0]

        # Reemplazar {{var}} en el texto
        task = scenario_text
        for k, v in vars.items():
            task = task.replace(f"{{{k}}}", v)

        # Ejecutar pre_setup si existe
        for cmd in level_data.get("pre_setup", []):
            cmd = cmd.format(**vars)  # reemplazar variables en pre_setup
            try:
                check_output(cmd, shell=True)
            except CalledProcessError as e:
                print(f"{Color.RED}Error en pre_setup: {e}{Color.RESET}")

        return task, vars

    def validate_solution(self, expected):
        # Validación básica - personalízala por módulo (ej: LVM = lvdisplay, users = id -u)
        # Ejemplo para LVM
        try:
            output = check_output("lvdisplay", shell=True).decode()
            if expected["lv"] in output:
                return 100
            else:
                return 0
        except:
            return 0

    def run_training(self):
        clear_screen()
        print(f"{Color.CYAN}ENTRENAMIENTO: {self.data['name']} - Nivel {self.level.upper()}{Color.RESET}\n")

        start_time = datetime.now()

        task, vars = self.generate_scenario()
        print(f"{Color.YELLOW}Tarea:{Color.RESET} {task}")
        input(f"\n{Color.GREEN}Ejecuta la tarea y pulsa Enter para validar...{Color.RESET}")

        score = self.validate_solution(vars)

        time_taken = (datetime.now() - start_time).total_seconds()

        # Guardar progreso en DB
        db = DatabaseManager()
        c = db.conn.cursor()
        c.execute("""
            INSERT INTO progress (scenario_id, completed_at, time_seconds, attempts, score)
            VALUES (?, datetime('now'), ?, 1, ?)
        """, (self.id, time_taken, score))
        db.conn.commit()
        db.close()

        print(f"\n{Color.GREEN}Puntuación: {score}/100{Color.RESET}")
        print(f"Tiempo: {time_taken:.1f} segundos")

        pause("Enter para siguiente repetición...")

    def suggest_next(self):
        # Sugiere basado en progreso bajo
        db = DatabaseManager()
        c = db.cursor
        c.execute("""
            SELECT s.id, AVG(p.score) as avg_score
            FROM scenarios s LEFT JOIN progress p ON s.id = p.scenario_id
            GROUP BY s.id
            ORDER BY avg_score ASC LIMIT 1
        """)
        next_id = c.fetchone()[0]
        db.close()
        return next_id

# Para probar rápido
if __name__ == "__main__":
    engine = ScenarioEngine("test-001")
    engine.run_training()