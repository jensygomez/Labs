# Lab_RHEL/ex200/rhcsa_lab_trainer/ui/menu/exercises_menu.py
#!/usr/bin/env python3
"""
Gestión de Laboratorios RHCSA - Nueva DB labs (YAML maestro → 16 labs)
"""
from ui.display.banners import show_banner
from ui.display.colors import Color
from ui.utils.screen_utils import clear_screen, pause
from ui.utils.input_handlers import get_menu_choice
from core.database_manager import DatabaseManager
from pathlib import Path
import subprocess
import os

class ExercisesMenu:
    def run(self):
        while True:
            clear_screen()
            show_banner("GESTIÓN DE LABORATORIOS RHCSA")
            
            print(f"{Color.CYAN}1.{Color.RESET} Nuevo YAML maestro (16 labs)")
            print(f"{Color.CYAN}2.{Color.RESET} Lista laboratorios")
            print(f"{Color.CYAN}3.{Color.RESET} Progreso por módulo")
            print(f"{Color.RED}b{Color.RESET} → Volver al menú principal")
            print()
            
            choice = input(f"{Color.CYAN}Opción → {Color.RESET}").strip().lower()

            if choice in ("b", "back"):
                return
            elif choice == "1":
                self.import_yaml_master()
            elif choice == "2":
                self.list_laboratories()
            elif choice == "3":
                self.show_module_progress()
            else:
                pause(f"{Color.RED}Opción inválida{Color.RESET}")

    def import_yaml_master(self):
        """🚀 IMPORTA TU YAML LVM → 16 labs DB"""
        clear_screen()
        print(f"{Color.YELLOW}📤 IMPORTAR YAML MAESTRO (16 labs por subtema){Color.RESET}")
        print(f"\n{Color.CYAN}Ejemplos:{Color.RESET}")
        print(f"  scenarios/03_local_storage/lvm-master.yaml")
        print(f"  scenarios/01_essential_tools/users-master.yaml")
        
        yaml_path = input(f"\n{Color.CYAN}Ruta YAML → {Color.RESET}").strip()
        if not yaml_path:
            yaml_path = "scenarios/03_local_storage/lvm.yaml"
        
        try:
            with DatabaseManager() as db:
                count = db.import_lab_yaml(yaml_path)
                if count > 0:
                    print(f"{Color.GREEN}🎉 {count} labs importados correctamente!{Color.RESET}")
                    print(f"{Color.CYAN}→ Ahora en Entrenamiento!{Color.RESET}")
                else:
                    print(f"{Color.RED}❌ No se encontraron labs en {yaml_path}{Color.RESET}")
            pause()
        except FileNotFoundError:
            print(f"{Color.RED}❌ Archivo no encontrado: {yaml_path}{Color.RESET}")
            pause()
        except Exception as e:
            print(f"{Color.RED}❌ Error: {e}{Color.RESET}")
            pause()

    def list_laboratories(self):
        """📋 Lista TODOS labs (vacía = mensaje amigable)"""
        try:
            with DatabaseManager() as db:
                labs = db.get_labs_by_module()  # Nueva función labs
                
                clear_screen()
                show_banner("LABORATORIOS DISPONIBLES")
                
                if not labs:
                    print(f"{Color.YELLOW}📭 No hay laboratorios importados{Color.RESET}")
                    print(f"\n{Color.CYAN}🚀 PRIMEROS PASOS:{Color.RESET}")
                    print(f"  1. Opción 1 → Importar YAML LVM")
                    print(f"  2. scenarios/03_local_storage/lvm.yaml")
                    print(f"  3. 16 labs LVM → DB automáticamente")
                    print(f"  4. Training → ¡Practica!")
                    pause()
                    return
                
                # Header PRO
                print(f"{Color.CYAN}{'ID':<14} {'TÍTULO':<35} {'DIFICULTAD':<10} {'PTS':<6} {'REPS':<8} {'ESTADO':<12}{Color.RESET}")
                print(f"{Color.CYAN}{'-'*14} {'-'*35} {'-'*10} {'-'*6} {'-'*8} {'-'*12}{Color.RESET}")
                
                for lab_id, title, difficulty, points, reps_done, reps_total in labs:
                    progress = f"{reps_done}/{reps_total}"
                    if reps_done == 0:
                        status = f"{Color.RED}🔴 Nuevo{Color.RESET}"
                    elif reps_done == reps_total:
                        status = f"{Color.GREEN}🏆 Maestro{Color.RESET}"
                    else:
                        pct = (reps_done / reps_total) * 100
                        status = f"{Color.YELLOW}{int(pct)}%{Color.RESET}"
                    
                    print(f"{lab_id:<14} {title[:34]:<35} D{difficulty:<9} {points:<6} {progress:<8} {status}")
                
                pause()
                
        except Exception as e:
            print(f"{Color.RED}❌ Error DB: {e}{Color.RESET}")
            print(f"{Color.YELLOW}💡 Verifica: python3 create_database.py{Color.RESET}")
            pause()

    def show_module_progress(self):
        """📊 Progreso por módulo RHCSA"""
        try:
            with DatabaseManager() as db:
                modules = db.get_modules_progress()  # Nueva función
                
                clear_screen()
                show_banner("PROGRESO POR MÓDULO")
                
                if not modules:
                    print(f"{Color.YELLOW}No hay módulos con labs{Color.RESET}")
                    pause()
                    return
                
                print(f"{Color.CYAN}{'MÓDULO':<20} {'LABS':<6} {'COMPLETADOS':<12} {'PROMEDIO PTS':<12} {'MEJOR LAB':<20}{Color.RESET}")
                print(f"{Color.CYAN}{'-'*20} {'-'*6} {'-'*12} {'-'*12} {'-'*20}{Color.RESET}")
                
                for module_name, total_labs, completed_labs, avg_score, best_lab in modules:
                    pct = (completed_labs / total_labs) * 100 if total_labs else 0
                    status = f"{Color.GREEN}{pct:.0f}%{Color.RESET}" if pct == 100 else f"{Color.YELLOW}{pct:.0f}%{Color.RESET}"
                    print(f"{module_name:<20} {total_labs:<6} {completed_labs:<12} {avg_score:<12} {best_lab:<20} {status}")
                
                pause()
        except Exception as e:
            print(f"{Color.RED}❌ Error: {e}{Color.RESET}")
            pause()

    def new_exercise_full(self):
        """🗑️ OBSOLETO: Reemplazado por import_yaml_master()"""
        print(f"{Color.YELLOW}🗑️ Función obsoleta → Usa '1. Importar YAML maestro'{Color.RESET}")
        pause()
