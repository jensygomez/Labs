import sys
from ui.display.banners import show_banner, show_footer
from ui.display.colors import Color
from ui.utils.screen_utils import clear_screen, pause
from ui.utils.input_handlers import get_menu_choice

class MainMenu:
    def __init__(self):
        self.options = {
            "1": self.training_mode,
            "2": self.exam_mode,
            "3": self.show_progress,
            "4": self.config_menu,
            "5": self.cleanup_labs,
            "6": self.new_exercise,
            "7": lambda: sys.exit(0),  
        }

    def run(self):
        while True:
            clear_screen()
            show_banner()
            print(f"\n{Color.CYAN}╔{'═'*54}╗")
            print(f"║{Color.WHITE}              MENÚ PRINCIPAL              {Color.CYAN}║")
            print(f"{Color.CYAN}╚{'═'*54}╝\n{Color.RESET}")

            items = [
                ("1", "Entrenamiento", "Modo Entrenamiento", "Practica escenarios guiados"),
                ("2", "Examen", "Modo Examen", "Examen simulado con tiempo"),
                ("3", "Progreso", "Ver Progreso", "Tus estadísticas"),
                ("4", "Config", "Configuración", "Ajustes"),
                ("5", "Limpiar", "Limpiar Laboratorios", "Resetear entorno"),
                ("6", "Base de Datos", "Gestión de Ejercicios RHCSA", "Crear • Editar • Eliminar ejercicios"),
                ("7", "Salir", "Salir", "Cerrar aplicación"),
            ]

            for num, icon, title, desc in items:
                print(f" {Color.YELLOW}{num}{Color.RESET} {icon} {Color.WHITE}{title}{Color.RESET}")
                print(f"   {Color.GRAY}{desc}{Color.RESET}\n")

            show_footer()
            choice = get_menu_choice("1234567")
            if choice in self.options:
                self.options[choice]()

    def training_mode(self):
        from ui.menu.training_menu import TrainingMenu
        TrainingMenu().run()

    def exam_mode(self):
        clear_screen(); show_banner("MODO EXAMEN")
        print(f"\n{Color.RED}Próximamente disponible{Color.RESET}\n")
        pause()

    def config_menu(self):
        clear_screen(); show_banner("CONFIGURACIÓN")
        print(f"\n{Color.CYAN}Configuración en desarrollo{Color.RESET}\n")
        pause()

    def cleanup_labs(self):
        clear_screen(); show_banner("LIMPIAR LABORATORIOS")
        print(f"\n{Color.YELLOW}Advertencia: Esto eliminará todo{Color.RESET}\n")
        if input(f"{Color.RED}¿Continuar? (s/N): {Color.RESET}").lower() == 's':
            print(f"\n{Color.GREEN}Entorno limpiado{Color.RESET}")
        else:
            print(f"\n{Color.BLUE}Cancelado{Color.RESET}")
        pause()



    def new_exercise(self):
        import os
        import subprocess
        from pathlib import Path
        from core.database_manager import DatabaseManager

        while True:
            clear_screen()
            show_banner("GESTIÓN DE EJERCICIOS RHCSA")
            print(f"{Color.CYAN}Base de datos de ejercicios dinámicos:\n{Color.RESET}")

            # Cargar y mostrar tabla bonita
            db = DatabaseManager()
            c = db.cursor
            c.execute("""
                SELECT id, name, module, points, repetitions_required 
                FROM scenarios 
                WHERE type = 'dynamic' OR type IS NULL
                ORDER BY module, id
            """)
            exercises = c.fetchall()
            db.close()

            if not exercises:
                print(f"{Color.YELLOW}Aún no hay ejercicios creados.{Color.RESET}\n")
            else:
                # Cabecera
                print(f"{Color.CYAN}{'ID':<12} {'NOMBRE':<35} {'MÓDULO':<20} {'PUNTOS':<8} {'REPS':<6}{Color.RESET}")
                print(f"{Color.CYAN}{'─'*12} {'─'*35} {'─'*20} {'─'*8} {'─'*6}{Color.RESET}")
                for sid, name, module, points, reps in exercises:
                    mod_name = module.replace("_", " ").title()
                    print(f" {Color.YELLOW}{sid:<11}{Color.RESET} {name:<35.34} {mod_name:<20} {points:<8} {reps:<6}")
                print()

            # Menú de acciones
            print(f"{Color.CYAN}Opciones disponibles:{Color.RESET}")
            print(f" {Color.GREEN}1{Color.RESET} → Crear nuevo ejercicio dinámico")
            print(f" {Color.GREEN}2{Color.RESET} → Editar ejercicio existente (por ID)")
            print(f" {Color.GREEN}3{Color.RESET} → Eliminar ejercicio (por ID)")
            print(f" {Color.RED}b{Color.RESET} → Volver al menú principal\n")

            choice = input(f"{Color.CYAN}Opción → {Color.RESET}").strip().lower()

            if choice in ("b", "back", "7"):
                break

            elif choice == "1":
                from core.scenario_creator import create_dynamic_exercise
                create_dynamic_exercise()
                continue

            elif choice in ("2", "3"):
                eid = input(f"\n{Color.CYAN}Escribe el ID del ejercicio → {Color.RESET}").strip()
                if not eid:
                    pause("ID requerido")
                    continue

                # Buscar en DB
                db = DatabaseManager()
                c = db.cursor
                c.execute("SELECT path FROM scenarios WHERE id = ?", (eid,))
                row = c.fetchone()
                db.close()

                if not row or not row[0]:
                    pause(f"{Color.RED}Ejercicio con ID '{eid}' no encontrado{Color.RESET}")
                    continue

                file_path = Path(row[0])

                if choice == "2":  # EDITAR
                    if file_path.exists():
                        editor = os.getenv("EDITOR", "nano")
                        print(f"\n{Color.CYAN}Abriendo {file_path} con {editor}...{Color.RESET}")
                        subprocess.call([editor, str(file_path)])
                        input(f"\n{Color.GREEN}Archivo editado – pulsa Enter{Color.RESET}")
                    else:
                        pause(f"{Color.RED}Archivo no encontrado en disco{Color.RESET}")

                elif choice == "3":  # ELIMINAR
                    confirm = input(f"{Color.RED}¿Eliminar '{eid}' permanentemente? (escribir 'borrar') → {Color.RESET}")
                    if confirm == "borrar":
                        if file_path.exists():
                            file_path.unlink()
                        db = DatabaseManager()
                        db.cursor.execute("DELETE FROM scenarios WHERE id = ?", (eid,))
                        db.conn.commit()
                        db.close()
                        print(f"{Color.GREEN}Ejercicio {eid} eliminado de disco y base de datos{Color.RESET}")
                        input("Pulsa Enter...")
                    else:
                        print(f"{Color.BLUE}Operación cancelada{Color.RESET}")
                        input("Enter...")

            else:
                print(f"{Color.RED}Opción no válida{Color.RESET}")
                pause()




        
       

    def show_progress(self):
        from core.database_manager import DatabaseManager
        import time
        from datetime import datetime
        
        clear_screen()
        show_banner("📊 PROGRESO")
        
        db = DatabaseManager()
        cursor = db.cursor
        
        # 1. RESUMEN GENERAL
        cursor.execute("""
            SELECT COUNT(DISTINCT s.id), COUNT(DISTINCT s.module),
                COALESCE(SUM(CASE WHEN p.score>=80 THEN 1 ELSE 0 END), 0),
                COALESCE(SUM(s.repetitions_required), 0),
                ROUND(COALESCE(AVG(p.score), 0), 0),
                COALESCE(SUM(p.time_seconds), 0)
            FROM scenarios s LEFT JOIN progress p ON s.id = p.scenario_id
        """)
        total_ex, total_mod, comp, req, avg_score, total_time = cursor.fetchone() or (0,0,0,0,0,0)
        
        progress_pct = int((comp / max(req, 1)) * 100)
        bar_global = "█" * (progress_pct // 10) + "░" * (10 - progress_pct // 10)
        time_str = self.format_time(total_time)
        
        print(f"{Color.CYAN}{'═'*78}{Color.RESET}")
        print(f"{Color.YELLOW}{'📊 RESUMEN GENERAL':<28}{'│':'<1}{'📊 POR DIFICULTAD':<25}{Color.RESET}")
        
        print(f" Ejercicios: {total_ex}/{total_mod} módulos{' ':<12}│", end="")
        
        # DIFICULTAD con repeticiones TOTALES
        cursor.execute("""
            SELECT s.difficulty,
                SUM(s.repetitions_required),
                COUNT(CASE WHEN p.score>=80 THEN 1 ELSE 0 END)
            FROM scenarios s LEFT JOIN progress p ON s.id = p.scenario_id 
            GROUP BY s.difficulty
        """)
        diffs_data = cursor.fetchall()
        
        diff_names = {1: "Básico", 2: "Intermedio", 3: "Avanzado"}
        for diff_num in [1, 2, 3]:
            row = next((r for r in diffs_data if r[0] == diff_num), (diff_num, 0, 0))
            total_rep, comp_rep = row[1], row[2]
            pct = int((comp_rep / max(total_rep, 1)) * 100)
            bar = "█" * (pct // 20) + "░" * (5 - pct // 20)
            urg = "🔴" if pct == 0 else "🟢" if pct >= 80 else "🟡"
            print(f"\n {diff_names[diff_num]:<10} {bar} {comp_rep}/{total_rep} ({pct}%) {urg}")
        
        print(f"\n Progreso:  {bar_global} {progress_pct}%{' ':<15}│", end="")
        print(f"\n Puntaje:   {avg_score}%{' ':<23}│ Total rep: {comp}/{req} ({int((comp/max(req,1))*100)}%)")
        print(f" Tiempo:    {time_str}{' ':<22}│")
        print(f"{Color.CYAN}{'─'*78}{Color.RESET}")
        
        # 2. MÓDULOS (ordenados por urgencia)
        cursor.execute("""
            SELECT s.module, s.id, s.name, s.repetitions_required,
                COUNT(CASE WHEN p.score>=80 THEN 1 END),
                ROUND(COALESCE(AVG(p.score),0),0)
            FROM scenarios s LEFT JOIN progress p ON s.id = p.scenario_id
            GROUP BY s.id ORDER BY s.module, 
                    s.repetitions_required - COUNT(CASE WHEN p.score>=80 THEN 1 END) DESC
        """)
        
        modules = {}
        for module, sid, name, req, comp, avg_score in cursor.fetchall():
            if module not in modules: modules[module] = []
            faltan = req - comp
            pct = int((comp / max(req, 1)) * 100)
            bar = "█" * (pct // 20) + "░" * (5 - pct // 20)
            urg = "🔴" if faltan > 3 else "🟡" if faltan > 0 else "🟢"
            modules[module].append(f"{sid} {name[:25]:<25} {bar} {comp}/{req} {urg}")
        
        # Mostrar en 2 columnas
        mod_list = list(modules.items())
        for i in range(0, len(mod_list), 2):
            left_mod, left_items = mod_list[i]
            right_mod = mod_list[i+1][0] if i+1 < len(mod_list) else ""
            right_items = modules.get(right_mod, [])
            
            print(f"\n{left_mod.replace('_',' ').title():<28}│{right_mod.replace('_',' ').title():<25}")
            print(f"{''.join(['─']*28)}│{''.join(['─']*25)}")
            
            for j in range(max(len(left_items), len(right_items))):
                left = left_items[j] if j < len(left_items) else " " * 40
                right = right_items[j] if j < len(right_items) else " " * 35
                print(f" {left:<40}│{right}")
        
        # 3. ÚLTIMOS INTENTOS
        cursor.execute("""
            SELECT s.name[:30], p.time_seconds, p.score, 
                CASE s.difficulty WHEN 1 THEN 'Básico' WHEN 2 THEN 'Intermedio' WHEN 3 THEN 'Avanzado' END,
                datetime(p.completed_at)
            FROM progress p JOIN scenarios s ON p.scenario_id = s.id
            ORDER BY p.completed_at DESC LIMIT 5
        """)
        
        print(f"\n{Color.CYAN}{'⏰ ÚLTIMOS INTENTOS':<78}{Color.RESET}")
        print(f"{''.join(['─']*78)}")
        attempts = cursor.fetchall()
        if attempts:
            for name, secs, score, diff, date in attempts:
                time_str = self.format_time(secs)
                print(f" {date[-8:]:<8} │ {name:<25} │ {time_str:<7} │ {score}pts │ {diff}")
        else:
            print(" Ningún intento registrado aún. ¡Practica tu primer ejercicio!")
        
        db.close()
        print(f"\n{Color.CYAN}{'─'*78}{Color.RESET}")
        print(f"{Color.YELLOW}⌨️  [P]racticar urgentes  [B]ásico  [I]ntermedio  [A]vanzado  [V]olver{Color.RESET}")
        pause()

    def format_time(self, seconds):
        """Formato hh:mm:ss"""
        hours, rem = divmod(seconds, 3600)
        mins, secs = divmod(rem, 60)
        return f"{hours:01d}h{ mins:02d}m" if hours else f"{mins:02d}m{secs:02d}s"

