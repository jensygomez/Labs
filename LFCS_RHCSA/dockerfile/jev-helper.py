#!/usr/bin/env python3
import os
import sys
import json
import re
from openai import OpenAI

# 1. CONFIGURACIÓN DE LA API
API_KEY = os.environ.get("KODEKEY_API_KEY")
BASE_URL = os.environ.get("OPENAI_BASE_URL", "https://api.ai.kodekloud.com/v1")

if not API_KEY:
    print("❌ Error: KODEKEY_API_KEY no está disponible.")
    print("   Ejecuta: export KODEKEY_API_KEY='tu_nueva_clave' en tu host.")
    sys.exit(1)

client = OpenAI(api_key=API_KEY, base_url=BASE_URL)

# Nombre exacto del modelo según la documentación oficial de KodeKey (minúsculas y guiones)
DEFAULT_MODEL = "gpt-6-luna"

# 2. RECOLECCIÓN DE DATOS
def get_user_input():
    print("\n" + "="*70)
    print(" 🤖 JEV HELPER: Preprocesamiento y Generación de IaC")
    print("="*70)
    problem = input("\n1️⃣  [PROBLEMA] Describe el objetivo técnico o tarea:\n> ").strip()
    context = input("\n2️⃣  [CONTEXTO] Restricciones del entorno (OS, rutas, idempotencia, etc.):\n> ").strip()
    options = input("\n3️⃣  [OPCIONES] Alternativas a evaluar (separadas por coma):\n> ").strip()
    
    # Preguntamos el modelo, pero sugerimos el correcto por defecto
    model_input = input(f"\n4️⃣  [MODELO] (Default: {DEFAULT_MODEL}):\n> ").strip()
    model_name = model_input if model_input else DEFAULT_MODEL
    
    return problem, context, options, model_name

# 3. FASE 1: PREPROCESAMIENTO (Análisis)
def analyze_with_jev(problem, context, options, model_name):
    print(f"\n⏳ [{model_name}] Analizando contexto y evaluando opciones...")
    system_prompt = """Eres un motor de análisis técnico especializado en DevOps e IaC.
Devuelve TU RESPUESTA EXCLUSIVAMENTE en formato JSON válido. Sin markdown (```json), sin texto extra.
Estructura JSON exacta:
{
  "analysis": "Breve análisis técnico, identificando riesgos o dependencias clave.",
  "recommended_option": "La mejor opción elegida, con justificación de 1 frase.",
  "optimized_prompt_for_coder": "Prompt altamente detallado y optimizado para un modelo de código. Incluye tarea exacta, contexto depurado, opción elegida y mejores prácticas de seguridad/idempotencia."
}"""
    try:
        response = client.chat.completions.create(
            model=model_name,
            messages=[
                {"role": "system", "content": system_prompt}, 
                {"role": "user", "content": f"PROBLEMA: {problem}\n\nCONTEXTO: {context}\n\nOPCIONES: {options}"}
            ],
            temperature=0.2
        )
        raw_content = response.choices[0].message.content
        clean_json = re.sub(r'^```json\s*', '', raw_content, flags=re.IGNORECASE)
        clean_json = re.sub(r'\s*```$', '', clean_json, flags=re.IGNORECASE)
        return json.loads(clean_json)
    except Exception as e:
        print(f"\n❌ Error en Fase 1: {e}")
        print("💡 NOTA: Si el error dice 'only access models=[kodekey-pro]', tu plan actual requiere usar 'kodekey-pro' como modelo.")
        sys.exit(1)

# 4. FASE 2: GENERACIÓN DE CÓDIGO
def generate_code(optimized_prompt, model_name):
    print(f"\n⏳ [{model_name}] Generando la solución de código final...")
    system_prompt = "Eres un Ingeniero DevOps/SRE Senior experto en IaC (OpenTofu, Ansible, K8s, Incus). Genera código de producción, limpio, seguro e idempotente. Devuelve solo el código y breves comentarios de verificación."
    try:
        response = client.chat.completions.create(
            model=model_name,
            messages=[
                {"role": "system", "content": system_prompt}, 
                {"role": "user", "content": optimized_prompt}
            ],
            temperature=0.1
        )
        return response.choices[0].message.content
    except Exception as e:
        print(f"\n❌ Error en Fase 2: {e}")
        sys.exit(1)

# 5. EJECUCIÓN PRINCIPAL
if __name__ == "__main__":
    problem, context, options, model_name = get_user_input()
    
    # Fase 1
    jev_result = analyze_with_jev(problem, context, options, model_name)
    
    print("\n" + "="*70 + "\n 📊 RESULTADO DEL ANÁLISIS\n" + "="*70)
    print(f"🔍 Análisis: {jev_result['analysis']}")
    print(f"✅ Opción Recomendada: {jev_result['recommended_option']}\n" + "="*70)
    
    # Fase 2
    final_code = generate_code(jev_result['optimized_prompt_for_coder'], model_name)
    
    print("\n" + "="*70 + "\n 💻 CÓDIGO GENERADO\n" + "="*70)
    print(final_code + "\n" + "="*70)
    
    save_option = input("\n¿Deseas guardar este código en un archivo? (s/N): ").strip().lower()
    if save_option == 's':
        filename = input("Nombre del archivo (ej. playbook.yml, main.tf): ").strip() or "output.txt"
        filepath = f"/workspace/{filename}" if not filename.startswith('/') else filename
        with open(filepath, 'w') as f:
            f.write(final_code)
        print(f"✅ Código guardado en {filepath}")
