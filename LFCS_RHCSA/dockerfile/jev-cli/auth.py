#!/usr/bin/env python3
"""
auth.py - Gestión segura de API Keys por modelo para TypeSafe System One.
Cada modelo (kodekey-pro, typesafe/jev-1.13.0, gpt-6-luna, etc.) tiene su
propia API Key, independiente de las demás.

Prioridad de búsqueda por modelo:
  1. Variable de entorno específica  -> KODEKEY_API_KEY_<MODELO_SLUG>
  2. Archivo temporal de la sesión   -> /tmp/.jev_key_<modelo_slug>
  3. Preguntar al usuario y guardarla temporalmente
"""
import os
import re
import stat
import sys

def _slug(model_name: str) -> str:
    """'typesafe/jev-1.13.0' -> 'TYPESAFE_JEV_1_13_0'"""
    return re.sub(r'[^A-Za-z0-9]+', '_', model_name).strip('_').upper()

def _temp_key_file(model_name: str) -> str:
    return f"/tmp/.jev_key_{_slug(model_name).lower()}"

def get_api_key(model_name: str) -> str:
    """Retorna la API Key asociada a `model_name`, pidiéndola solo si es necesario."""
    env_var = f"KODEKEY_API_KEY_{_slug(model_name)}"
    temp_file = _temp_key_file(model_name)

    # 1. Variable de entorno específica del modelo
    key = os.environ.get(env_var)
    if key:
        return key

    # 2. Archivo temporal de la sesión (ya se pidió antes, dentro de este contenedor)
    if os.path.exists(temp_file):
        with open(temp_file, "r") as f:
            key = f.read().strip()
            if key:
                return key

    # 3. Pedirla al usuario y guardarla temporalmente
    print("\n" + "="*70)
    print(f" 🔑 CONFIGURACIÓN DE SESIÓN — Modelo: {model_name}")
    print("="*70)
    print(f" No se encontró una API Key para '{model_name}' en esta sesión.")
    print(" Se guardará temporalmente y se eliminará al salir del contenedor.\n")

    key = input(f" Pega la API Key para '{model_name}' aquí: ").strip()

    if not key:
        print("❌ Error: No se proporcionó una clave. Abortando.")
        sys.exit(1)

    with open(temp_file, "w") as f:
        f.write(key)
    os.chmod(temp_file, stat.S_IREAD | stat.S_IWRITE)  # 0600

    print(f"✅ Clave para '{model_name}' guardada temporalmente para esta sesión.\n")
    return key
