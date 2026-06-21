---
name: avanzar-tcc
description: >
  Usar esta skill cuando Jensy pida avanzar, continuar, revisar o trabajar en el
  TCC (artículo científico de la Pós-Graduação en Arquitetura e Infraestrutura de TI).
  Disparadores: "avancemos con el TCC", "sigamos con el artículo", "revisa el TCC",
  "qué falta del TCC", o cualquier referencia a tcc_state.md, draft.md o
  bibliografia.md dentro de ~/Labs/TCC/.
---

# Skill: avanzar-tcc

## Propósito
Continuar la redacción del artículo científico del TCC de forma incremental,
sesión tras sesión, sin perder contexto y sin violar las reglas institucionales
fijadas en `CLAUDE.md`.

## Paso 0 — Siempre al inicio
1. Leer `~/Labs/TCC/CLAUDE.md` (reglas y contexto fijo del proyecto).
2. Leer `~/Labs/TCC/tcc_state.md` (en qué etapa quedó el trabajo).
3. Anunciar a Jensy en una línea: "Estamos en la etapa X, lo último completado fue Y,
   lo pendiente es Z" — antes de proponer cualquier contenido nuevo.

## Orden de etapas (artículo científico)

1. **Tema, problema, justificativa, objetivos** — cerrar la versión final (la
   inicial está en CLAUDE.md §2, puede refinarse aquí).
2. **Recolección de fuentes** — construir `referencias/bibliografia.md` con
   8-15 fuentes reales (mínimo razonable: empezar a buscar desde 10-12 para
   tener margen). Cada entrada debe incluir: referencia completa en formato
   ABNT, 2-3 líneas de resumen de lo que aporta, y si es citación directa
   potencial o solo apoyo conceptual.
3. **Resumo + Palavras-chave** (se escriben al final, pero se dejan reservados aquí).
4. **Introdução** — contextualización, problema, justificativa, objetivos,
   estructura del artículo.
5. **Metodologia** — describir explícitamente que es revisão bibliográfica:
   bases consultadas (Google Acadêmico, Scielo, Portal CAPES, BDTD), criterios
   de inclusión/exclusión de fuentes, periodo considerado.
6. **Resultados e Discussões** — síntesis crítica y comparativa de lo que dicen
   las fuentes sobre microsserviços, escalabilidade, resiliência — NUNCA datos
   propios del lab o de Accenture como evidencia.
7. **Conclusão** — retomar objetivos, responder el problema de pesquisa,
   limitaciones, sugerencias para trabajos futuros.
8. **Referências** — lista final en ABNT, verificada contra `bibliografia.md`.
9. **Revisión global ABNT** — formato, 3ª persona, rango de páginas (10-20),
   rango de referencias (8-15), citaciones bien formateadas.

No es obligatorio avanzar en este orden estricto si Jensy prefiere otro, pero
sí es obligatorio que cada etapa pase el checklist antes de marcarse "completa".

## Checklist de validación por sección (antes de marcar como completa en tcc_state.md)

- [ ] Redactado en 3ª persona del singular (cero "eu", "minha experiência", etc.)
- [ ] Toda afirmación con respaldo de fuente real lleva cita ABNT correcta
- [ ] Ninguna fuente citada es inventada o no verificada — si hay duda, se marca
      explícitamente como `[VERIFICAR FUENTE]` en el draft, nunca se presenta como segura
- [ ] No hay relato de experiencia personal ni estudio de caso presentado como evidencia
- [ ] Paráfrasis genuina, no copia casi literal sin comillas
- [ ] Formato: fuente 12, interlineado 1,5, justificado, sin sangría (es artículo)
- [ ] Títulos en MAYÚSCULA y negrita

## Al cerrar la sesión
Actualizar `tcc_state.md` con:
- Qué se completó en esta sesión
- Qué quedó a medias (con el punto exacto donde se cortó)
- Dudas abiertas para la próxima sesión o para el orientador
- Conteo actual de páginas y de referencias acumuladas

## Notas de estilo de interacción
- Discutir en español/português, como Jensy prefiera en el momento.
- Para contenido del artículo: proponer texto en português, marcado como borrador,
  y esperar validación antes de darlo por definitivo.
- Para decisiones estructurales (tema, alcance, enfoque): mantener el estilo
  socrático — preguntar antes de imponer, dado que es el estilo de aprendizaje
  preferido por Jensy en otros contextos del lab.
