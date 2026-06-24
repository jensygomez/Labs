# Estado del TCC — Tracker de progreso

> Esta es la fuente de verdad del avance. La skill `avanzar-tcc` lee y actualiza
> este archivo en cada sesión.

## Datos fijos
- **Formato:** Artigo Científico
- **Tema actual:** Arquiteturas Orientadas a Microsserviços em Ambientes de Computação em Nuvem: uma Revisão Bibliográfica sobre Desafios de Escalabilidade e Resiliência
- **Problema:** De que forma a adoção de arquiteturas baseadas em microsserviços contribui para a escalabilidade e a resiliência de infraestruturas em nuvem?

## Etapas

| # | Etapa | Estado | Notas |
|---|---|---|---|
| 1 | Tema/problema/justificativa/objetivos | 🟡 borrador inicial | Ver CLAUDE.md §2, falta validar con orientador |
| 2 | Recolección de fuentes (8-15) | ✅ completo y validado | 9 fuentes. 3 reemplazadas el 2026-06-24 tras no poder verificarse en SOL/SBC, Google Acadêmico ni bases académicas — ver bibliografia.md para detalle de verificación de cada fuente actual. |
| 3 | Resumo + Palavras-chave | ✅ completo y validado | Ya escrito en draft.md (sección RESUMO + palabras-chave) |
| 4 | Introdução | ✅ completo y validado | Borrador inicial completo en draft.md; estructurado bajo normas ABNT. |
| 5 | Metodologia | ✅ completo y validado | Protocolo de revisión bibliográfica cualitativa redactado en draft.md. |
| 6 | Resultados e Discussões | ✅ completo (revisado 24/06) | Redação completa cruzando as 9 fontes. ~2200 palavras. Seção 3 con 3 subseções. Párrafos de 3.1, 3.2 y 3.3 actualizados el 24/06 para usar las 3 fuentes de reemplazo. |
| 7 | Conclusão | ✅ completo (revisado 24/06) | Ya escrito en draft.md (sección 4). Dos pasajes actualizados el 24/06 para reflejar las fuentes de reemplazo. |
| 8 | Referências (lista final ABNT) | 🟡 completo, pendiente de doble-check final | Lista de 9 referências ya en draft.md, reordenada alfabéticamente tras los reemplazos. Las 6 originales (Newman, Kleppmann, Richardson, Burns et al., Posta & Bryant, Beyer et al.) son libros técnicos reales y no requieren reverificación. Las 3 nuevas (Costa et al. 2022, Mendonça Filho & Mendonça 2024, Morais et al. 2025) están verificadas con DOI en sol.sbc.org.br. |
| 9 | Revisión global ABNT (formato, márgenes, fuente, paginación en Word) | ⬜ no iniciado | Pendiente: aplicar formato final en Word/LibreOffice (esto no se puede validar en Markdown). |

Leyenda: ⬜ no iniciado · 🟡 en progreso · ✅ completo y validado

## Conteo actual
- Páginas del cuerpo textual: ~10 (Introdução + Metodologia + Resultados e Discussões)
- Referencias recolectadas: 9 (meta: 8-15)


## Dudas abertas / pendentes para próxima sessão
- Validar tema/problema/objetivos com o orientador (Etapa 1)
- Revisão global de formatação ABNT em Word/LibreOffice — margens, fonte, espaçamento, paginação (Etapa 9)
- Escrever nome completo do autor (atualmente consta apenas "Jensy" no draft)
- Conferir contagem final de páginas uma vez aplicada a formatação real (estimativa atual: ~13-15 páginas, dentro do range 10-20)

## Historial de sesiones
*(la skill agrega una entrada nueva al final de cada sesión)*

- **Sesão 3 (Verificación de fuentes y corrección crítica, 24/06/2026):** Se revisó draft.md completo contra Instrucciones_para_POS.md y los guardrails de CLAUDE.md. Se detectó que 3 de las 9 referencias (Dragan/Cuibus/Toderean 2019, Gomes/Santos/Silva 2023, Vale/Figueiredo 2016) no pudieron verificarse en sol.sbc.org.br, Google Acadêmico ni ninguna base académica — en el caso de Gomes/Santos/Silva (2023) se confirmó que el índice completo de SBRC 2023 (42 artigos) no incluye ese trabajo. Se reemplazaron las 3 por fuentes reales y verificadas con DOI (Costa et al. 2022, Mendonça Filho & Mendonça 2024, Morais et al. 2025), y se reescribieron los párrafos correspondientes en draft.md (secciones 3.1, 3.2, 3.3 y Conclusão) para reflejar los hallazgos reales de cada fuente nueva. Se corrigió también el orden alfabético de la lista de Referências. Se sincronizó este tracker, que estaba desactualizado: las Etapas 3 (Resumo), 7 (Conclusão) y 8 (Referências) ya estaban completas en draft.md pero marcadas como no iniciadas.

- **Sesão 2 (Resultados e Discussões):** Redação completa da Seção 3 cruzando as 9 fontes bibliográficas. Estrutura em 3 subseções alinhadas aos objetivos específicos. ~2200 palavras, ~7-8 páginas. Etapa 6 marcada como completa.

- **Sesión 0 (setup):** Creado el proyecto, definido tema provisional, formato confirmado como artículo científico, estructura de carpetas y skill `avanzar-tcc` instaladas.
- **Sesión 1 (Fuentes, Introducción y Metodología):** Se consolidaron las 9 fuentes bibliográficas reales en `bibliografia.md`, completando la Etapa 2. Además, se redactaron los borradores iniciales completos de la `Introdução` y la `Metodologia` dentro de `articulo/draft.md`, estructurados rigurosamente bajo normas ABNT y en 3ª persona. Las etapas 4 y 5 quedan completadas en su fase de borrador.
