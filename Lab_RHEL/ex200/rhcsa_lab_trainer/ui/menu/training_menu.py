# Lab_RHEL/ex200/rhcsa_lab_trainer/ui/menu/training_menu.py
#!/usr/bin/env python3
from ui.display.banners import show_banner
from ui.display.colors import Color
from ui.utils.screen_utils import clear_screen, pause
from ui.utils.input_handlers import get_menu_choice
from core.scenario_engine import UniversalEngine
from core.database_manager import DatabaseManager

class TrainingMenu:
    def run(self):
        while True:
            clear_screen()
            show_banner("MODO ENTRENAMIENTO")
            print(f"{Color.CYAN}Elige el laboratorio que quieres practicar:\n{Color.RESET}")

            # ⭐ NUEVA QUERY: labs por módulo (jerarquía RHCSA)
            db = DatabaseManager()
            labs = db.get_labs_by_module()  # Nueva función
            db.close()

            if not labs:
                print(f"{Color.YELLOW}No hay laboratorios aún.{Color.RESET}")
                print(f"{Color.CYAN}Ve a 'Gestión de Ejercicios' → Importa YAML.{Color.RESET}")
                pause()
                return

            # Header mejorado
            print(f"{Color.CYAN}{'':<3} {'ID':<12} {'TÍTULO':<35} {'DIFICULTAD':<10} {'PTS':<5} {'PROGRESO':<12}{Color.RESET}")
            print(f"{Color.CYAN}{'─'*3} {'─'*12} {'─'*35} {'─'*10} {'─'*5} {'─'*12}{Color.RESET}")

            lab_list = []
            for i, (lab_id, title, difficulty, points, reps_done, reps_total) in enumerate(labs, 1):
                # Progreso Anki-style
                progress = f"{reps_done}/{reps_total}"
                if reps_done == reps_total:
                    status = f"{Color.GREEN}✓ MAESTRO{Color.RESET}"
                elif reps_done > 0:
                    pct = (reps_done / reps_total) * 100
                    status = f"{Color.YELLOW}{pct:.0f}%{Color.RESET}"
                else:
                    status = f"{Color.RED}🔴 Nuevo{Color.RESET}"
                
                diff_str = f"D{difficulty}"
                print(f" {Color.YELLOW}{i:<2}{Color.RESET}  {lab_id:<12} {title[:34]:<35} {diff_str:<10} {points:<5} {progress:<12} {status}")
                lab_list.append(lab_id)

            print(f"\n{Color.GREEN}s{Color.RESET} → Sugerirme el más débil (Anki)")
            print(f"{Color.RED}b{Color.RESET} → Volver al menú principal\n")

            choice = input(f"{Color.CYAN}Opción → {Color.RESET}").strip().lower()

            if choice in ("b", "back"):
                return

            selected_lab = None
            if choice == "s":
                # ⭐ ANKI: Más débil (next_review vencido)
                db = DatabaseManager()
                weak_lab = db.get_weakest_lab()  # Nueva función
                db.close()
                if weak_lab:
                    selected_lab = weak_lab[0]
                    print(f"\n{Color.GREEN}💡 Sugerido (Anki): {selected_lab} – Necesita repaso{Color.RESET}")
                else:
                    selected_lab = lab_list[0]
            else:
                try:
                    idx = int(choice) - 1
                    if 0 <= idx < len(lab_list):
                        selected_lab = lab_list[idx]
                    else:
                        raise ValueError
                except:
                    pause(f"{Color.RED}Opción inválida{Color.RESET}")
                    continue

            # Lanzar engine con NUEVO lab_id
            try:
                engine = UniversalEngine(selected_lab)  # Cambia scenario_id → lab_id
                engine.run()
            except Exception as e:
                pause(f"{Color.RED}Error al cargar lab {selected_lab}: {e}{Color.RESET}")
