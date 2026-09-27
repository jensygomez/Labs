#!/usr/bin/env python3
"""
noul.py - Módulo de validación binaria (Sí/No) para TypeSafe System One.
"""
import json
from api_client import get_client, get_model_name

def read_multiline(prompt: str) -> str:
    """Lee texto multilínea (útil para pegar tickets/logs largos).
    Termina al encontrar una línea vacía."""
    print(prompt)
    print(" (Pega tu texto. Cuando termines, presiona Enter en una línea vacía)")
    lines = []
    while True:
        try:
            line = input("> " if not lines else "  ")
        except EOFError:
            break
        if line == "":
            break
        lines.append(line)
    return "\n".join(lines)

def run_noul():
    print("\n" + "="*70)
    print(" 🛡️  MÓDULO NOUL: Validación Binaria (Sí/No) Calibrada")
    print("="*70)

    state = read_multiline("\n1️⃣  [CONTEXTO/STATE] El texto o situación a evaluar:").strip()
    question = input("\n2️⃣  [PREGUNTA] ¿Qué debemos validar? (ej: ¿El mensaje pide credenciales?):\n> ").strip()
    focus = input("\n3️⃣  [ENFOQUE] (Opcional) ¿En qué detalle específico fijarnos?:\n> ").strip()
    true_criteria = input("\n4️⃣  [CRITERIO TRUE] ¿Cuándo es SÍ?:\n> ").strip()
    false_criteria = input("\n5️⃣  [CRITERIO FALSE] ¿Cuándo es NO?:\n> ").strip()

    instructions = question if not focus else {"question": question, "focus": focus}

    questions_payload = {
        "validation_check": {
            "type": "noul",
            "instructions": instructions,
            "criteria": {"true": true_criteria, "false": false_criteria},
        }
    }

    print(f"\n⏳ Enviando estructura Noul a {get_model_name()}...")

    try:
        client = get_client()
        response = client.chat.completions.create(
            model=get_model_name(),
            messages=[
                {"role": "user", "content": state}
            ],
            extra_body={
                "response_format": {
                    "type": "questions",
                    "questions": questions_payload,
                }
            },
        )

        raw_content = response.choices[0].message.content
        result = json.loads(raw_content)

        print("\n" + "="*70)
        print(" 📊 RESPUESTA DE JEV (System One)")
        print("="*70)

        noul_value = result["validation_check"]["noul"]
        print(f" Probabilidad (0=No, 1=Sí): {noul_value}")
        print(f" Decisión: {'✅ SÍ' if noul_value > 0.5 else '❌ NO'}")
        print("="*70 + "\n")

    except Exception as e:
        print(f"\n❌ Error en la llamada a la API: {e}")
