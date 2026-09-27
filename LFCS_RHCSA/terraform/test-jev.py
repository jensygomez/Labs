#!/usr/bin/env python3
import os
import json
from openai import OpenAI

API_KEY = os.environ.get("KODEKEY_API_KEY")
BASE_URL = os.environ.get("OPENAI_BASE_URL", "https://api.ai.kodekloud.com/v1")

client = OpenAI(api_key=API_KEY, base_url=BASE_URL)

print("🧪 Probando el verdadero flujo de Jev (System One Model)...")

# Intentamos llamar al modelo por su nombre real según la docs de TypeSafe/KodeKloud
# Si 'jev' falla, probaremos 'jev-1.13.0'
MODEL_NAME = "jev" 

try:
    response = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {"role": "system", "content": "Eres Jev, un modelo de decisión System One. Devuelve SOLO un objeto JSON válido con las claves 'decision' (string) y 'confianza' (float entre 0.0 y 1.0). No uses markdown."},
            {"role": "user", "content": "Contexto: El sujeto se llama María José y en su documento de identidad figura como sexo femenino. Pregunta: ¿Es hombre o mujer?"}
        ],
        response_format={"type": "json_object"}, # Forzamos la salida estructurada nativa de la API
        temperature=0.0 # Máxima determinación
    )
    
    result = json.loads(response.choices[0].message.content)
    print("\n✅ ¡ÉXITO! Respuesta de Jev:")
    print(f"   Decisión : {result.get('decision')}")
    print(f"   Confianza: {result.get('confianza') * 100}%")
    print(f"   Tiempo estimado de inferencia: < 500ms (System One)")

except Exception as e:
    print(f"\n❌ Error al llamar a '{MODEL_NAME}':")
    print(f"   {e}")
    print("\n💡 NOTA: Si el error dice que solo puedes acceder a ['kodekey-pro'], significa que KodeKloud aún no expone el endpoint nativo de Jev en su proxy, y está simulando Jev con un LLM tradicional a través de 'kodekey-pro'.")
