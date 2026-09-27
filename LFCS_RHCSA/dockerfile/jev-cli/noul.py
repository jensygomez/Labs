#!/usr/bin/env python3
"""
noul.py - Módulo de validación binaria (Sí/No) para TypeSafe System One.
"""
import json
import copy
from api_client import get_client, get_model_name
from templates import NOUL_TEMPLATE

def run_noul():
    print("\n" + "="*70)
    print(" 🛡️  MÓDULO NOUL: Validación Binaria (Sí/No) Calibrada")
    print("="*70)
    
    # 1. Recolección de variables del usuario
    state = input("\n1️⃣  [CONTEXTO/STATE] El texto o situación a evaluar:\n> ").strip()
    question = input("\n2️⃣  [PREGUNTA] ¿Qué debemos validar? (ej: ¿El mensaje pide credenciales?):\n> ").strip()
    focus = input("\n3️⃣  [ENFOQUE] (Opcional) ¿En qué detalle específico fijarnos?:\n> ").strip() or "Ninguno"
    true_criteria = input("\n4️⃣  [CRITERIO TRUE] ¿Cuándo es SÍ?:\n> ").strip()
    false_criteria = input("\n5️⃣  [CRITERIO FALSE] ¿Cuándo es NO?:\n> ").strip()

    # 2. Construcción del payload usando la plantilla (deepcopy para no modificar la original)
    payload = copy.deepcopy(NOUL_TEMPLATE)
    payload["state"] = state
    payload["questions"]["validation_check"]["instructions"]["question"] = question
    payload["questions"]["validation_check"]["instructions"]["focus"] = focus
    payload["questions"]["validation_check"]["criteria"]["true"] = true_criteria
    payload["questions"]["validation_check"]["criteria"]["false"] = false_criteria

    print(f"\n⏳ Enviando estructura Noul a {get_model_name()}...")
    
    try:
        # 3. Llamada a la API
        client = get_client()
        response = client.chat.completions.create(
            model=get_model_name(),
            messages=[
                {"role": "system", "content": "Eres Jev, un modelo System One. Evalúa el estado y devuelve una decisión calibrada en formato JSON."},
                {"role": "user", "content": json.dumps(payload, indent=2)}
            ],
            temperature=0.0,
            response_format={"type": "json_object"}
        )
        
        # 4. Salida en pantalla
        raw_response = response.choices[0].message.content
        print("\n" + "="*70)
        print(" 📊 RESPUESTA DE JEV (System One)")
        print("="*70)
        
        # Intentamos formatear el JSON para que sea legible
        try:
            parsed = json.loads(raw_response)
            print(json.dumps(parsed, indent=2, ensure_ascii=False))
        except json.JSONDecodeError:
            print(raw_response) # Fallback si la API devuelve texto plano
            
        print("="*70 + "\n")

    except Exception as e:
        print(f"\n❌ Error en la llamada a la API: {e}")
        print("💡 NOTA: Si el error menciona 'kodekey-pro', la plataforma podría estar forzando el uso de su proxy unificado.")
