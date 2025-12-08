#!/usr/bin/env python3
"""
CREADOR DE BASE DE DATOS COMPLETA - RHCSA Trainer v2.0
Estructura normalizada con validaciones en tabla separada
"""
import os
import sqlite3
from datetime import datetime
from pathlib import Path

# Configuración
PROJECT_ROOT = Path(__file__).parent
DB_PATH = PROJECT_ROOT / "data" / "database" / "rhcsa_trainer.db"
DB_BACKUP_DIR = PROJECT_ROOT / "data" / "database" / "backups"

def ensure_directories():
    """Asegura que existan los directorios necesarios"""
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    DB_BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    print(f"📁 Directorios verificados")

def backup_existing_db():
    """Hace backup de BD existente si hay una"""
    if DB_PATH.exists():
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        backup_file = DB_BACKUP_DIR / f"rhcsa_trainer_backup_{timestamp}.db"
        
        import shutil
        shutil.copy2(DB_PATH, backup_file)
        print(f"📦 Backup creado: {backup_file}")
        return True
    return False

def create_complete_database():
    """Crea la estructura de BD completa y normalizada"""
    
    print("=" * 60)
    print("🚀 CREANDO BASE DE DATOS COMPLETA - RHCSA Trainer v2.0")
    print("=" * 60)
    
    # Backup si existe
    if backup_existing_db():
        print("🗑️  Eliminando base de datos anterior...")
        DB_PATH.unlink(missing_ok=True)
    
    # Conectar a nueva BD
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Activar foreign keys y mejoras de performance
    cursor.execute("PRAGMA foreign_keys = ON")
    cursor.execute("PRAGMA journal_mode = WAL")
    cursor.execute("PRAGMA synchronous = NORMAL")
    
    # ============================================
    # 1. TABLA: modules (Módulos del curso)
    # ============================================
    print("\n📚 1. Creando tabla: modules")
    cursor.execute("""
    CREATE TABLE modules (
        id TEXT PRIMARY KEY,                   -- Ej: "1", "3.2"
        parent_id TEXT,                        -- Para jerarquía: "3" → "3.2"
        name TEXT NOT NULL,                    -- "Local Storage"
        description TEXT,                      -- Descripción detallada
        icon TEXT DEFAULT '📦',               -- Emoji/icono
        order_num REAL NOT NULL,               -- 1.0, 3.2, etc.
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        
        FOREIGN KEY (parent_id) REFERENCES modules(id) ON DELETE CASCADE
    )
    """)
    
    # ============================================
    # 2. TABLA: labs (Laboratorios principales)
    # ============================================
    print("🔬 2. Creando tabla: labs")
    cursor.execute("""
    CREATE TABLE labs (
        id TEXT PRIMARY KEY,                   -- lab-lvm-001
        module_id TEXT NOT NULL,               -- Referencia a módulo
        title TEXT NOT NULL,                   -- "Crear Physical Volume"
        subtitle TEXT,                         -- "Fundamentos de LVM"
        
        -- Metadatos
        difficulty INTEGER DEFAULT 1 CHECK (difficulty BETWEEN 1 AND 5),
        points INTEGER DEFAULT 20 CHECK (points > 0),
        estimated_time INTEGER,               -- Minutos estimados
        version TEXT DEFAULT '1.0',
        
        -- Contenido
        scenario_text TEXT NOT NULL,           -- Descripción para usuario
        setup_ssh TEXT,                        -- Script de setup
        hints_text TEXT,                       -- Pistas opcionales
        
        -- Configuración VM
        vm_ip TEXT DEFAULT '192.168.1.100',
        vm_user TEXT DEFAULT 'rhcsa_lab',
        vm_requires_sudo BOOLEAN DEFAULT TRUE,
        
        -- Estado
        is_published BOOLEAN DEFAULT TRUE,
        is_deprecated BOOLEAN DEFAULT FALSE,
        
        -- Auditoría
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        published_at TIMESTAMP,
        
        FOREIGN KEY (module_id) REFERENCES modules(id) ON DELETE CASCADE
    )
    """)
    
    # ============================================
    # 3. TABLA: lab_validations (VALIDACIONES - TABLA SEPARADA)
    # ============================================
    print("✅ 3. Creando tabla: lab_validations (CRÍTICA)")
    cursor.execute("""
    CREATE TABLE lab_validations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lab_id TEXT NOT NULL,
        
        -- COMANDO A EJECUTAR
        command TEXT NOT NULL,
        command_timeout INTEGER DEFAULT 10,    -- segundos
        
        -- TIPO DE VALIDACIÓN
        validation_type TEXT NOT NULL CHECK (
            validation_type IN (
                'output_contains',
                'output_exact', 
                'output_regex',
                'range_numeric',
                'range_units',
                'in_list',
                'count_lines',
                'exit_code',
                'file_exists',
                'service_status'
            )
        ),
        
        -- VALOR(ES) ESPERADO(S)
        expected_value TEXT,                   -- Para tipos simples
        expected_min TEXT,                     -- Para rangos
        expected_max TEXT,                     -- Para rangos
        expected_list TEXT,                    -- JSON array para in_list
        regex_pattern TEXT,                    -- Para regex
        
        -- METADATOS DE VALIDACIÓN
        description TEXT NOT NULL,             -- Descripción amigable
        weight INTEGER DEFAULT 1 CHECK (weight > 0),
        order_index INTEGER DEFAULT 0,         -- Orden de ejecución
        is_required BOOLEAN DEFAULT TRUE,
        fail_message TEXT,                     -- Mensaje si falla
        success_message TEXT,                  -- Mensaje si pasa
        
        -- CONDICIONES ADICIONALES
        depends_on_validation_id INTEGER,      -- Dependencia de otra validación
        pre_command TEXT,                      -- Comando a ejecutar antes
        post_command TEXT,                     -- Comando a ejecutar después
        
        -- AUDITORÍA
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        
        FOREIGN KEY (lab_id) REFERENCES labs(id) ON DELETE CASCADE,
        FOREIGN KEY (depends_on_validation_id) REFERENCES lab_validations(id),
        
        -- Restricciones de integridad
        CHECK (
            (validation_type IN ('output_contains', 'output_exact', 'output_regex', 'exit_code') AND expected_value IS NOT NULL) OR
            (validation_type IN ('range_numeric', 'range_units') AND expected_min IS NOT NULL AND expected_max IS NOT NULL) OR
            (validation_type = 'in_list' AND expected_list IS NOT NULL) OR
            (validation_type = 'count_lines' AND expected_value IS NOT NULL) OR
            (validation_type IN ('file_exists', 'service_status'))
        )
    )
    """)
    
    # ============================================
    # 4. TABLA: users (Usuarios del sistema)
    # ============================================
    print("👤 4. Creando tabla: users")
    cursor.execute("""
    CREATE TABLE users (
        id TEXT PRIMARY KEY,                   -- UUID o username
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE,
        display_name TEXT,
        
        -- Roles y permisos
        role TEXT DEFAULT 'student' CHECK (role IN ('student', 'instructor', 'admin')),
        is_active BOOLEAN DEFAULT TRUE,
        
        -- Configuración
        theme TEXT DEFAULT 'dark',
        language TEXT DEFAULT 'es',
        
        -- Seguridad
        password_hash TEXT,                    -- Para futuro auth
        last_login TIMESTAMP,
        failed_attempts INTEGER DEFAULT 0,
        
        -- Auditoría
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    """)
    
    # ============================================
    # 5. TABLA: user_progress (Progreso por usuario)
    # ============================================
    print("📊 5. Creando tabla: user_progress")
    cursor.execute("""
    CREATE TABLE user_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL DEFAULT 'default',
        lab_id TEXT NOT NULL,
        
        -- ESTADÍSTICAS BÁSICAS
        repetitions_completed INTEGER DEFAULT 0 CHECK (repetitions_completed >= 0),
        total_attempts INTEGER DEFAULT 0 CHECK (total_attempts >= 0),
        
        -- PUNTUACIONES
        best_score REAL DEFAULT 0 CHECK (best_score BETWEEN 0 AND 100),
        avg_score REAL DEFAULT 0 CHECK (avg_score BETWEEN 0 AND 100),
        last_score REAL CHECK (last_score BETWEEN 0 AND 100),
        
        -- TIEMPOS
        best_time INTEGER,                     -- Mejor tiempo en segundos
        avg_time INTEGER,                      -- Tiempo promedio en segundos
        total_time INTEGER DEFAULT 0,          -- Tiempo total invertido
        
        -- GAMIFICACIÓN
        streak_current INTEGER DEFAULT 0,
        streak_longest INTEGER DEFAULT 0,
        streak_last_date DATE,
        
        mastery_level TEXT DEFAULT 'novato' CHECK (
            mastery_level IN ('novato', 'aprendiendo', 'proficiente', 'experto', 'maestro')
        ),
        
        badges_json TEXT DEFAULT '[]',         -- JSON con badges obtenidos
        
        -- SPACED REPETITION (Anki-like)
        next_review DATE,
        interval_days INTEGER DEFAULT 1,
        ease_factor REAL DEFAULT 2.5 CHECK (ease_factor BETWEEN 1.3 AND 4.0),
        
        -- ESTADO
        is_completed BOOLEAN DEFAULT FALSE,
        is_mastered BOOLEAN DEFAULT FALSE,
        
        -- FECHAS
        first_attempt TIMESTAMP,
        last_attempt TIMESTAMP,
        completed_at TIMESTAMP,
        
        -- AUDITORÍA
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (lab_id) REFERENCES labs(id) ON DELETE CASCADE,
        UNIQUE(user_id, lab_id)
    )
    """)
    
    # ============================================
    # 6. TABLA: attempt_history (Historial de intentos)
    # ============================================
    print("📝 6. Creando tabla: attempt_history")
    cursor.execute("""
    CREATE TABLE attempt_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL DEFAULT 'default',
        lab_id TEXT NOT NULL,
        
        -- RESULTADOS GENERALES
        score REAL CHECK (score BETWEEN 0 AND 100),
        execution_time INTEGER,                -- segundos
        
        -- DESGLOSE DE VALIDACIONES
        total_validations INTEGER,
        passed_validations INTEGER,
        failed_validations INTEGER,
        skipped_validations INTEGER,
        
        -- CONFIGURACIÓN USADA
        vm_ip TEXT,
        vm_user TEXT,
        ssh_method TEXT DEFAULT 'password',    -- password, key
        
        -- ESTADO
        status TEXT DEFAULT 'completed' CHECK (
            status IN ('started', 'completed', 'failed', 'timeout', 'cancelled')
        ),
        
        -- ERRORES (si aplica)
        error_message TEXT,
        error_details TEXT,
        
        -- TIMESTAMPS
        started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        completed_at TIMESTAMP,
        
        -- AUDITORÍA
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (lab_id) REFERENCES labs(id) ON DELETE CASCADE
    )
    """)
    
    # ============================================
    # 7. TABLA: validation_results (Resultados detallados)
    # ============================================
    print("🔍 7. Creando tabla: validation_results")
    cursor.execute("""
    CREATE TABLE validation_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        attempt_id INTEGER NOT NULL,
        validation_id INTEGER NOT NULL,
        
        -- EJECUCIÓN
        command_executed TEXT NOT NULL,
        raw_output TEXT,                       -- Output completo
        exit_code INTEGER,
        execution_time_ms INTEGER,             -- milisegundos
        
        -- RESULTADO
        passed BOOLEAN NOT NULL,
        match_type_used TEXT,
        expected_value TEXT,
        actual_value TEXT,
        
        -- DEBUG INFO
        error_output TEXT,                     -- stderr si hubo error
        debug_info TEXT,                       -- Información adicional
        
        -- METADATOS
        weight INTEGER DEFAULT 1,
        was_required BOOLEAN DEFAULT TRUE,
        
        -- TIMESTAMP
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        
        FOREIGN KEY (attempt_id) REFERENCES attempt_history(id) ON DELETE CASCADE,
        FOREIGN KEY (validation_id) REFERENCES lab_validations(id) ON DELETE CASCADE
    )
    """)
    
    # ============================================
    # 8. TABLA: system_config (Configuración global)
    # ============================================
    print("⚙️  8. Creando tabla: system_config")
    cursor.execute("""
    CREATE TABLE system_config (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        data_type TEXT DEFAULT 'string' CHECK (
            data_type IN ('string', 'integer', 'float', 'boolean', 'json')
        ),
        category TEXT DEFAULT 'general',
        description TEXT,
        is_public BOOLEAN DEFAULT FALSE,       -- Si puede verlo el usuario
        is_editable BOOLEAN DEFAULT TRUE,      -- Si puede editarlo el admin
        
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        
        CHECK (
            (data_type = 'boolean' AND value IN ('true', 'false')) OR
            data_type != 'boolean'
        )
    )
    """)
    
    # ============================================
    # 9. TABLA: lab_tags (Etiquetas para labs)
    # ============================================
    print("🏷️  9. Creando tabla: lab_tags")
    cursor.execute("""
    CREATE TABLE lab_tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lab_id TEXT NOT NULL,
        tag TEXT NOT NULL,                     -- Ej: 'lvm', 'filesystem', 'advanced'
        tag_type TEXT DEFAULT 'topic',         -- topic, difficulty, technology
        
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        
        FOREIGN KEY (lab_id) REFERENCES labs(id) ON DELETE CASCADE,
        UNIQUE(lab_id, tag, tag_type)
    )
    """)
    
    # ============================================
    # CREAR ÍNDICES PARA PERFORMANCE
    # ============================================
    print("\n🚀 Creando índices para optimización...")
    
    # Labs
    cursor.execute("CREATE INDEX idx_labs_module ON labs(module_id)")
    cursor.execute("CREATE INDEX idx_labs_difficulty ON labs(difficulty)")
    cursor.execute("CREATE INDEX idx_labs_published ON labs(is_published) WHERE is_published = TRUE")
    
    # Validaciones (CRÍTICO para performance)
    cursor.execute("CREATE INDEX idx_validations_lab ON lab_validations(lab_id)")
    cursor.execute("CREATE INDEX idx_validations_order ON lab_validations(lab_id, order_index)")
    cursor.execute("CREATE INDEX idx_validations_type ON lab_validations(validation_type)")
    
    # Progreso de usuario
    cursor.execute("CREATE INDEX idx_progress_user ON user_progress(user_id)")
    cursor.execute("CREATE INDEX idx_progress_lab ON user_progress(lab_id)")
    cursor.execute("CREATE INDEX idx_progress_completion ON user_progress(is_completed)")
    cursor.execute("CREATE INDEX idx_progress_mastery ON user_progress(mastery_level)")
    
    # Historial
    cursor.execute("CREATE INDEX idx_attempts_user ON attempt_history(user_id)")
    cursor.execute("CREATE INDEX idx_attempts_lab ON attempt_history(lab_id)")
    cursor.execute("CREATE INDEX idx_attempts_date ON attempt_history(started_at)")
    cursor.execute("CREATE INDEX idx_attempts_score ON attempt_history(score)")
    
    # Resultados de validación
    cursor.execute("CREATE INDEX idx_vresults_attempt ON validation_results(attempt_id)")
    cursor.execute("CREATE INDEX idx_vresults_validation ON validation_results(validation_id)")
    cursor.execute("CREATE INDEX idx_vresults_passed ON validation_results(passed)")
    
    # Tags
    cursor.execute("CREATE INDEX idx_tags_lab ON lab_tags(lab_id)")
    cursor.execute("CREATE INDEX idx_tags_tag ON lab_tags(tag)")
    
    # ============================================
    # INSERTAR DATOS INICIALES
    # ============================================
    print("\n📝 Insertando datos iniciales...")
    
    # 1. Insertar usuario por defecto
    cursor.execute("""
    INSERT OR IGNORE INTO users (id, username, display_name, role)
    VALUES ('default', 'default', 'Usuario Principal', 'student')
    """)
    
    # 2. Insertar módulos principales
    modules_data = [
        ('1', None, 'Essential Tools', 'Herramientas esenciales de administración', '🔧', 1.0),
        ('2', None, 'Running Systems', 'Administración de sistemas en ejecución', '🚀', 2.0),
        ('3', None, 'Local Storage', 'Almacenamiento local y LVM', '💾', 3.0),
        ('3.1', '3', 'Particiones', 'Administración de particiones de disco', '🗂️', 3.1),
        ('3.2', '3', 'LVM', 'Logical Volume Manager', '🧩', 3.2),
        ('4', None, 'File Systems', 'Sistemas de archivos', '📁', 4.0),
        ('5', None, 'Deploy Systems', 'Implementación de sistemas', '🖥️', 5.0),
        ('6', None, 'Networking', 'Redes y conectividad', '🌐', 6.0),
    ]
    
    cursor.executemany("""
    INSERT OR IGNORE INTO modules (id, parent_id, name, description, icon, order_num)
    VALUES (?, ?, ?, ?, ?, ?)
    """, modules_data)
    
    # 3. Insertar configuración del sistema
    system_config = [
        # General
        ('system.version', '2.0', 'string', 'general', 'Versión del sistema', True, False),
        ('system.name', 'RHCSA Lab Trainer', 'string', 'general', 'Nombre de la aplicación', True, False),
        
        # SSH
        ('ssh.default_timeout', '30', 'integer', 'ssh', 'Timeout SSH en segundos', False, True),
        ('ssh.default_user', 'student', 'string', 'ssh', 'Usuario SSH por defecto', False, True),
        ('ssh.retry_attempts', '3', 'integer', 'ssh', 'Intentos de reconexión', False, True),
        
        # Validación
        ('validation.default_timeout', '10', 'integer', 'validation', 'Timeout por validación', False, True),
        ('validation.max_concurrent', '3', 'integer', 'validation', 'Máximo validaciones concurrentes', False, True),
        
        # Scoring
        ('scoring.pass_threshold', '70', 'integer', 'scoring', 'Umbral para aprobar (%)', True, True),
        ('scoring.mastery_threshold', '90', 'integer', 'scoring', 'Umbral para maestría (%)', True, True),
        ('scoring.weight_enabled', 'true', 'boolean', 'scoring', 'Usar pesos en validaciones', False, True),
        
        # Spaced Repetition
        ('spaced_repetition.enabled', 'true', 'boolean', 'spaced_repetition', 'Habilitar repetición espaciada', True, True),
        ('spaced_repetition.max_interval', '30', 'integer', 'spaced_repetition', 'Máximo días entre repasos', False, True),
        ('spaced_repetition.min_interval', '1', 'integer', 'spaced_repetition', 'Mínimo días entre repasos', False, True),
        
        # UI/UX
        ('ui.theme', 'dark', 'string', 'ui', 'Tema de interfaz', True, True),
        ('ui.language', 'es', 'string', 'ui', 'Idioma de la interfaz', True, True),
        ('ui.show_hints', 'true', 'boolean', 'ui', 'Mostrar pistas', True, True),
        ('ui.animations', 'true', 'boolean', 'ui', 'Habilitar animaciones', True, True),
    ]
    
    cursor.executemany("""
    INSERT OR IGNORE INTO system_config 
    (key, value, data_type, category, description, is_public, is_editable)
    VALUES (?, ?, ?, ?, ?, ?, ?)
    """, system_config)
    
    # ============================================
    # FINALIZAR
    # ============================================
    
    conn.commit()
    
    # Verificar creación
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
    tables = cursor.fetchall()
    
    print("\n" + "=" * 60)
    print("✅ BASE DE DATOS COMPLETA CREADA EXITOSAMENTE")
    print("=" * 60)
    print(f"\n📍 Ubicación: {DB_PATH}")
    print(f"📊 Tamaño: {DB_PATH.stat().st_size if DB_PATH.exists() else 0} bytes")
    
    print("\n📋 TABLAS CREADAS:")
    for i, (table_name,) in enumerate(tables, 1):
        cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
        count = cursor.fetchone()[0]
        print(f"   {i:2d}. {table_name:25} ({count} registros)")
    
    print("\n🎯 ESTRUCTURA CLAVE:")
    print("   • lab_validations → Validaciones en TABLA SEPARADA")
    print("   • validation_type → Tipos específicos: output_contains, range_numeric, etc.")
    print("   • user_progress → Progreso por usuario con spaced repetition")
    print("   • attempt_history + validation_results → Analytics completo")
    print("   • system_config → Configuración centralizada")
    
    print("\n🔍 ÍNDICES CREADOS: 16 índices para optimización")
    
    # Mostrar configuración inicial
    print("\n⚙️  CONFIGURACIÓN INICIAL:")
    cursor.execute("SELECT key, value, description FROM system_config WHERE category='general'")
    for key, value, desc in cursor.fetchall():
        print(f"   • {key:30} = {value:10} # {desc}")
    
    conn.close()
    
    print("\n" + "=" * 60)
    print("🚀 ¡Base de datos lista para usar!")
    print("=" * 60)

def main():
    """Función principal"""
    try:
        ensure_directories()
        create_complete_database()
        
        # Verificar que se puede acceder
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute("PRAGMA foreign_key_check")
        result = cursor.fetchone()
        if result:
            print(f"⚠️  Advertencia: Problemas con foreign keys: {result}")
        else:
            print("🔒 Foreign keys: OK")
        conn.close()
        
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        print("\n💡 Solución:")
        print("   1. Asegúrate de tener permisos de escritura")
        print("   2. Cierra cualquier conexión a la BD existente")
        print("   3. Intenta ejecutar sin sudo primero")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())