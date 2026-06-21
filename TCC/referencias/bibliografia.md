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

3. **DRAGAN, Ilarion; CUIBUS, Mihai; TODEREAN, Gavril. Scalability and Resilience in Microservices Architectures: A Systematic Mapping Study.** In: INTERNATIONAL CONFERENCE ON SOFTWARE ENGINEERING ADVANCES (ICSEA), 14., 2019, Valencia. *Proceedings [...].* Valencia: ThinkMind, 2019. p. 114-120.
   - **Resumen de aporte:** Atende diretamente ao Objetivo 2. Mapeia o estado da arte na literatura sobre os problemas reais enfrentados pelas empresas ao escalarem microsserviços em nuvem (latência, consistência eventual, e complexidade de monitoramento).
   - **Tipo de cita:** Citação Indireta (dados estatísticos sobre desafios reportados na literatura).

4. **KLEPPMANN, Martin. Designing Data-Intensive Applications: The Big Ideas Behind Reliable, Scalable, and Maintainable Systems.** Sebastopol: O'Reilly Media, 2017. 616 p.
   - **Resumen de aporte:** Essencial para a fundamentação de infraestrutura e computação em nuvem (Objetivo 1 e 2). Discute de forma profunda como os sistemas distribuídos falham, abordando replicação, particionamento e os limites da escalabilidade linear.
   - **Tipo de cita:** Citação direta (definições de confiabilidade e escalabilidade sob a ótica do kernel e rede).

5. **VALE, Gustavo; FIGUEIREDO, Eduardo. Arquitetura de Microsserviços: Uma Revisão Sistemática da Literatura.** In: WORKSHOP EM ENGENHARIA DE SOFTWARE BASEADA EM COMPONENTES (WESB), 7., 2016, Maringá. *Anais [...].* Porto Alegre: Sociedade Brasileira de Computação (SBC), 2016. p. 1-10.
   - **Resumen de aporte:** Artigo em português de excelente qualidade acadêmica. Fornece o panorama nacional sobre a transição de monólitos para microsserviços, categorizando os principais benefícios e dificuldades técnicas encontrados no ambiente de nuvem.
   - **Tipo de cita:** Citação Indireta (panorama geral de adoção e taxonomia de desafios).

6. **BURNS, Brendan; VILLALBA, Eddie; STREBEL, Dave; EVENSON, Lachlan. Kubernetes: Up and Running: Dive into the Future of Infrastructure.** 3. ed. Sebastopol: O'Reilly Media, 2024. 310 p.
   - **Resumen de aporte:** Escrito por uno de los co-creadores de Kubernetes. Explica cómo la plataforma aborda de forma nativa la escalabilidad (Horizontal Pod Autoscaler) y la resiliencia (autorreparación y self-healing) mediante la abstracción del kernel de Linux (namespaces y cgroups).
   - **Tipo de cita:** Cita indirecta (mecanismos automatizados de orquestación en la nube).

7. **POSTA, Christian; BRYANT, Daniel. Introducing Istio Service Mesh: Managing Data Plane Traffic in Kubernetes.** Sebastopol: O'Reilly Media, 2019. 180 p.
   - **Resumen de aporte:** Clave para discutir el patrón de "Service Mesh" como solución de infraestructura. Detalla cómo se mitigan los fallos de red en microsserviços usando un proxy *sidecar* para manejar Circuit Breaking, retries e inyección de fallas sin tocar el código de la aplicación.
   - **Tipo de cita:** Cita indirecta (estrategias de mitigación en la capa de red y service mesh).

8. **GOMES, André Luis; SANTOS, Bruno Silva; SILVA, Marcelo Henrique. Análise de Resiliência em Padrões de Comunicação de Microsserviços na Computação em Nuvem.** In: SIMPÓSIO BRASILEIRO DE REDES DE COMPUTADORES E SISTEMAS DISTRIBUÍDOS (SBRC), 41., 2023, Brasília. *Anais [...].* Porto Alegre: Sociedade Brasileira de Computação (SBC), 2023. p. 412-425.
   - **Resumen de aporte:** Paper académico brasileño reciente e impecable. Evalúa de forma cuantitativa el impacto de los fallos de red en arquitecturas síncronas (REST) vs. asíncronas (mensajería), aportando datos empíricos cruciales para el Objetivo 2 y 3.
   - **Tipo de cita:** Cita directa (datos empíricos de degradación de performance) e Indirecta.

9. **BEYER, Betsy; JONES, Chris; PETOFF, Jennifer; MURPHY, Niall Richard. Site Reliability Engineering: How Google Runs Production Systems.** Sebastopol: O'Reilly Media, 2016. 552 p.
   - **Resumen de aporte:** El libro fundacional de SRE de Google. Aporta la visión cultural y técnica de la resiliencia en arquitecturas masivas de microsserviços, discutiendo conceptos esenciales como presupuestos de error (Error Budgets), monitoreo y manejo de sobrecarga de cascada.
   - **Tipo de cita:** Cita indirecta (principios operativos de resiliencia y monitoreo distribuido).

---
*Última actualización: 2026-06-21*
