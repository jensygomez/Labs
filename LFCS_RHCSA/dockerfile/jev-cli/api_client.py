#!/usr/bin/env python3
"""
api_client.py - Cliente de OpenAI configurado para KodeKey/TypeSafe.
"""
from openai import OpenAI
import sys
import os

# Agregar la ruta del directorio actual para importar auth
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from auth import get_api_key

BASE_URL = "https://api.ai.kodekloud.com/v1"

# CAMBIO CLAVE: Usamos el único modelo que tu API Key tiene autorizado
MODEL_NAME = "kodekey-pro"

def get_client():
    api_key = get_api_key()
    return OpenAI(api_key=api_key, base_url=BASE_URL)

def get_model_name():
    return MODEL_NAME
