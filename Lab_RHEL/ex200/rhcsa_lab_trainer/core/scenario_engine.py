# Lab_RHEL/ex200/rhcsa_lab_trainer/core/scenario_engine.py
#!/usr/bin/env python3
import time
import paramiko
import re
from datetime import datetime, date, timedelta
from pathlib import Path
from ui.display.colors import Color
from ui.utils.screen_utils import clear_screen, pause
from core.database_manager import DatabaseManager

class UniversalEngine:
    def __init__(self, lab_id):
        """Inicializa lab completo desde DB nueva"""
        self.lab_id = lab_id
        self.vm_ip = "192.168.1.100"
        self.vm_user = "rhcsa_lab"
        
        # Cargar TODO del lab desde DB
        with DatabaseManager() as db:
            lab = db.get_lab_by_id(lab_id)
            if not lab:
                raise Exception(f"❌ Lab {lab_id} no encontrado en BD")
            
            # Desempaquetar columnas DB → atributos
            (self.id, self.module, self.submodule, self.title, self.subtitle,
             self.difficulty, self.points, self.repetitions_required, self.repetitions_completed,
             self.last_reviewed, self.next_review, self.interval_days, self.ease_factor,
             self.best_score, self.avg_time_seconds, self.total_attempts, self.mastery_level,
             self.streak, self.badges, self.scenario_text, self.expected_text,
             self.setup_ssh, vm_ip, vm_user, self.created_at, self.updated_at) = lab
            
            self.vm_ip = vm_ip or self.vm_ip
            self.vm_user = vm_user or self.vm_user
        
        print(f"🎯 Cargado: {self.title} (D{self.difficulty}) {self.points}pts")

    def run(self):
        """Flujo completo: setup → Jensy → validate → Anki update"""
        clear_screen()
        print_banner()
        
        print(f"{Color.CYAN}{'='*60}{Color.RESET}")
        print(f"🔬 LABORATORIO: {self.title}")
        print(f"📂 Módulo: {self.module} | Dificultad: D{self.difficulty}")
        print(f"📊 Progreso: {self.repetitions_completed}/{self.repetitions_required}")
        print(f"{Color.CYAN}{'='*60}{Color.RESET}\n")
        
        print(f"{Color.BLUE}📋 ESCENARIO:{Color.RESET}")
        print(self.scenario_text)
        print(f"\n{Color.YELLOW}🔧 Preparando VM...{Color.RESET}")
        
        # 1. SETUP VM via SSH
        if self.run_setup_ssh():
            print(f"{Color.GREEN}✅ VM lista!{Color.RESET}")
        else:
            pause("❌ Error setup VM. Enter para continuar...")
            return
        
        # 2. JENSY TRABAJA
        print(f"\n{Color.CYAN}💻 ssh {self.vm_user}@{self.vm_ip}{Color.RESET}")
        start_time = time.time()
        input(f"{Color.MAGENTA}⏱️  Realiza la tarea → [ENTER] para validar...{Color.RESET}")
        elapsed = int(time.time() - start_time)
        
        # 3. VALIDAR
        score = self.validate()
        print(f"\n{Color.CYAN}📊 VALIDACIÓN FINAL:{Color.RESET}")
        print(f"Tiempo: {elapsed}s | Puntaje: {score}/{self.points}")
        
        # 4. ACTUALIZAR PROGRESO ANKI
        self.update_progress(score, elapsed)
        
        pause("\nEnter para continuar...")

    def run_setup_ssh(self):
        """Ejecuta setup_ssh línea por línea via SSH"""
        try:
            # 🔧 SSH CONFIG INTERACTIVA
            config = SSHConfig()
            config.ask_config()
            
            ssh = paramiko.SSHClient()
            ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            if config.config['auth'] == 'key':
                ssh.connect(config.config['host'], username=config.config['user'], timeout=10)
            else:
                ssh.connect(config.config['host'], username=config.config['user'], 
                        password=config.config['password'], timeout=10)
            
            print(f"{Color.GRAY}📡 Conectando {config.config['user']}@{config.config['host']}...{Color.RESET}")
            
            # Ejecutar cada línea del setup_ssh
            for i, cmd in enumerate(self.setup_ssh.strip().split('\n'), 1):
                cmd = cmd.strip()
                if cmd and not cmd.startswith('#'):
                    print(f"  {i}. {Color.GRAY}{cmd[:60]}...{Color.RESET}")
                    stdin, stdout, stderr = ssh.exec_command(f"sudo bash -c '{cmd}'")
                    exit_code = stdout.channel.recv_exit_status()
                    if exit_code != 0:
                        error = stderr.read().decode().strip()
                        print(f"  {Color.RED}❌ Error: {error[:100]}{Color.RESET}")
                        ssh.close()
                        return False
            
            ssh.close()
            print(f"{Color.GREEN}✅ Setup VM completado ✓{Color.RESET}")
            return True
            
        except Exception as e:
            print(f"{Color.RED}❌ SSH Error: {e}{Color.RESET}")
            return False

    def validate(self):
        """Valida expected_text → Devuelve score 0-100"""
        try:
            # 🔧 SSH CONFIG INTERACTIVA
            config = SSHConfig()
            config.ask_config()
            
            ssh = paramiko.SSHClient()
            ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            if config.config['auth'] == 'key':
                ssh.connect(config.config['host'], username=config.config['user'], timeout=10)
            else:
                ssh.connect(config.config['host'], username=config.config['user'], 
                        password=config.config['password'], timeout=10)
            
            total_checks = 0
            passed_checks = 0
            
            # Parsear expected_text → comandos de validación
            validation_cmds = self.parse_expected_text()
            
            for cmd in validation_cmds:
                stdin, stdout, stderr = ssh.exec_command(cmd)
                output = stdout.read().decode().strip()
                exit_code = stdout.channel.recv_exit_status()
                
                total_checks += 1
                if exit_code == 0 and output:
                    passed_checks += 1
                    print(f"  {Color.GREEN}✓{Color.RESET} {cmd[:50]:<50} OK")
                else:
                    print(f"  {Color.RED}✗{Color.RESET} {cmd[:50]:<50} FAIL")
            
            ssh.close()
            return int((passed_checks / total_checks) * self.points)
            
        except Exception as e:
            print(f"{Color.RED}❌ Validación falló: {e}{Color.RESET}")
            return 0


    def parse_expected_text(self):
        """Parsea expected_text → lista comandos validación"""
        cmds = []
        
        # Regex común para extraer comandos de expected_text
        patterns = [
            r'`([^`]+)`',  # `lvs` → lvs
            r'(\w+\s+\w+(?:\s+\S+)*)',  # comandos sueltos
        ]
        
        for pattern in patterns:
            matches = re.findall(pattern, self.expected_text, re.IGNORECASE)
            cmds.extend(matches)
        
        # Comandos comunes LVM
        lvm_cmds = ['pvs', 'vgs', 'lvs', 'df -h', 'mount | grep mnt']
        cmds.extend([cmd for cmd in lvm_cmds if cmd in self.expected_text.lower()])
        
        return list(set(cmds))[:10]  # Max 10 checks

    def update_progress(self, score, elapsed_time):
        """Actualiza DB: reps, Anki, gamificación"""
        with DatabaseManager() as db:
            # Incrementar repeticiones
            new_reps = self.repetitions_completed + 1
            
            # Calcular nuevo interval (Anki)
            if score >= 90:
                interval_days = min(self.interval_days * 2.5, 30)
                ease_factor = min(self.ease_factor + 0.15, 4.0)
            elif score >= 70:
                interval_days = self.interval_days * 1.8
                ease_factor = self.ease_factor + 0.10
            else:
                interval_days = max(self.interval_days * 0.8, 1)
                ease_factor = max(self.ease_factor - 0.20, 1.3)
            
            next_review = date.today() + timedelta(days=interval_days)
            
            # Mastery level
            mastery = 'novato'
            if new_reps >= self.repetitions_required and score >= 90:
                mastery = 'maestro'
            elif new_reps >= self.repetitions_required * 0.8 and score >= 80:
                mastery = 'proficiente'
            elif new_reps >= self.repetitions_required * 0.5:
                mastery = 'aprendiendo'
            
            # Streak
            streak = self.streak + 1 if score >= 70 else 0
            
            db.cursor.execute("""
                UPDATE labs SET
                    repetitions_completed = ?,
                    best_score = GREATEST(?, best_score),
                    avg_time_seconds = ((avg_time_seconds * total_attempts + ?) / (total_attempts + 1)),
                    total_attempts = total_attempts + 1,
                    last_reviewed = CURRENT_TIMESTAMP,
                    next_review = ?,
                    interval_days = ?,
                    ease_factor = ?,
                    mastery_level = ?,
                    streak = ?,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
            """, (new_reps, score, elapsed_time, next_review, interval_days,
                  ease_factor, mastery, streak, self.lab_id))
            
            db.commit()
            print(f"{Color.GREEN}📈 Progreso actualizado: {new_reps}/{self.repetitions_required} | {mastery}{Color.RESET}")

def print_banner():
    print(f"{Color.MAGENTA}{'='*70}{Color.RESET}")
    print(f"  🎯 {Color.WHITE}RHCSA LAB TRAINER - {Color.CYAN}{Color.BOLD}{time.strftime('%Y-%m-%d %H:%M')}{Color.RESET}")
    print(f"{Color.MAGENTA}{'='*70}{Color.RESET}")
