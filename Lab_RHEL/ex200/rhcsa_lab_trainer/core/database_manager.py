# Lab_RHEL/ex200/rhcsa_lab_trainer/core/database_manager.py
#!/usr/bin/env python3

import sqlite3
import yaml
from pathlib import Path
from ui.display.colors import Color


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
    
    def import_yaml_scenario(self, yaml_path):
        """Importa YAML completo → DB automáticamente"""
        try:
            with open(yaml_path, 'r', encoding='utf-8') as f:
                data = yaml.safe_load(f)
            
            c = self.cursor
            c.execute("""
                INSERT OR REPLACE INTO scenarios 
                (id, name, module, type, path, description, points, repetitions_required)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                data['id'], data['name'], data['module'], data['type'],
                str(yaml_path), data['description'], data['points'], data['repetitions_required']
            ))
            self.conn.commit()
            print(f"{Color.GREEN}✅ {data['id']} importado desde {yaml_path}{Color.RESET}")
            return True
        except Exception as e:
            print(f"{Color.RED}❌ Error importando {yaml_path}: {e}{Color.RESET}")
            return False
