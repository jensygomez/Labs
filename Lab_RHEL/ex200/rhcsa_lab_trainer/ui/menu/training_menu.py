#!/usr/bin/env python3
from ui.display.banners import show_banner
from ui.display.colors import Color
from ui.utils.screen_utils import clear_screen, pause
from core.scenario_engine import UniversalEngine
from core.database_manager import DatabaseManager

class TrainingMenu:
    def run(self):
        while True:
            clear_screen()
            show_banner("MODO ENTRENAMIENTO")
            print(f"{Color.CYAN}Elige el ejercicio que quieres practicar:\n{Color.RESET}")

            # Cargar ejercicios DINÁMICOS con progreso por NIVEL
            db = DatabaseManager()
            c = db.cursor
            
            c.execute("""
                SELECT 
                    s.id, s.name, s.module, s.path,
                    s1.reps_req as basic_reps, COALESCE(s1.completed, 0) as basic_done,
                    s2.reps_req as inter_reps, COALESCE(s2.completed, 0) as inter_done,
                    s3.reps_req as adv_reps, COALESCE(s3.completed, 0) as adv_done
                FROM scenarios s
                LEFT JOIN (
                    SELECT scenario_id, repetitions_required as reps_req, 
                           COUNT(*) as completed
                    FROM progress p JOIN scenarios s ON p.scenario_id = s.id 
                    WHERE s.type = 'dynamic' AND s.difficulty = 1
                    GROUP BY scenario_id
                ) s1 ON s.id = s1.scenario_id
                LEFT JOIN (
                    SELECT scenario_id, repetitions_required as reps_req, 
                           COUNT(*) as completed
                    FROM progress p JOIN scenarios s ON p.scenario_id = s.id 
                    WHERE s.type = 'dynamic' AND s.difficulty = 2
                    GROUP BY scenario_id
                ) s2 ON s.id = s2.scenario_id
                LEFT JOIN (
                    SELECT scenario_id, repetitions_required as reps_req, 
                           COUNT(*) as completed
                    FROM progress p JOIN scenarios s ON p.scenario_id = s.id 
                    WHERE s.type = 'dynamic' AND s.difficulty = 3
                    GROUP BY scenario_id
                ) s3 ON s.id = s3.scenario_id
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

            # Header con columnas más anchas
            print(f"{Color.CYAN}{'':<3} {'ID':<12} {'NOMBRE':<32} {'MÓDULO':<16} {'BÁSICO':<8} {'INTER':<8} {'AVANZADO':<10}{Color.RESET}")
            print(f"{Color.CYAN}{'─'*3} {'─'*12} {'─'*32} {'─'*16} {'─'*8} {'─'*8} {'─'*10}{Color.RESET}")

            for i, row in enumerate(exercises, 1):
                sid, name, module, path, b_reps, b_done, i_reps, i_done, a_reps, a_done = row
                
                # Progreso por nivel con colores
                b_prog = f"{Color.GREEN}{b_done}/{b_reps}{Color.RESET}" if b_reps else "-"
                i_prog = f"{Color.YELLOW}{i_done}/{i_reps}{Color.RESET}" if i_reps else "-"
                a_prog = f"{Color.RED}{a_done}/{a_reps}{Color.RESET}" if a_reps else "-"
                
                mod_clean = module.replace("_", " ").title()
                print(f" {Color.YELLOW}{i:<2}{Color.RESET}  {sid:<12} {name[:31]:<32} {mod_clean:<16} {b_prog:<8} {i_prog:<8} {a_prog:<10}")

            print(f"\n{Color.GREEN}s{Color.RESET} → Sugerirme el más urgente (más reps restantes)")
            print(f"{Color.RED}b{Color.RESET} → Volver al menú principal\n")

            choice = input(f"{Color.CYAN}Opción → {Color.RESET}").strip().lower()

            if choice in ("b", "back", ""):
                return

            selected_id = None

            if choice == "s":
                # Más urgente: suma reps restantes totales
                most_urgent = max(exercises, key=lambda x: 
                    (x[5] or 0) + (x[7] or 0) + (x[9] or 0)  # reps restantes
                )
                selected_id = most_urgent[0]
                print
