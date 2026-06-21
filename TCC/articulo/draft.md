# ARQUITETURAS ORIENTADAS A MICROSSERVIÇOS EM AMBIENTES DE COMPUTAÇÃO EM NUVEM: UMA REVISÃO BIBLIOGRÁFICA SOBRE DESAFIOS DE ESCALABILIDADE E RESILIÊNCIA

**Jensy**

## RESUMO
*(O resumo será redigido ao final da construção do corpo textual, conforme as diretrizes metodológicas institucionais, sintetizando os objetivos, a metodologia de revisão e as principais conclusões alcançadas).*

**Palavras-chave:** Microsserviços. Computação em Nuvem. Escalabilidade. Resiliência. Infraestrutura de TI.

---

## 1 INTRODUÇÃO

A evolução histórica da infraestrutura de Tecnologia da Informação (TI) consolidou a computação em nuvem como o paradigma predominante para a sustentação de aplicações corporativas modernas. Esse cenário impôs a necessidade de migração dos antigos modelos de desenvolvimento, caracterizados por arquiteturas monolíticas altamente acopladas, para abordagens mais flexíveis e descentralizadas. Nesse contexto de modernização, as arquiteturas orientadas a microsserviços emergiram como uma solução de engenharia para lidar com a crescente complexidade dos ecossistemas de software distribuídos (NEWMAN, 2021). 

A segmentação de um sistema computacional em serviços granulares independentes e fracamente acoplados alinha-se intrinsecamente com as capacidades elásticas oferecidas pelos provedores de computação em nuvem. Cada componente passa a ser encapsulado de forma isolada, comunicando-se por meio de protocolos de rede padronizados. Todavia, a transição para um ecossistema distribuído transfere a complexidade do código interno da aplicação diretamente para a infraestrutura de rede e para as camadas de gerenciamento da arquitetura (KLEPPMANN, 2017). Fenômenos como latência de comunicação, consistência eventual de dados e falhas parciais passam a figurar como variáveis críticas para os arquitetos de infraestrutura.

A relevância científica e técnica desta discussão reside no fato de que a busca por escalabilidade — a habilidade de um sistema absorver o aumento de carga de trabalho sem degradação de performance — muitas vezes tensiona os mecanismos de resiliência, definidos como a capacidade de a infraestrutura resistir e se recuperar de falhas operacionais involuntárias (BURNS et al., 2024). Quando múltiplos serviços dependem mutuamente uns dos outros através da rede, a falha em um único componente periférico pode deflagrar um efeito cascata que compromete a disponibilidade total da plataforma (BEYER et al., 2016). Portanto, a mitigação de falhas em arquiteturas distribuídas exige abordagens estruturais profundas que transcendem o desenvolvimento de software tradicional, demandando a implementação de padrões arquiteturais resilientes diretamente nas fundações de rede e orquestração.

Diante desse cenário complexo e com base nos mapeamentos sistemáticos da literatura recente, delimita-se o seguinte problema de pesquisa: **De que forma a adoção de arquiteturas baseadas em microsserviços contribui para a escalabilidade e a resiliência de infraestruturas em nuvem?**

Para responder a essa questão, estabeleceu-se como objetivo geral analisar, por meio de revisão da literatura, os principais desafios e benefícios da adoção de arquiteturas de microsserviços em ambientes de computação em nuvem. Para a consecução do objetivo principal, definiram-se os seguintes objetivos específicos:
1. Caracterizar os fundamentos teóricos das arquiteturas de microsserviços e sua relação com a infraestrutura em nuvem.
2. Identificar, na literatura, os principais desafios de escalabilidade e resiliência reportados na adoção dessas arquiteturas.
3. Discutir estratégias e padrões arquiteturais propostos na literatura para mitigar tais desafios.

O presente artigo científico estrutura-se de forma contínua em seções subsequentes que abordam os procedimentos metodológicos utilizados para o levantamento bibliográfico, a fundamentação teórica baseada nas fontes de referência consolidadas, a análise analítica dos resultados e discussões literárias e, por fim, as conclusões que sumarizam as contribuições conceituais obtidas pelo estudo.


## 2 METODOLOGIA

O presente estudo caracteriza-se como uma revisão bibliográfica de natureza qualitativa e caráter exploratório-descritivo, focada na análise do estado da arte das arquiteturas de microsserviços em ambientes de computação em nuvem. A construção da base teórica seguiu um protocolo estruturado de busca e seleção de literatura científica de alta relevância técnica e acadêmica.

Para o levantamento das fontes primárias e secundárias, realizou-se uma busca direcionada em repositórios digitais e bases de dados consagradas, incluindo o Google Acadêmico, a biblioteca digital da Sociedade Brasileira de Computação (SBC), IEEE Xplore e publicações técnicas de referência na área de engenharia de sistemas distribuídos. Foram utilizados descritores de busca nos idiomas português e inglês, combinados por operadores booleanos, tais como: "arquitetura de microsserviços", "cloud computing", "escalabilidade", "resiliência" e "sistemas distribuídos".

Os critérios de inclusão definidos para a seleção do portfólio bibliográfico consideraram: 
1. Livros de fundamentação arquitetural clássicos e consolidados no mercado de TI;
2. Artigos científicos publicados em anais de congressos e simpósios nacionais ou internacionais com avaliação por pares;
3. Literatura técnica de referência originada por pioneiros na engenharia de confiabilidade de sites (SRE).

Foram excluídos da amostragem artigos de opinião sem embasamento acadêmico, postagens informais de blogs e materiais publicitários de fornecedores de nuvem específicos. A partir da aplicação desses filtros, consolidou-se um corpus documental composto por 9 fontes principais, as quais foram submetidas à análise de conteúdo para responder ao problema de pesquisa formulado.
