# Lab_RHEL/ex200/rhcsa_lab_trainer/core/database_manager.py
#!/usr/bin/env python3
import sqlite3
import yaml
from pathlib import Path
from ui.display.colors import Color
from datetime import datetime, date, timedelta
import traceback

class DatabaseManager:
    def __init__(self, db_path="data/database/rhcsa_trainer.db"):
        self.db_path = Path(db_path)
        self.conn = sqlite3.connect(self.db_path)
        self.cursor = self.conn.cursor()
    
    def __enter__(self):
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()
    
    def commit(self):
        self.conn.commit()
    
    def close(self):
        if self.conn:
            self.conn.close()

    def import_lab_yaml(self, yaml_path):
        """🚀 GENÉRICO: Importa CUALQUIER YAML MAESTRO → labs DB"""
        try:
            with open(yaml_path, 'r', encoding='utf-8') as f:
                data = yaml.safe_load(f)
            
            if not data or 'labs' not in data:
                print(f"{Color.YELLOW}⚠️  No se encontró 'labs: []' en {yaml_path}{Color.RESET}")
                return 0
            
            labs_imported = 0
            module_name = data.get('module', 'Unknown')
            submodule_name = data.get('submodule', module_name)
            
            print(f"{Color.CYAN}📥 Importando '{submodule_name}' ({len(data['labs'])} labs)...{Color.RESET}")
            
            for lab_data in data.get('labs', []):
                # 🎯 FLEXIBLE: Maneja TU estructura exacta
                lab_id = lab_data.get('id')
                if not lab_id:
                    print(f"{Color.YELLOW}⚠️  Lab sin 'id': {lab_data.get('title', 'Unknown')}{Color.RESET}")
                    continue
                
                title = lab_data.get('title') or lab_data.get('name') or 'Sin título'
                difficulty = lab_data.get('difficulty', 2)
                points = lab_data.get('points', 50)
                repetitions_required = lab_data.get('repetitions_required', 5)
                
                # 🎯 GENÉRICO: scenario/task/description → scenario_text
                scenario_candidates = ['scenario', 'task', 'description']
                scenario_text = None
                for candidate in scenario_candidates:
                    if candidate in lab_data:
                        scenario_text = lab_data[candidate]
                        break
                if not scenario_text:
                    scenario_text = "Realiza la configuración requerida"
                
                # 🎯 expected/validation → expected_text
                expected_candidates = ['expected', 'validation']
                expected_text = None
                for candidate in expected_candidates:
                    if candidate in lab_data:
                        expected_text = lab_data[candidate]
                        break
                if not expected_text:
                    expected_text = "Comandos de verificación ejecutados correctamente"
                
                # 🎯 setup/setup_ssh → setup_ssh
                setup_candidates = ['setup', 'setup_ssh']
                setup_ssh = None
                for candidate in setup_candidates:
                    if candidate in lab_data:
                        setup_ssh = lab_data[candidate]
                        break
                if not setup_ssh:
                    setup_ssh = "# Setup básico requerido"
                
                self.cursor.execute("""
                    INSERT OR REPLACE INTO labs (
                        id, module, submodule, title, subtitle, 
                        difficulty, points, repetitions_required,
                        scenario_text, expected_text, setup_ssh
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    lab_id, module_name, submodule_name, title,
                    lab_data.get('subtitle', ''),
                    difficulty, points, repetitions_required,
                    scenario_text, expected_text, setup_ssh
                ))
                labs_imported += 1
            
            # 🎯 GENÉRICO: modules table
            module_id = module_name.replace(' ', '_').replace('.', '_').lower()
            self.cursor.execute("""
                INSERT OR REPLACE INTO modules 
                (id, name, order_num, labs_count)
                VALUES (?, ?, ?, ?)
            """, (module_id, submodule_name, len(data.get('labs', [])), labs_imported))
            
            self.commit()
            print(f"{Color.GREEN}✅ {labs_imported} labs '{submodule_name}' importados ✓{Color.RESET}")
            return labs_imported
            
        except FileNotFoundError:
            print(f"{Color.RED}❌ YAML no encontrado: {yaml_path}{Color.RESET}")
            return 0
        except Exception as e:
            print(f"{Color.RED}❌ Error parseando YAML: {e}{Color.RESET}")
            print(f"{Color.GRAY}{traceback.format_exc()}{Color.RESET}")
            return 0

    def get_labs_by_module(self, module=None):
        """Lista labs para menú (genérico)"""
        if module:
            self.cursor.execute("""
                SELECT id, title, difficulty, points, 
                       repetitions_completed, repetitions_required
                FROM labs WHERE module=? ORDER BY next_review ASC, difficulty ASC, id
            """, (module,))
        else:
            self.cursor.execute("""
                SELECT id, title, difficulty, points, 
                       repetitions_completed, repetitions_required
                FROM labs ORDER BY module, difficulty, id
            """)
        return self.cursor.fetchall()

    def get_lab_by_id(self, lab_id):
        """Lab completo para training"""
        self.cursor.execute("""
            SELECT * FROM labs WHERE id=? 
            ORDER BY created_at DESC LIMIT 1
        """, (lab_id,))
        return self.cursor.fetchone()

    def get_modules_progress(self):
        """Progreso por módulo (genérico)"""
        self.cursor.execute("""
            SELECT module, COUNT(*) as total_labs,
                   SUM(CASE WHEN repetitions_completed >= repetitions_required THEN 1 ELSE 0 END) as completed,
                   ROUND(AVG(COALESCE(best_score, 0)), 1) as avg_score,
                   (SELECT title FROM labs l2 WHERE l2.module = l1.module ORDER BY best_score DESC LIMIT 1) as best_lab
            FROM labs l1 GROUP BY module ORDER BY module
        """)
        return self.cursor.fetchall()

    def get_weakest_lab(self):
        """Anki: Lab más débil (next_review vencido)"""
        self.cursor.execute("""
            SELECT id FROM labs 
            WHERE next_review <= date('now') OR next_review IS NULL
            ORDER BY interval_days ASC, difficulty DESC
            LIMIT 1
        """)
        return self.cursor.fetchone()

