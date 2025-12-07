# Lab_RHEL/ex200/rhcsa_lab_trainer/ui/menu/training_menu.py
#!/usr/bin/env python3
from ui.display.banners import show_banner
from ui.display.colors import Color
from ui.utils.screen_utils import clear_screen, pause
from ui.utils.input_handlers import get_menu_choice
from core.scenario_engine import UniversalEngine  # ← FALTABA
from core.database_manager import DatabaseManager


class TrainingMenu:  # ← CAMBIAR DE ExercisesMenu → TrainingMenu
    def run(self):
        while True:
            clear_screen()
            show_banner("MODO ENTRENAMIENTO")
            print(f"{Color.CYAN}Elige el ejercicio que quieres practicar:\n{Color.RESET}")

            # Consulta ejercicios dinámicos
            db = DatabaseManager()
            c = db.cursor
            c.execute("""
                SELECT DISTINCT s.id, s.name, s.module
                FROM scenarios s 
                WHERE s.type = 'dynamic'
                ORDER BY s.module, s.id
            """)
            exercises = c.fetchall()
            db.close()

            if not exercises:
                print(f"{Color.YELLOW}No hay ejercicios dinámicos aún.{Color.RESET}")
                print(f"{Color.CYAN}Ve a 'Gestión de Ejercicios' y crea uno primero.{Color.RESET}")
                pause()
                return

            # Header
            print(f"{Color.CYAN}{'':<3} {'ID':<12} {'NOMBRE':<35} {'MÓDULO':<18} {'PROGRESO':<20}{Color.RESET}")
            print(f"{Color.CYAN}{'─'*3} {'─'*12} {'─'*35} {'─'*18} {'─'*20}{Color.RESET}")

            exercise_list = []
            for i, (sid, name, module) in enumerate(exercises, 1):
                # Progreso
                db = DatabaseManager()
                c = db.cursor
                c.execute("SELECT COUNT(*), AVG(score) FROM progress WHERE scenario_id = ?", (sid,))
                stats = c.fetchone()
                db.close()
                
                attempts, avg_score = stats if stats and stats[0] > 0 else (0, 0)
                prog_str = f"{attempts} intentos | {avg_score:.0f}%" if attempts else "Nuevo"
                
                mod_clean = module.replace("_", " ").title()
                print(f" {Color.YELLOW}{i:<2}{Color.RESET}  {sid:<12} {name[:34]:<35} {mod_clean:<18} {prog_str:<20}")
                exercise_list.append((sid, name))

            print(f"\n{Color.GREEN}s{Color.RESET} → Sugerirme el más débil")
            print(f"{Color.RED}b{Color.RESET} → Volver al menú principal\n")

            choice = input(f"{Color.CYAN}Opción → {Color.RESET}").strip().lower()

            if choice in ("b", "back"):
                return

            selected_id = None
            if choice == "s":
                selected_id = exercise_list[0][0]
                print(f"\n{Color.GREEN}Te sugiero: {selected_id} – {exercise_list[0][1]}{Color.RESET}")
                pause("Pulsa Enter para empezar...")
            else:
                try:
                    idx = int(choice) - 1
                    if 0 <= idx < len(exercise_list):
                        selected_id = exercise_list[idx][0]
                    else:
                        raise ValueError
                except:
                    pause(f"{Color.RED}Opción inválida{Color.RESET}")
                    continue

            # Lanzar UniversalEngine
            try:
                engine = UniversalEngine(selected_id)
                engine.run()
            except Exception as e:
                pause(f"{Color.RED}Error al cargar: {e}{Color.RESET}")
