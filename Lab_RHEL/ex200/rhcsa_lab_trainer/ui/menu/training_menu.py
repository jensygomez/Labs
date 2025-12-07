# Lab_RHEL/ex200/rhcsa_lab_trainer/ui/menu/training_menu.py
#!/usr/bin/env python3
from ui.display.banners import show_banner
from ui.display.colors import Color
from ui.utils.screen_utils import clear_screen, pause
from core.scenario_engine import ScenarioEngine
from core.database_manager import DatabaseManager

class TrainingMenu:
    def run(self):
        while True:
            clear_screen()
            show_banner("MODO ENTRENAMIENTO")
            print(f"{Color.CYAN}Elige el ejercicio que quieres practicar:\n{Color.RESET}")

            # Cargar ejercicios desde la base de datos
            db = DatabaseManager()
            c = db.cursor
            c.execute("""
                SELECT s.id, s.name, s.module,
                       COUNT(p.id) as intentos,
                       ROUND(AVG(p.score),1) as promedio
                FROM scenarios s
                LEFT JOIN progress p ON s.id = p.scenario_id
                WHERE s.type = 'dynamic'
                GROUP BY s.id
                ORDER BY s.module, promedio ASC NULLS FIRST, s.id
            """)
            exercises = c.fetchall()
            db.close()

            if not exercises:
                print(f"{Color.YELLOW}No hay ejercicios dinámicos aún.{Color.RESET}")
                print(f"{Color.CYAN}Ve a 'Gestión de Ejercicios' y crea uno primero.{Color.RESET}")
                pause()
                return

            # Mostrar lista bonita
            print(f"{Color.CYAN}{'':<3} {'ID':<12} {'NOMBRE':<35} {'MÓDULO':<18} {'INTENTOS':<8} {'PROMEDIO':<8}{Color.RESET}")
            print(f"{Color.CYAN}{'─'*3} {'─'*12} {'─'*35} {'─'*18} {'─'*8} {'─'*8}{Color.RESET}")

            for i, (sid, name, module, attempts, avg_score) in enumerate(exercises, 1):
                mod_clean = module.replace("_", " ").replace("_", " ").title()
                score_str = f"{avg_score or 0:.1f}%" if avg_score else "-"
                print(f" {Color.YELLOW}{i:<2}{Color.RESET}  {sid:<12} {name:<35.34} {mod_clean:<18} {attempts:<8} {score_str:<8}")

            print(f"\n{Color.GREEN}s{Color.RESET} → Sugerirme el ejercicio más débil")
            print(f"{Color.RED}b{Color.RESET} → Volver al menú principal\n")

            choice = input(f"{Color.CYAN}Opción → {Color.RESET}").strip().lower()

            if choice in ("b", "back", ""):
                return

            selected_id = None

            if choice == "s":
                # Sugiere el que tenga peor promedio (o el primero si todos son nuevos)
                selected_id = exercises[0][0]
                print(f"\n{Color.GREEN}Te sugiero practicar: {selected_id} – {exercises[0][1]}{Color.RESET}")
                print(f"{Color.YELLOW}Es el que peor promedio tienes (o el más nuevo){Color.RESET}")
                input("\nPulsa Enter para empezar...")

            else:
                try:
                    idx = int(choice) - 1
                    if 0 <= idx < len(exercises):
                        selected_id = exercises[idx][0]
                    else:
                        raise ValueError
                except:
                    pause(f"{Color.RED}Opción inválida{Color.RESET}")
                    continue

            # Lanzar el motor
            try:
                engine = ScenarioEngine(selected_id)
                engine.run_training()
            except Exception as e:
                pause(f"{Color.RED}Error al cargar el ejercicio: {e}{Color.RESET}")