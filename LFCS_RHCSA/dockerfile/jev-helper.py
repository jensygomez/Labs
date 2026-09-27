#!/usr/bin/env python3
import os
import sys
import json
import re
import stat
from openai import OpenAI

BASE_URL = os.environ.get("OPENAI_BASE_URL", "https://api.ai.kodekloud.com/v1")
TEMP_KEY_FILE = "/tmp/.jev_session_key"

# 1. OBTENER LA API KEY (Entorno -> Archivo Temporal -> Pedir al usuario)
def get_api_key():
    # 1. Intentar leer de variable de entorno
    key = os.environ.get("KODEKEY_API_KEY")
    if key:
        return key
    
    # 2. Intentar leer del archivo temporal de la sesión
    if os.path.exists(TEMP_KEY_FILE):
        with open(TEMP_KEY_FILE, "r") as f:
            return f.read().strip()
    
    # 3. Pedirla al usuario y guardarla temporalmente
    print("\n" + "="*70)
    print(" 🔑 CONFIGURACIÓN DE SESIÓN")
    print("="*70)
    print(" No se encontró una API Key de KodeKloud en esta sesión.")
    print(" (La clave se guardará temporalmente y se eliminará al salir del contenedor).")
    key = input(" Pega tu KODEKEY_API_KEY aquí: ").strip()
    
    if not key:
        print("❌ Error: No se proporcionó una clave. Abortando.")
        sys.exit(1)
        
    # Guardar en /tmp con permisos seguros (solo el dueño puede leerlo)
    with open(TEMP_KEY_FILE, "w") as f:
        f.write(key)
    os.chmod(TEMP_KEY_FILE, stat.S_IREAD | stat.S_IWRITE) # 0600
    
    print("✅ Clave guardada temporalmente para esta sesión.\n")
    return key

API_KEY = get_api_key()
client = OpenAI(api_key=API_KEY, base_url=BASE_URL)

# NOMBRES EXACTOS SEGÚN LA DOCUMENTACIÓN OFICIAL DE KODEKLOUD
MODEL_JEV = "typesafe/jev-1.13.0"
MODEL_CODER = "gpt-6-luna"

# 2. RECOLECCIÓN DE DATOS
def get_user_input():
    print("\n" + "="*70)
    print(" 🤖 JEV HELPER: Preprocesamiento y Generación de IaC")
    print("="*70)
    problem = input("\n1️⃣  [PROBLEMA] Describe el objetivo técnico o tarea:\n> ").strip()
    context = input("\n2️⃣  [CONTEXTO] Restricciones del entorno (OS, rutas, idempotencia, etc.):\n> ").strip()
    options = input("\n3️⃣  [OPCIONES] Alternativas a evaluar (separadas por coma):\n> ").strip()
    return problem, context, options

# 3. FASE 1: PREPROCESAMIENTO (Análisis Estructurado con JEV)
def analyze_with_jev(problem, context, options):
    print(f"\n⏳ [{MODEL_JEV}] Analizando contexto y evaluando opciones (System One Model)...")
    system_prompt = """Eres Jev, un motor de análisis técnico System One especializado en DevOps e IaC.
Devuelve TU RESPUESTA EXCLUSIVAMENTE en formato JSON válido. Sin markdown, sin texto extra.
Estructura JSON exacta:
{
  "analysis": "Breve análisis técnico, identificando riesgos o dependencias clave.",
  "recommended_option": "La mejor opción elegida, con justificación de 1 frase.",
  "optimized_prompt_for_coder": "Prompt altamente detallado y optimizado para un modelo de código. Incluye tarea exacta, contexto depurado, opción elegida y mejores prácticas de seguridad/idempotencia."
}"""
    try:
        response = client.chat.completions.create(
            model=MODEL_JEV,
            messages=[
                {"role": "system", "content": system_prompt}, 
                {"role": "user", "content": f"PROBLEMA: {problem}\n\nCONTEXTO: {context}\n\nOPCIONES: {options}"}
            ],
            temperature=0.1
        )
        raw_content = response.choices[0].message.content
        clean_json = re.sub(r'^```json\s*', '', raw_content, flags=re.IGNORECASE)
        clean_json = re.sub(r'\s*```$', '', clean_json, flags=re.IGNORECASE)
        return json.loads(clean_json)
    except Exception as e:
        print(f"\n❌ Error en Fase 1 (JEV): {e}")
        print("💡 Verifica que tu clave sea válida y tenga acceso a 'typesafe/jev-1.13.0'.")
        # Limpiar la clave temporal si falló por autenticación
        if os.path.exists(TEMP_KEY_FILE):
            os.remove(TEMP_KEY_FILE)
        sys.exit(1)

# 4. FASE 2: GENERACIÓN DE CÓDIGO
def generate_code(optimized_prompt):
    print(f"\n⏳ [{MODEL_CODER}] Generando la solución de código final...")
    system_prompt = "Eres un Ingeniero DevOps/SRE Senior experto en IaC (OpenTofu, Ansible, K8s, Incus). Genera código de producción, limpio, seguro e idempotente. Devuelve solo el código y breves comentarios de verificación."
    try:
        response = client.chat.completions.create(
            model=MODEL_CODER,
            messages=[
                {"role": "system", "content": system_prompt}, 
                {"role": "user", "content": optimized_prompt}
            ],
            temperature=0.1
        )
        return response.choices[0].message.content
    except Exception as e:
        print(f"\n❌ Error en Fase 2 (Código): {e}")
        sys.exit(1)

# 5. EJECUCIÓN PRINCIPAL
if __name__ == "__main__":
    problem, context, options = get_user_input()
    
    # Fase 1
    jev_result = analyze_with_jev(problem, context, options)
    
    print("\n" + "="*70 + "\n 📊 RESULTADO DEL ANÁLISIS DE JEV\n" + "="*70)
    print(f"🔍 Análisis: {jev_result['analysis']}")
    print(f"✅ Opción Recomendada: {jev_result['recommended_option']}\n" + "="*70)
    
    # Fase 2
    final_code = generate_code(jev_result['optimized_prompt_for_coder'])
    
    print("\n" + "="*70 + "\n 💻 CÓDIGO GENERADO\n" + "="*70)
    print(final_code + "\n" + "="*70)
    
    save_option = input("\n¿Deseas guardar este código en un archivo? (s/N): ").strip().lower()
    if save_option == 's':
        filename = input("Nombre del archivo (ej. playbook.yml, main.tf): ").strip() or "output.txt"
        filepath = f"/workspace/{filename}" if not filename.startswith('/') else filename
        with open(filepath, 'w') as f:
            f.write(final_code)
        print(f"✅ Código guardado en {filepath}")
