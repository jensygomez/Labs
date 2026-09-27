#!/usr/bin/env python3
import os
import sys
import json
import re
from openai import OpenAI

# 1. CONFIGURACIÓN DE LA API (KodeKey)
API_KEY = os.environ.get("KODEKEY_API_KEY")
BASE_URL = os.environ.get("OPENAI_BASE_URL", "https://api.ai.kodekloud.com/v1")

if not API_KEY:
    print("❌ Error: La variable KODEKEY_API_KEY no está disponible en el contenedor.")
    sys.exit(1)

client = OpenAI(api_key=API_KEY, base_url=BASE_URL)

# 2. RECOLECCIÓN DE DATOS INTERACTIVA
def get_user_input():
    print("\n" + "="*70)
    print(" 🤖 JEV HELPER: Preprocesamiento y Generación de IaC")
    print("="*70)
    problem = input("\n1️⃣  [PROBLEMA] Describe el objetivo técnico o tarea:\n> ").strip()
    context = input("\n2️⃣  [CONTEXTO] Restricciones del entorno (ej. rutas, OS, versiones):\n> ").strip()
    options = input("\n3️⃣  [OPCIONES] Caminos o alternativas a evaluar (separados por coma):\n> ").strip()
    coding_model = input("\n4️⃣  [MODELO DE CÓDIGO] (ej. GPT-6 Luna, Claude Sonnet 5) [Default: GPT-6 Luna]:\n> ").strip() or "GPT-6 Luna"
    return problem, context, options, coding_model

# 3. FASE 1: PREPROCESAMIENTO CON JEV
def analyze_with_jev(problem, context, options):
    print("\n⏳ [JEV 1.13.0] Analizando contexto masivo y evaluando opciones...")
    system_prompt = """Eres JEV, un motor de análisis técnico especializado en DevOps e IaC.
Devuelve TU RESPUESTA EXCLUSIVAMENTE en formato JSON válido. Sin markdown (```json), sin texto extra.
Estructura JSON exacta:
{
  "analysis": "Breve análisis técnico, identificando riesgos o dependencias clave.",
  "recommended_option": "La mejor opción elegida, con justificación de 1 frase.",
  "optimized_prompt_for_coder": "Prompt altamente detallado y optimizado, listo para un modelo de código. Incluye tarea exacta, contexto depurado, opción elegida y mejores prácticas de seguridad/idempotencia."
}"""
    try:
        response = client.chat.completions.create(
            model="Jev 1.13.0",
            messages=[{"role": "system", "content": system_prompt}, {"role": "user", "content": f"PROBLEMA: {problem}\n\nCONTEXTO: {context}\n\nOPCIONES: {options}"}],
            temperature=0.2
        )
        raw_content = response.choices[0].message.content
        clean_json = re.sub(r'^```json\s*', '', raw_content, flags=re.IGNORECASE)
        clean_json = re.sub(r'\s*```$', '', clean_json, flags=re.IGNORECASE)
        return json.loads(clean_json)
    except Exception as e:
        print(f"\n❌ Error en JEV: {e}\nRespuesta cruda: {raw_content if 'raw_content' in locals() else 'N/A'}")
        sys.exit(1)

# 4. FASE 2: GENERACIÓN DE CÓDIGO
def generate_code(optimized_prompt, model_name):
    print(f"\n⏳ [{model_name}] Generando la solución de código final...")
    system_prompt = "Eres un Ingeniero DevOps/SRE Senior experto en IaC (OpenTofu, Ansible, K8s, Incus). Genera código de producción, limpio, seguro e idempotente. Devuelve solo el código y breves comentarios de verificación."
    try:
        response = client.chat.completions.create(
            model=model_name,
            messages=[{"role": "system", "content": system_prompt}, {"role": "user", "content": optimized_prompt}],
            temperature=0.1
        )
        return response.choices[0].message.content
    except Exception as e:
        print(f"\n❌ Error en generación de código: {e}")
        sys.exit(1)

# 5. EJECUCIÓN PRINCIPAL
if __name__ == "__main__":
    problem, context, options, coding_model = get_user_input()
    jev_result = analyze_with_jev(problem, context, options)
    
    print("\n" + "="*70 + "\n 📊 RESULTADO DEL ANÁLISIS DE JEV\n" + "="*70)
    print(f"🔍 Análisis: {jev_result['analysis']}")
    print(f"✅ Opción Recomendada: {jev_result['recommended_option']}\n" + "="*70)
    
    final_code = generate_code(jev_result['optimized_prompt_for_coder'], coding_model)
    
    print("\n" + "="*70 + "\n 💻 CÓDIGO GENERADO\n" + "="*70)
    print(final_code + "\n" + "="*70)
    
    save_option = input("\n¿Deseas guardar este código en un archivo? (s/N): ").strip().lower()
    if save_option == 's':
        filename = input("Nombre del archivo (ej. playbook.yml, main.tf): ").strip() or "output.txt"
        filepath = f"/workspace/{filename}" if not filename.startswith('/') else filename
        with open(filepath, 'w') as f:
            f.write(final_code)
        print(f"✅ Código guardado en {filepath}")
