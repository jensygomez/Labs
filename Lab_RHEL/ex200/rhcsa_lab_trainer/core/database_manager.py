# Lab_RHEL/ex200/rhcsa_lab_trainer/core/database_manager.py
#!/usr/bin/env python3
import sqlite3
import yaml
from pathlib import Path
from ui.display.colors import Color
from datetime import datetime, date, timedelta

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
        """🚀 NUEVO: Importa TU YAML MAESTRO LVM → labs DB"""
        try:
            with open(yaml_path, 'r', encoding='utf-8') as f:
                data = yaml.safe_load(f)
            
            labs_imported = 0
            for lab in data.get('labs', []):
                self.cursor.execute("""
                    INSERT OR REPLACE INTO labs (
                        id, module, submodule, title, subtitle, 
                        difficulty, points, repetitions_required,
                        scenario_text, expected_text, setup_ssh
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    lab['id'],
                    lab.get('module', '3.2'),  # LVM por defecto
                    lab.get('submodule', 'Administración LVM'),
                    lab['title'],
                    lab.get('subtitle', ''),
                    lab['difficulty'],
                    lab['points'],
                    lab.get('repetitions_required', 5),
                    lab['scenario'],
                    lab['expected'],
                    lab['setup']
                ))
                labs_imported += 1
            
            # Actualizar modules
            self.cursor.execute("""
                INSERT OR REPLACE INTO modules 
                (id, name, order_num, labs_count)
                VALUES ('3.2_lvm', 'Administración LVM', 3.2, ?)
            """, (labs_imported,))
            
            self.commit()
            print(f"{Color.GREEN}✅ {labs_imported} LABS LVM importados desde {yaml_path}{Color.RESET}")
            return labs_imported
        except Exception as e:
            print(f"{Color.RED}❌ Error: {e}{Color.RESET}")
            return 0

    def get_labs_by_module(self, module='3.2'):
        """Lista labs por módulo (para menú opción 6)"""
        self.cursor.execute("""
            SELECT id, title, difficulty, points, repetitions_completed, repetitions_required
            FROM labs WHERE module=? ORDER BY difficulty, id
        """, (module,))
        return self.cursor.fetchall()

    
    def get_lab_by_id(self, lab_id):
        """Obtiene lab completo por ID"""
        self.cursor.execute("""
            SELECT * FROM labs WHERE id=? 
            ORDER BY created_at DESC LIMIT 1
        """, (lab_id,))
        return self.cursor.fetchone()



    def get_modules_progress(self):
        """Progreso por módulo para menú"""
        self.cursor.execute("""
            SELECT 
                module,
                COUNT(*) as total_labs,
                SUM(CASE WHEN repetitions_completed >= repetitions_required THEN 1 ELSE 0 END) as completed,
                AVG(best_score) as avg_score,
                (SELECT title FROM labs l2 WHERE l2.module = l1.module ORDER BY best_score DESC LIMIT 1) as best_lab
            FROM labs l1 GROUP BY module ORDER BY module
        """)
        return self.cursor.fetchall()
