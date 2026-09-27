#!/usr/bin/env python3
"""
choice.py - Módulo de elección entre múltiples opciones para TypeSafe System One.
"""
import json
from api_client import get_client, get_model_name


def read_multiline(prompt: str) -> str:
    """Lee varias líneas de texto hasta que el usuario deje una línea vacía."""
    print(prompt)
    lines = []
    while True:
        line = input()
        if line.strip() == "" and lines:
            break
        if line.strip() == "" and not lines:
            # Permite saltar la primera línea vacía sin cortar de inmediato
            continue
        lines.append(line)
    return "\n".join(lines).strip()


def run_choice():
    print("\n" + "="*70)
    print(" 🎯 MÓDULO CHOICE: Elegir la Mejor Opción entre Varias")
    print("="*70)

    state = read_multiline(
        "\n1️⃣  [CONTEXTO/STATE] El texto o situación a evaluar "
        "(termina con una línea vacía):"
    )

    questions_payload = {}
    contador = 1

    while True:
        print(f"\n--- Pregunta Choice #{contador} ---")
        question = input("\n2️⃣  [PREGUNTA] ¿Qué debemos elegir?:\n> ").strip()
        focus = input("\n3️⃣  [ENFOQUE] (Opcional) ¿En qué detalle fijarnos?:\n> ").strip()

        criteria = {}
        print("\n4️⃣  [OPCIONES] Agrega al menos 2 opciones. Escribe 'fin' en el "
              "nombre para terminar.")
        while True:
            nombre = input("\n   Nombre de la opción (o 'fin'): ").strip()
            if nombre.lower() == "fin":
                if len(criteria) < 2:
                    print(f"   ❌ Necesitas al menos 2 opciones (llevas {len(criteria)}). Sigue agregando.")
                    continue
                break
            if not nombre:
                print("   ❌ El nombre no puede estar vacío.")
                continue
            descripcion = input(f"   Descripción de '{nombre}': ").strip()
            criteria[nombre] = descripcion

        id_pregunta = f"selection_{contador}"
        instructions = question if not focus else {"question": question, "focus": focus}

        questions_payload[id_pregunta] = {
            "type": "choice",
            "instructions": instructions,
            "criteria": criteria,
        }

        contador += 1

        otra = input("\n¿Agregar otra pregunta Choice? (y/N): ").strip().lower()
        if otra != "y":
            break

    print(f"\n⏳ Enviando estructura Choice ({len(questions_payload)} pregunta(s)) a {get_model_name()}...")

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

        for id_pregunta in questions_payload:
            data = result[id_pregunta]
            choice_ganador = data["choice"]
            confidence = data.get("confidence")
            probabilities = data.get("probabilities", {})

            print(f"\n🔹 {id_pregunta}")
            print(f"   Opción elegida: {choice_ganador}")
            if confidence is not None:
                print(f"   Confianza: {confidence}")
            if probabilities:
                print("   Probabilidades:")
                for opcion, prob in probabilities.items():
                    print(f"     - {opcion}: {prob}")

        print("\n" + "="*70 + "\n")

    except Exception as e:
        print(f"\n❌ Error en la llamada a la API: {e}")
