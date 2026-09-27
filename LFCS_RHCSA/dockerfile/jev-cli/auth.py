#!/usr/bin/env python3
"""
auth.py - Gestión segura de la API Key de KodeKey.
Prioridad: Variable de entorno -> Archivo temporal -> Preguntar al usuario.
"""
import os
import stat
import sys

TEMP_KEY_FILE = "/tmp/.jev_session_key"

def get_api_key():
    """Retorna la API Key de KodeKey, pidiéndola solo si es necesario."""
    
    # 1. Intentar leer de variable de entorno
    key = os.environ.get("KODEKEY_API_KEY")
    if key:
        return key
    
    # 2. Intentar leer del archivo temporal de la sesión
    if os.path.exists(TEMP_KEY_FILE):
        with open(TEMP_KEY_FILE, "r") as f:
            key = f.read().strip()
            if key:
                return key
    
    # 3. Pedirla al usuario y guardarla temporalmente
    print("\n" + "="*70)
    print(" 🔑 CONFIGURACIÓN DE SESIÓN")
    print("="*70)
    print(" No se encontró KODEKEY_API_KEY en esta sesión.")
    print(" La clave se guardará temporalmente y se eliminará al salir del contenedor.\n")
    
    key = input(" Pega tu KODEKEY_API_KEY aquí: ").strip()
    
    if not key:
        print("❌ Error: No se proporcionó una clave. Abortando.")
        sys.exit(1)
    
    # Guardar en /tmp con permisos seguros (solo el dueño puede leerlo: 0600)
    with open(TEMP_KEY_FILE, "w") as f:
        f.write(key)
    os.chmod(TEMP_KEY_FILE, stat.S_IREAD | stat.S_IWRITE)
    
    print("✅ Clave guardada temporalmente para esta sesión.\n")
    return key
