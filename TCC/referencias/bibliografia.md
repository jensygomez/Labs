# Bibliografía — Fuentes para el TCC

> Archivo de trabajo para Jensy. Agregar aquí las fuentes encontradas manualmente.
> Formato: ABNT completo + 2-3 líneas de resumen de aporte + tipo de cita.

---

## Fuentes recolectadas

1. **NEWMAN, Sam. Building Microservices: Designing Fine-Grained Systems.** 2. ed. Sebastopol: O'Reilly Media, 2021. 612 p.
   - **Resumen de aporte:** É a bíblia técnica dos microsserviços. O autor detalha os fundamentos teóricos (Objetivo 1), modelagem de domínios, e aborda diretamente os desafios de resiliência e comunicação de rede entre serviços integrados.
   - **Tipo de cita:** Citação direta (conceitos de baixo acoplamento) e Indireta (estratégias de decomposição).

2. **RICHARDSON, Chris. Microservices Patterns: With examples in Java.** Shelter Island: Manning Publications, 2018. 520 p.
   - **Resumen de aporte:** Foco total no Objetivo 3. Apresenta os padrões arquiteturais de mitigação de falhas cruciais para a resiliência em nuvem, como *Circuit Breaker*, *Saga Pattern*, *CQRS* e *API Gateway*.
   - **Tipo de cita:** Citação Indireta (aplicação de padrões de design para tolerância a falhas).

3. **MENDONÇA FILHO, Ricardo César; MENDONÇA, Nabor C. Impacto de Desempenho da Granularidade de Microsserviços: Uma Avaliação com o Arcabouço Service Weaver.** In: SIMPÓSIO BRASILEIRO DE REDES DE COMPUTADORES E SISTEMAS DISTRIBUÍDOS (SBRC), 42., 2024, Niterói/RJ. *Anais [...].* Porto Alegre: Sociedade Brasileira de Computação (SBC), 2024. p. 644-657. DOI: 10.5753/sbrc.2024.1453.
   - **Resumen de aporte:** Atende diretamente ao Objetivo 2. Avalia experimentalmente, com o arcabouço Service Weaver, como o desacoplamento de serviços em diferentes granularidades aumenta a sobrecarga de comunicação entre processos e máquinas virtuais, afetando negativamente desempenho e escalabilidade — evidência real de que a decomposição em microsserviços não garante por si só ganhos de escalabilidade.
   - **Tipo de cita:** Citação Indireta (resultado experimental sobre granularidade e overhead de comunicação).
   - **Verificado:** sol.sbc.org.br/index.php/sbrc/article/view/29825 (reemplaza referencia anterior no verificable de Dragan/Cuibus/Toderean).

4. **KLEPPMANN, Martin. Designing Data-Intensive Applications: The Big Ideas Behind Reliable, Scalable, and Maintainable Systems.** Sebastopol: O'Reilly Media, 2017. 616 p.
   - **Resumen de aporte:** Essencial para a fundamentação de infraestrutura e computação em nuvem (Objetivo 1 e 2). Discute de forma profunda como os sistemas distribuídos falham, abordando replicação, particionamento e os limites da escalabilidade linear.
   - **Tipo de cita:** Citação direta (definições de confiabilidade e escalabilidade sob a ótica do kernel e rede).

5. **MORAIS, Larissa Zanata; CORDEIRO, André F. R.; OLIVEIRAJR, Edson. Arquitetura de Microsserviços: Uma Revisão Multivocal.** In: ESCOLA REGIONAL DE ENGENHARIA DE SOFTWARE (ERES), 9., 2025, Chapecó/SC. *Anais [...].* Porto Alegre: Sociedade Brasileira de Computação (SBC), 2025. p. 21-30. DOI: 10.5753/eres.2025.16759.
   - **Resumen de aporte:** Revisão multivocal recente e em português. Fornece panorama nacional/atual sobre arquitetura de microsserviços, mapeando principais tópicos, desafios, tecnologias empregadas e oportunidades de pesquisa — substitui o panorama nacional que se buscava com a fonte anterior.
   - **Tipo de cita:** Citação Indireta (panorama geral de adoção e taxonomia de desafios).
   - **Verificado:** sol.sbc.org.br/index.php/eres/article/view/40375 (reemplaza referencia anterior no verificable de Vale/Figueiredo, WESB 2016).

6. **BURNS, Brendan; VILLALBA, Eddie; STREBEL, Dave; EVENSON, Lachlan. Kubernetes: Up and Running: Dive into the Future of Infrastructure.** 3. ed. Sebastopol: O'Reilly Media, 2024. 310 p.
   - **Resumen de aporte:** Escrito por uno de los co-creadores de Kubernetes. Explica cómo la plataforma aborda de forma nativa la escalabilidad (Horizontal Pod Autoscaler) y la resiliencia (autorreparación y self-healing) mediante la abstracción del kernel de Linux (namespaces y cgroups).
   - **Tipo de cita:** Cita indirecta (mecanismos automatizados de orquestación en la nube).

7. **POSTA, Christian; BRYANT, Daniel. Introducing Istio Service Mesh: Managing Data Plane Traffic in Kubernetes.** Sebastopol: O'Reilly Media, 2019. 180 p.
   - **Resumen de aporte:** Clave para discutir el patrón de "Service Mesh" como solución de infraestructura. Detalla cómo se mitigan los fallos de red en microsserviços usando un proxy *sidecar* para manejar Circuit Breaking, retries e inyección de fallas sin tocar el código de la aplicación.
   - **Tipo de cita:** Cita indirecta (estrategias de mitigación en la capa de red y service mesh).

8. **COSTA, Thiago M.; VASCONCELOS, Davi M.; ADERALDO, Carlos M.; MENDONÇA, Nabor C. Avaliação de Desempenho de Dois Padrões de Resiliência para Microsserviços: Retry e Circuit Breaker.** In: SIMPÓSIO BRASILEIRO DE REDES DE COMPUTADORES E SISTEMAS DISTRIBUÍDOS (SBRC), 40., 2022, Fortaleza/CE. *Anais [...].* Porto Alegre: Sociedade Brasileira de Computação (SBC), 2022. p. 517-530. DOI: 10.5753/sbrc.2022.222363.
   - **Resumen de aporte:** Paper acadêmico brasileiro real e verificado. Avalia experimentalmente o impacto de desempenho dos padrões de resiliência Retry e Circuit Breaker (via Polly/C# e Resilience4j/Java), mostrando que Retry reduz mais eficazmente a contenção por recursos externos, com impacto leve a moderado no tempo de execução — dado empírico real para os Objetivos 2 e 3.
   - **Tipo de cita:** Citação Indireta (dados empíricos de desempenho de padrões de resiliência).
   - **Verificado:** sol.sbc.org.br/index.php/sbrc/article/view/21194 (reemplaza referencia anterior no verificable de Gomes/Santos/Silva).

9. **BEYER, Betsy; JONES, Chris; PETOFF, Jennifer; MURPHY, Niall Richard. Site Reliability Engineering: How Google Runs Production Systems.** Sebastopol: O'Reilly Media, 2016. 552 p.
   - **Resumen de aporte:** El libro fundacional de SRE de Google. Aporta la visión cultural y técnica de la resiliencia en arquitecturas masivas de microsserviços, discutiendo conceptos esenciales como presupuestos de error (Error Budgets), monitoreo y manejo de sobrecarga de cascada.
   - **Tipo de cita:** Cita indirecta (principios operativos de resiliencia y monitoreo distribuido).

---
*Última actualización: 2026-06-24 — 3 referências substituídas após verificação em sol.sbc.org.br (ver detalhe em cada entrada).*
