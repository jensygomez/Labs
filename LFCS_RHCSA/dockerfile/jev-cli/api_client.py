#!/usr/bin/env python3
"""
api_client.py - Cliente de OpenAI para TypeSafe System One.
Cada modelo usa su propia API Key (ver auth.py).
"""
from openai import OpenAI
import sys
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from auth import get_api_key

BASE_URL = "https://api.ai.kodekloud.com/v1"

# Modelo por defecto usado por jev-cli (noul/choice/score)
DEFAULT_MODEL = "kodekey-pro"

def get_client(model_name: str = DEFAULT_MODEL) -> OpenAI:
    """Cliente OpenAI autenticado con la API Key propia de `model_name`."""
    api_key = get_api_key(model_name)
    return OpenAI(api_key=api_key, base_url=BASE_URL)

def get_model_name() -> str:
    return DEFAULT_MODEL
