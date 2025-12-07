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
        """Menú interactivo de niveles con 'b' para volver"""
        while True:
            clear_screen()
            print(f"{Color.CYAN}🚀 {self.exercise['name']} — Elige dificultad{Color.RESET}")
            print(f"{Color.YELLOW}📊 Total reps: {self.exercise['repetitions_required']}{Color.RESET}\n")
            print(f"{Color.RED}b{Color.RESET} → Volver al menú de entrenamiento")
            print()
            
            levels = ["basic", "intermediate", "advanced"]
            level_names = ["🔵 Básico", "🟡 Intermedio", "🔴 Avanzado"]
            
            for i, lvl in enumerate(levels, 1):
                level_data = self.exercise["levels"][lvl]
                print(f"   {i}. {level_names[i-1]} ({level_data['repetitions']} reps, {level_data['points_per_rep']}pts)")
            
            choice = input(f"{Color.CYAN}Opción → {Color.RESET}").strip().lower()

            if choice in ("b", "back"):
                print(f"{Color.YELLOW}Volviendo al menú de entrenamiento...{Color.RESET}")
                pause()
                return None  # ← Indica cancelar
            
            try:
                choice_num = int(choice)
                if 1 <= choice_num <= 3:
                    self.level = levels[choice_num-1]
                    print(f"{Color.GREEN}✓ Nivel {level_names[choice_num-1]} seleccionado{Color.RESET}")
                    pause()
                    return self.level
            except:
                pause(f"{Color.RED}Opción inválida{Color.RESET}")


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
        """Flujo completo con VALIDACIÓN AUTOMÁTICA"""
        self.select_level()  
        
        clear_screen()
        print(f"{Color.CYAN}🎯 ENTRENAMIENTO: {self.exercise['name']}{Color.RESET}")
        print(f"{Color.YELLOW}📂 Nivel: {self.level.title()} | Reps: {self.exercise['levels'][self.level]['repetitions']}{Color.RESET}\n")

        start = datetime.now()
        task, values = self.generate()  # ← RECIBE values también

        print(f"{Color.YELLOW}Tarea:{Color.RESET} {task}\n")
        input(f"{Color.GREEN}Realiza la tarea y pulsa Enter cuando termines →{Color.RESET}")

        elapsed = (datetime.now() - start).total_seconds()
        
        # 🔥 VALIDACIÓN REAL (reemplaza puntos fijos)
        score = self.validate(values)  # ← ¡LO NUEVO!

        # Guardar progreso
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







# =====================================================
# VALIDACION
# =====================================================

    def validate(self, values):
        level = self.exercise["levels"][self.level]
        validation_cmds = level.get("validation", [])
        
        if not validation_cmds:
            return 100  # Sin validación = 100pts
        
        score = 100
        print(f"{Color.CYAN}🔍 Validando...{Color.RESET}")
        
        for i, cmd_tmpl in enumerate(validation_cmds, 1):
            cmd = cmd_tmpl
            for var, val in values.items():
                cmd = cmd.replace(f"{{{{{var}}}}}", str(val))
            
            try:
                result = check_output(cmd, shell=True, executable="/bin/bash", timeout=5)
                print(f"   {i}. {Color.GREEN}✓ {cmd}{Color.RESET}")
            except:
                print(f"   {i}. {Color.RED}✗ {cmd}{Color.RESET}")
                score -= 20  # -20pts por fallo
        
        return max(0, score)
 

# Prueba
if __name__ == "__main__":
    UniversalEngine("users-001").run()
