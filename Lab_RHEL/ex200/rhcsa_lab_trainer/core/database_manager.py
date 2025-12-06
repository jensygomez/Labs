#!/usr/bin/env python3
"""
Gestor de Base de Datos RHCSA Lab Trainer
"""
import sqlite3
from pathlib import Path

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

