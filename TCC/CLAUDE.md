# CLAUDE.md — Proyecto TCC (Pós-Graduação Arquitetura e Infraestrutura de TI)

> Este archivo vive en `~/Labs/TCC/CLAUDE.md`. Claude Code lo lee automáticamente
> cuando trabaja dentro de esta carpeta. Complementa (no reemplaza) el `CLAUDE.md`
> general en `~/Labs/CLAUDE.md`.

## 1. Contexto del proyecto

- **Estudiante:** Jensy, NOC L1 en Accenture, en transición hacia Sysadmin Linux (LFCS en curso).
- **Curso:** Pós-Graduação Lato Sensu en Arquitetura e Infraestrutura de TI (EAD), 500h.
- **Entregable:** Trabalho de Conclusão de Curso (TCC), modalidad **Artigo Científico**.
- **Documento fuente de reglas institucionales:** `Instrucciones_para_POS.pdf`
  (ya analizado y resumido en la sección 3 de este archivo — consultar el PDF original
  solo si hay duda sobre un detalle no cubierto aquí).
- **Idioma de redacción final:** Português (Brasil), 3ª persona del singular.
- **Idioma de trabajo/discusión con Claude Code:** Español o Português, como prefiera Jensy.

## 2. Tema, problema y objetivos (estado actual — ajustable con orientador)

- **Tema:** Arquiteturas Orientadas a Microsserviços em Ambientes de Computação em
  Nuvem: uma Revisão Bibliográfica sobre Desafios de Escalabilidade e Resiliência.
- **Problema de pesquisa** (no debe contener la palabra "porque"):
  *De que forma a adoção de arquiteturas baseadas em microsserviços contribui para
  a escalabilidade e a resiliência de infraestruturas em nuvem?*
- **Objetivo geral:** Analisar, por meio de revisão da literatura, os principais
  desafios e benefícios da adoção de arquiteturas de microsserviços em ambientes
  de computação em nuvem.
- **Objetivos específicos:**
  1. Caracterizar os fundamentos teóricos das arquiteturas de microsserviços e sua
     relação com a infraestrutura em nuvem.
  2. Identificar, na literatura, os principais desafios de escalabilidade e
     resiliência reportados na adoção dessas arquiteturas.
  3. Discutir estratégias e padrões arquiteturais propostos na literatura para
     mitigar tais desafios.

Este bloque es el **estado vivo** del proyecto. Cualquier sesión de Claude Code debe
leerlo antes de avanzar, y actualizarlo si Jensy decide ajustar tema/problema/objetivos.
El detalle de avance fino (qué sección está completa, qué referencias ya están
recolectadas) vive en `tcc_state.md`, no aquí.

## 3. Reglas institucionales duras (resumen operativo)

### 3.1 Naturaleza del trabajo — **regla más importante**
- El método es **revisão bibliográfica exclusivamente**.
- **PROHIBIDO**: estudo de caso, pesquisa de campo, relato de experiência.
  Esto significa que el lab Rocky Linux / la experiencia NOC de Jensy **no pueden
  presentarse como evidencia empírica propia** dentro del artículo. Pueden mencionarse
  solo como motivación personal en la introducción, nunca como fuente de datos o resultados.
- El tema **no puede ser** el nombre del curso ni el nombre de una disciplina tal cual.

### 3.2 Formato — Artigo Científico
- Cuerpo textual: **10 a 20 páginas**.
- Referencias bibliográficas: **8 a 15**.
- Texto corrido, **sin** quiebres de página entre secciones.
- Estructura: Título, Autor, Resumo, Palavras-chave → Introdução, Metodologia,
  Resultados e Discussões, Conclusão → Referências.
- Sin sangría de párrafo (a diferencia de la monografía).

### 3.3 Formato gráfico (ABNT)
- Fuente Times New Roman o Arial, 12pt, negro.
- Márgenes: superior 3cm, inferior 2cm, izquierda 3cm, derecha 2cm.
- Interlineado 1,5. Alineación justificada.
- Títulos de sección en MAYÚSCULAS y negrita; subtítulos en negrita con solo la
  primera letra en mayúscula. Numeración secuencial de títulos/subtítulos.
- Paginación en margen inferior derecha.

### 3.4 Citaciones (ABNT NBR 10520)
- Citación corta (≤3 líneas): entre comillas o cursiva, integrada al párrafo,
  con autor-año-página: `(Apellido, año, p. X)` o `Apellido (año, p. X)`.
- Citación larga (>3 líneas): párrafo aparte, sangría 4cm desde margen izquierda,
  espaciado simple, fuente 10.
- Citación de segunda mano: usar "apud".
- Toda citación, larga o corta, **debe** llevar referencia bibliográfica completa
  en la sección final, siguiendo el formato ABNT (autor en MAYÚSCULA, título
  destacado, edición, ciudad, editora, año).

### 3.5 Redacción
- **Siempre 3ª persona del singular.** Nunca "eu", "eu acredito", "na minha experiência".
- Tono académico, objetivo, sin opiniones personales no fundamentadas.

### 3.6 Evaluación (banca examinadora) — pesos para priorizar esfuerzo
| Criterio | Puntos |
|---|---|
| Fundamentação Teórica | 15 |
| Análise e interpretação dos resultados | 10 |
| Objetivos/Problema/Metodologia | 10 |
| Resumo | 10 |
| Introdução | 10 |
| Conclusão | 10 |
| Formatação | 10 |
| Tema/Título | 10 |
| Cantidad de páginas | 5 |
| Citações | 5 |
| Referências | 5 |
| **Mínimo para aprobar** | **70/100** |

→ **Fundamentação Teórica** y **Análise e Interpretação** concentran el mayor peso
(25 de 100 puntos juntos): ahí debe ir el mayor esfuerzo de revisión y argumentación,
no solo de extensión.

## 4. Guardrails — reglas que Claude Code NUNCA debe romper en este proyecto

1. **Nunca inventar referencias bibliográficas.** Toda fuente citada debe ser real,
   verificable y, idealmente, efectivamente leída/revisada por Jensy o localizable en
   Google Acadêmico, Scielo, Portal de Periódicos CAPES o BDTD. Si Claude Code no
   tiene certeza de que una fuente existe con esos datos exactos (autor, año, editora,
   páginas), debe decirlo explícitamente y pedir que Jensy la verifique o la
   reemplace — nunca rellenar con datos plausibles pero no confirmados.
2. **Nunca generar contenido que simule ser un "relato de experiência" o "estudo de
   caso"** del lab personal o del trabajo en Accenture como si fuera evidencia
   empírica del artículo. Si Jensy pide explícitamente incluir su experiencia,
   Claude Code debe recordar la restricción institucional antes de proceder.
3. **Nunca escribir en 1ª persona** en el texto del artículo final.
4. **Nunca exceder ni quedar por debajo de los rangos de página/referencias**
   (10-20 págs., 8-15 refs.) sin avisarlo explícitamente.
5. **Nunca presentar un párrafo como paráfrasis si en realidad es una copia casi
   literal de la fuente** sin comillas y cita — riesgo de plagio, causa de
   reprobación automática según el manual.
6. Antes de marcar cualquier sección como "completa" en `tcc_state.md`, validar
   contra el checklist de la Skill `avanzar-tcc`.

## 5. Estructura de carpetas del proyecto

```
~/Labs/TCC/
├── CLAUDE.md                      (este archivo)
├── Instrucciones_para_POS.pdf     (manual institucional original)
├── tcc_state.md                   (tracker de progreso — fuente de verdad de avance)
├── articulo/
│   └── draft.md                   (borrador vivo del artículo, en Markdown)
├── referencias/
│   └── bibliografia.md            (lista de fuentes reales recolectadas, con
│                                    datos completos ABNT y notas de lectura)
└── .claude/
    └── skills/
        └── avanzar-tcc/
            └── SKILL.md
```

## 6. Flujo de trabajo esperado

Cada vez que Jensy abra una sesión de Claude Code en esta carpeta y diga algo como
"avancemos con el TCC" o invoque la skill `avanzar-tcc`:

1. Leer `tcc_state.md` para saber en qué etapa quedó el trabajo.
2. Continuar desde ahí (ver orden de etapas en `SKILL.md`).
3. Al cerrar la sesión, **siempre** actualizar `tcc_state.md` con lo avanzado,
   lo pendiente, y cualquier duda abierta para la próxima sesión.
4. Mantener el estilo socrático que Jensy prefiere para el aprendizaje técnico
   (preguntas guía antes de soluciones) **excepto** en la redacción final del
   artículo, donde se prioriza producir texto en formato ABNT correcto — ahí
   Claude Code puede proponer texto directamente, pero siempre marcando
   claramente qué partes son borrador para revisión de Jensy vs. texto ya validado.
