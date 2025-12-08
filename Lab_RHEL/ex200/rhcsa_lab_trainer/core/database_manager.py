# Lab_RHEL/ex200/rhcsa_lab_trainer/core/database_manager.py
#!/usr/bin/env python3
"""
GESTOR DE BASE DE DATOS - Versión 2.0
Para la nueva estructura completa de BD
"""
import sqlite3
import json
from datetime import datetime, date
from typing import Dict, List, Any, Optional, Tuple
from contextlib import contextmanager
from pathlib import Path

class DatabaseManager:
    """Gestor de base de datos para estructura completa"""
    
    def __init__(self, db_path: str = None):
        self.db_path = db_path or str(Path(__file__).parent.parent / "data" / "database" / "rhcsa_trainer.db")
        self._ensure_tables()
    
    def _ensure_tables(self):
        """Verifica/crea tablas si no existen"""
        # La BD ya fue creada completa por create_complete_database.py
        # Esta función es solo para verificar conexión
        pass
    
    @contextmanager
    def get_connection(self):
        """Context manager para conexión a BD"""
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row  # Para acceso por nombre de columna
        try:
            # Activar foreign keys
            conn.execute("PRAGMA foreign_keys = ON")
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()
    
    @contextmanager
    def get_cursor(self):
        """Context manager para cursor"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            yield cursor
    
    # ============================================
    # MÉTODOS PARA LABS
    # ============================================
    
    def get_lab_by_id(self, lab_id: str) -> Optional[Dict]:
        """Obtiene un lab completo con sus validaciones"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            
            # 1. Obtener lab básico
            cursor.execute("""
                SELECT l.*, m.name as module_name
                FROM labs l
                LEFT JOIN modules m ON l.module_id = m.id
                WHERE l.id = ? AND l.is_published = 1
            """, (lab_id,))
            
            lab_row = cursor.fetchone()
            if not lab_row:
                return None
            
            lab = dict(lab_row)
            
            # 2. Obtener validaciones
            cursor.execute("""
                SELECT * FROM lab_validations 
                WHERE lab_id = ? 
                ORDER BY order_index
            """, (lab_id,))
            
            validations = [dict(row) for row in cursor.fetchall()]
            lab['validations'] = validations
            
            # 3. Obtener tags
            cursor.execute("""
                SELECT tag FROM lab_tags 
                WHERE lab_id = ?
            """, (lab_id,))
            
            tags = [row['tag'] for row in cursor.fetchall()]
            lab['tags'] = tags
            
            return lab
    
    def get_all_labs(self, module_id: str = None) -> List[Dict]:
        """Obtiene todos los labs (opcionalmente filtrados por módulo)"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            
            query = """
                SELECT l.*, m.name as module_name,
                       (SELECT COUNT(*) FROM lab_validations WHERE lab_id = l.id) as validation_count
                FROM labs l
                LEFT JOIN modules m ON l.module_id = m.id
                WHERE l.is_published = 1
            """
            params = []
            
            if module_id:
                query += " AND l.module_id = ?"
                params.append(module_id)
            
            query += " ORDER BY l.module_id, l.difficulty, l.title"
            
            cursor.execute(query, params)
            return [dict(row) for row in cursor.fetchall()]
    
    # ============================================
    # MÉTODOS PARA MÓDULOS
    # ============================================
    
    def get_all_modules(self) -> List[Dict]:
        """Obtiene todos los módulos con conteo de labs"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            
            cursor.execute("""
                SELECT m.*, 
                       COUNT(l.id) as labs_count,
                       SUM(CASE WHEN up.is_completed = 1 THEN 1 ELSE 0 END) as completed_count
                FROM modules m
                LEFT JOIN labs l ON m.id = l.module_id AND l.is_published = 1
                LEFT JOIN user_progress up ON l.id = up.lab_id AND up.user_id = 'default'
                WHERE m.is_active = 1
                GROUP BY m.id
                ORDER BY m.order_num
            """)
            
            return [dict(row) for row in cursor.fetchall()]
    
    def get_module_by_id(self, module_id: str) -> Optional[Dict]:
        """Obtiene un módulo por ID"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            
            cursor.execute("""
                SELECT m.*, 
                       GROUP_CONCAT(DISTINCT lt.tag) as common_tags
                FROM modules m
                LEFT JOIN labs l ON m.id = l.module_id
                LEFT JOIN lab_tags lt ON l.id = lt.lab_id
                WHERE m.id = ?
                GROUP BY m.id
            """, (module_id,))
            
            row = cursor.fetchone()
            return dict(row) if row else None
    
    # ============================================
    # MÉTODOS PARA PROGRESO DE USUARIO
    # ============================================
    
    def get_user_progress(self, user_id: str = 'default', lab_id: str = None) -> Dict:
        """Obtiene progreso de usuario"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            
            if lab_id:
                # Progreso para un lab específico
                cursor.execute("""
                    SELECT * FROM user_progress 
                    WHERE user_id = ? AND lab_id = ?
                """, (user_id, lab_id))
                
                row = cursor.fetchone()
                return dict(row) if row else None
            else:
                # Resumen general de progreso
                cursor.execute("""
                    SELECT 
                        COUNT(DISTINCT lab_id) as total_labs,
                        SUM(CASE WHEN is_completed = 1 THEN 1 ELSE 0 END) as completed_labs,
                        SUM(CASE WHEN mastery_level = 'maestro' THEN 1 ELSE 0 END) as mastered_labs,
                        AVG(avg_score) as overall_avg_score,
                        SUM(total_time) as total_study_time
                    FROM user_progress 
                    WHERE user_id = ?
                """, (user_id,))
                
                return dict(cursor.fetchone())
    
    def update_progress_after_attempt(
        self, 
        user_id: str, 
        lab_id: str, 
        score: float, 
        execution_time: int,
        passed_validations: int,
        total_validations: int
    ) -> bool:
        """Actualiza progreso después de un intento"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                
                # Obtener progreso actual
                cursor.execute("""
                    SELECT * FROM user_progress 
                    WHERE user_id = ? AND lab_id = ?
                """, (user_id, lab_id))
                
                current = cursor.fetchone()
                now = datetime.now()
                today = date.today()
                
                if current:
                    # Actualizar existente
                    current = dict(current)
                    
                    # Calcular nuevas estadísticas
                    new_attempts = current['total_attempts'] + 1
                    new_avg_score = (
                        (current['avg_score'] * current['total_attempts'] + score) 
                        / new_attempts
                    )
                    new_avg_time = (
                        (current['avg_time'] * current['total_attempts'] + execution_time) 
                        / new_attempts
                    )
                    
                    # Actualizar streak
                    streak_current = current['streak_current']
                    if score >= 70:  # Si pasó
                        if current['streak_last_date'] == today:
                            # Ya actualizado hoy
                            pass
                        elif (current['streak_last_date'] and 
                              (today - current['streak_last_date']).days == 1):
                            # Día consecutivo
                            streak_current += 1
                        else:
                            # Nuevo streak
                            streak_current = 1
                        
                        streak_longest = max(current['streak_longest'], streak_current)
                        streak_last_date = today
                    else:
                        # Reiniciar streak
                        streak_current = 0
                        streak_longest = current['streak_longest']
                        streak_last_date = current['streak_last_date']
                    
                    # Determinar mastery level
                    mastery_level = current['mastery_level']
                    if score >= 90 and new_attempts >= 3:
                        mastery_level = 'maestro'
                    elif score >= 80 and new_attempts >= 2:
                        mastery_level = 'experto'
                    elif score >= 70:
                        mastery_level = 'proficiente'
                    elif new_attempts >= 1:
                        mastery_level = 'aprendiendo'
                    
                    # Actualizar
                    cursor.execute("""
                        UPDATE user_progress SET
                            repetitions_completed = repetitions_completed + 1,
                            total_attempts = ?,
                            last_score = ?,
                            best_score = MAX(best_score, ?),
                            avg_score = ?,
                            best_time = CASE 
                                WHEN best_time IS NULL OR ? < best_time THEN ?
                                ELSE best_time 
                            END,
                            avg_time = ?,
                            total_time = total_time + ?,
                            streak_current = ?,
                            streak_longest = ?,
                            streak_last_date = ?,
                            mastery_level = ?,
                            is_completed = CASE WHEN ? >= 70 THEN 1 ELSE is_completed END,
                            is_mastered = CASE WHEN ? >= 90 AND ? >= 3 THEN 1 ELSE is_mastered END,
                            last_attempt = ?,
                            updated_at = ?
                        WHERE user_id = ? AND lab_id = ?
                    """, (
                        new_attempts, score, score, new_avg_score,
                        execution_time, execution_time, new_avg_time, execution_time,
                        streak_current, streak_longest, streak_last_date, mastery_level,
                        score, score, new_attempts, now, now,
                        user_id, lab_id
                    ))
                else:
                    # Crear nuevo registro
                    is_completed = 1 if score >= 70 else 0
                    is_mastered = 1 if score >= 90 else 0
                    mastery_level = 'maestro' if score >= 90 else 'experto' if score >= 80 else 'proficiente' if score >= 70 else 'aprendiendo'
                    
                    cursor.execute("""
                        INSERT INTO user_progress (
                            user_id, lab_id, repetitions_completed, total_attempts,
                            last_score, best_score, avg_score, best_time, avg_time, total_time,
                            streak_current, streak_longest, streak_last_date,
                            mastery_level, is_completed, is_mastered,
                            first_attempt, last_attempt, created_at, updated_at
                        ) VALUES (?, ?, 1, 1, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, (
                        user_id, lab_id, score, score, score,
                        execution_time, execution_time, execution_time,
                        1 if score >= 70 else 0, 1, today if score >= 70 else None,
                        mastery_level, is_completed, is_mastered,
                        now, now, now, now
                    ))
                
                return True
                
        except Exception as e:
            print(f"Error actualizando progreso: {e}")
            return False
    
    # ============================================
    # MÉTODOS PARA HISTORIAL
    # ============================================
    
    def save_attempt_history(
        self,
        user_id: str,
        lab_id: str,
        score: float,
        execution_time: int,
        passed_validations: int,
        total_validations: int,
        vm_ip: str,
        vm_user: str,
        status: str = 'completed'
    ) -> int:
        """Guarda un registro de intento en el historial"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            
            cursor.execute("""
                INSERT INTO attempt_history (
                    user_id, lab_id, score, execution_time,
                    passed_validations, total_validations, failed_validations, skipped_validations,
                    vm_ip, vm_user, status, completed_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                user_id, lab_id, score, execution_time,
                passed_validations, total_validations,
                total_validations - passed_validations, 0,
                vm_ip, vm_user, status, datetime.now()
            ))
            
            return cursor.lastrowid
    
    def save_validation_results(
        self,
        attempt_id: int,
        validation_id: int,
        command_executed: str,
        raw_output: str,
        exit_code: int,
        execution_time_ms: int,
        passed: bool,
        match_type_used: str,
        expected_value: str,
        actual_value: str,
        error_output: str = '',
        debug_info: str = ''
    ) -> bool:
        """Guarda resultados de una validación individual"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            
            cursor.execute("""
                INSERT INTO validation_results (
                    attempt_id, validation_id, command_executed, raw_output,
                    exit_code, execution_time_ms, passed, match_type_used,
                    expected_value, actual_value, error_output, debug_info
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                attempt_id, validation_id, command_executed, raw_output,
                exit_code, execution_time_ms, passed, match_type_used,
                expected_value, actual_value, error_output, debug_info
            ))
            
            return True
    
    # ============================================
    # MÉTODOS PARA CONFIGURACIÓN
    # ============================================
    
    def get_config(self, key: str, default: Any = None) -> Any:
        """Obtiene un valor de configuración"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            
            cursor.execute("""
                SELECT value, data_type FROM system_config 
                WHERE key = ? AND is_editable = 1
            """, (key,))
            
            row = cursor.fetchone()
            if not row:
                return default
            
            value, data_type = row
            
            # Convertir según tipo de dato
            if data_type == 'integer':
                return int(value)
            elif data_type == 'float':
                return float(value)
            elif data_type == 'boolean':
                return value.lower() == 'true'
            elif data_type == 'json':
                return json.loads(value)
            else:
                return value
    
    def set_config(self, key: str, value: Any, data_type: str = None) -> bool:
        """Establece un valor de configuración"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                
                # Determinar tipo de dato si no se especifica
                if not data_type:
                    if isinstance(value, bool):
                        data_type = 'boolean'
                        value = 'true' if value else 'false'
                    elif isinstance(value, int):
                        data_type = 'integer'
                        value = str(value)
                    elif isinstance(value, float):
                        data_type = 'float'
                        value = str(value)
                    elif isinstance(value, (dict, list)):
                        data_type = 'json'
                        value = json.dumps(value)
                    else:
                        data_type = 'string'
                        value = str(value)
                
                cursor.execute("""
                    INSERT OR REPLACE INTO system_config 
                    (key, value, data_type, updated_at)
                    VALUES (?, ?, ?, ?)
                """, (key, value, data_type, datetime.now()))
                
                return True
                
        except Exception as e:
            print(f"Error guardando configuración: {e}")
            return False
    
    # ============================================
    # MÉTODOS DE UTILIDAD
    # ============================================
    
    def reset_user_progress(self, user_id: str = 'default') -> bool:
        """Reinicia el progreso de un usuario"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                
                cursor.execute("DELETE FROM user_progress WHERE user_id = ?", (user_id,))
                cursor.execute("DELETE FROM attempt_history WHERE user_id = ?", (user_id,))
                cursor.execute("DELETE FROM validation_results WHERE attempt_id IN (SELECT id FROM attempt_history WHERE user_id = ?)", (user_id,))
                
                return True
                
        except Exception as e:
            print(f"Error reiniciando progreso: {e}")
            return False
    
    def get_database_stats(self) -> Dict:
        """Obtiene estadísticas de la BD"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            
            stats = {}
            
            # Conteo por tabla
            tables = ['labs', 'lab_validations', 'user_progress', 'attempt_history', 
                     'validation_results', 'modules', 'system_config', 'lab_tags']
            
            for table in tables:
                cursor.execute(f"SELECT COUNT(*) as count FROM {table}")
                stats[table] = cursor.fetchone()['count']
            
            # Tamaño de BD
            cursor.execute("SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size()")
            stats['db_size_bytes'] = cursor.fetchone()['size']
            
            return stats

    def import_master_yaml(self, yaml_path: str) -> int:
        """
        Importa un archivo master YAML con múltiples labs (como el que me mostraste)
        Devuelve cuántos labs se insertaron correctamente
        """
        import yaml
        from pathlib import Path

        if not Path(yaml_path).exists():
            print(f"{Color.RED}Archivo no encontrado: {yaml_path}{Color.RESET}")
            return 0

        try:
            with open(yaml_path, 'r', encoding='utf-8') as f:
                data = yaml.safe_load(f)
        except Exception as e:
            print(f"{Color.RED}Error leyendo YAML: {e}{Color.RESET}")
            return 0

        if not data or 'labs' not in data:
            print(f"{Color.YELLOW}No se encontraron labs en el archivo{Color.RESET}")
            return 0

        labs_inserted = 0
        with self.get_connection() as conn:
            cursor = conn.cursor()

            for lab_data in data['labs']:
                try:
                    lab_id = lab_data['id']

                    # Insertar lab principal
                    cursor.execute("""
                        INSERT OR REPLACE INTO labs 
                        (id, module_id, title, subtitle, difficulty, points, repetitions_required,
                         setup_script, scenario_text, yaml_file, is_published)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
                    """, (
                        lab_id,
                        self._get_module_id_by_name(data.get('module', 'Unknown')),
                        lab_data.get('title', 'Sin título'),
                        lab_data.get('subtitle', ''),
                        lab_data.get('difficulty', 1),
                        lab_data.get('points', 30),
                        lab_data.get('repetitions_required', 5),
                        lab_data.get('setup', ''),
                        lab_data.get('scenario', ''),
                        str(yaml_path)
                    ))

                    # Limpiar validaciones anteriores (por si se reimporta)
                    cursor.execute("DELETE FROM lab_validations WHERE lab_id = ?", (lab_id,))

                    # Insertar validaciones
                    order_index = 0
                    for val in lab_data.get('validations', []):
                        order_index += 1
                        cursor.execute("""
                            INSERT INTO lab_validations 
                            (lab_id, order_index, validation_type, command, expected_output,
                             expected_range_min, expected_range_max, expected_values,
                             match_type, description, weight)
                            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """, (
                            lab_id,
                            order_index,
                            'command_check',  # tipo genérico
                            val.get('command'),
                            val.get('expected_output'),
                            val.get('expected_range', {}).get('min'),
                            val.get('expected_range', {}).get('max'),
                            ','.join(val.get('expected_values', [])) if val.get('expected_values') else None,
                            val.get('match_type', 'exact'),
                            val.get('description', ''),
                            val.get('weight', 5)
                        ))

                    labs_inserted += 1

                except Exception as e:
                    print(f"{Color.RED}Error insertando lab {lab_data.get('id', '?')}: {e}{Color.RESET}")

        print(f"{Color.GREEN}Importados {labs_inserted} labs desde {Path(yaml_path).name}{Color.RESET}")
        return labs_inserted

    def _get_module_id_by_name(self, module_name: str) -> int:
            """Helper interno para obtener module_id por nombre"""
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("SELECT id FROM modules WHERE name LIKE ?", (f"%{module_name}%",))
                row = cursor.fetchone()
                return row['id'] if row else 1  # fallback











# Singleton para uso global
_db_instance = None

def get_db() -> DatabaseManager:
    """Obtiene instancia singleton de DatabaseManager"""
    global _db_instance
    if _db_instance is None:
        _db_instance = DatabaseManager()
    return _db_instance


if __name__ == "__main__":
    # Prueba básica
    db = DatabaseManager()
    stats = db.get_database_stats()
    print("📊 Estadísticas de BD:")
    for table, count in stats.items():
        print(f"  {table}: {count}")