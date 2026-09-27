#!/usr/bin/env python3
"""
templates.py - Plantillas JSON inmutables para TypeSafe System One Models.
Cada módulo (noul, choice, score) usa estas plantillas y las rellena con datos del usuario.
"""

# ==========================================
# PLANTILLA NOUL: Validación Binaria (Sí/No)
# ==========================================
NOUL_TEMPLATE = {
    "state": "",  # Se rellena con el contexto del usuario
    "questions": {
        "validation_check": {
            "type": "noul",
            "instructions": {
                "question": "",  # Se rellena con la pregunta del usuario
                "focus": ""      # Se rellena con el enfoque del usuario
            },
            "criteria": {
                "true": "",   # Se rellena con el criterio TRUE del usuario
                "false": ""   # Se rellena con el criterio FALSE del usuario
            }
        }
    }
}

# ==========================================
# PLANTILLA CHOICE: Elegir entre opciones
# ==========================================
CHOICE_TEMPLATE = {
    "state": "",  # Se rellena con el contexto del usuario
    "questions": {
        "selection": {
            "type": "choice",
            "instructions": {
                "question": "",  # Se rellena con la pregunta del usuario
                "focus": ""      # Se rellena con el enfoque del usuario
            },
            "criteria": {}  # Se rellena con las opciones del usuario (diccionario)
        }
    }
}

# ==========================================
# PLANTILLA SCORE: Evaluar en escala
# ==========================================
SCORE_TEMPLATE = {
    "state": "",  # Se rellena con el contexto del usuario
    "questions": {
        "evaluation": {
            "type": "score",
            "instructions": {
                "question": "",  # Se rellena con la pregunta del usuario
                "focus": ""      # Se rellena con el enfoque del usuario
            },
            "criteria": []  # Se rellena con los niveles de la escala (lista)
        }
    }
}
