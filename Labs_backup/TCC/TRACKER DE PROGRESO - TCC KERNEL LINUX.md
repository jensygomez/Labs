

## [cite_start]1. ELEMENTOS PRÉ-TEXTUAIS [cite: 121]
- [ ] [cite_start]Título Geral (Consistente e em maiúsculas) [cite: 100, 122, 245]
- [ ] [cite_start]Nome do Autor [cite: 123]
- [ ] [cite_start]RESUMO (Escrever por último. Máx 1 parágrafo: intro, desenvolvimento e conclusão) [cite: 111, 246]
- [ ] [cite_start]PALAVRAS-CHAVE (3 a 5 termos técnicos) [cite: 125]

---

## [cite_start]2. INTRODUÇÃO [cite: 127] (Meta: 1.5 a 2 páginas)
- [ ] Contextualização: O papel do Kernel Linux na infraestrutura de TI moderna.
- [ ] [cite_start]Justificativa: A importância do isolamento nativo para mitigar vulnerabilidades e ataques de negação de serviço (DoS)[cite: 59, 60].
- [ ] Problema de Pesquisa (Grande Pergunta): 
      "Como as estruturas nativas de Namespaces, Control Groups (Cgroups) e Netfilter atuam de forma integrada na arquitetura do Kernel Linux para garantir o isolamento e o endurecimento de recursos em ambientes virtualizados?" 
      [cite_start]*(Nota: Sem usar a palavra "Por que")* [cite: 56, 58]
- [ ] [cite_start]Objetivos Gerais e Específicos: Definir claramente as metas de análise teórica[cite: 248].
- [ ] [cite_start]Hipóteses: A configuração nativa e cirúrgica do Kernel substitui com maior eficiência determinística ferramentas automatizadas de terceiros[cite: 248].

---

## [cite_start]3. METODOLOGIA [cite: 128] (Meta: 0.5 a 1 página)
- [ ] [cite_start]Classificação da Pesquisa: Qualitativa, exploratória e de caráter puramente bibliográfico[cite: 45, 68].
- [ ] [cite_start]Fontes de Dados: Levantamento em bases científicas (Google Acadêmico, SciELO, CAPES)[cite: 69, 70, 71, 73].
- [ ] Critérios de Seleção: Artigos, livros técnicos consagrados (ex: Brian Ward) e documentação oficial do Kernel Linux de 2020 a 2026.

---

## [cite_start]4. REVISÃO DA LITERATURA / FUNDAMENTAÇÃO TEÓRICA [cite: 113, 126] (Meta: 5 a 8 páginas)
[cite_start]*(Esta seção será dividida em subcapítulos para manter a sequência lógica [cite: 251])*

### 4.1 ARQUITETURA DO KERNEL E ISOLAMENTO ESPACIAL (NAMESPACES)
- [ ] Conceito de Namespaces (PID, NET, MNT, IPC, UTS, USER).
- [ ] Mecânica de funcionamento no espaço de usuário versus espaço de kernel.

### 4.2 CONTROLE E RESTRIÇÃO DE RECURSOS (CGROUPS)
- [ ] Arquitetura do Cgroups V1 vs Cgroups V2 no gerenciamento de CPU, Memória e I/O.
- [ ] Prevenção de exaustão de recursos (Fork Bombs e vazamento de memória virtual).

### 4.3 ENDURECIMENTO DA CAMADA DE REDE (NETFILTER E NFTABLES)
- [ ] Subsistema Netfilter dentro do Kernel.
- [ ] Transição da arquitetura clássica de Iptables para a eficiência determinística de Nftables.

---

## [cite_start]5. RESULTADOS E DISCUSSÕES [cite: 129] (Meta: 2 a 3 páginas)
- [ ] Análise comparativa do impacto de configurações nativas (artesanais) versus o uso de instaladores automatizados opacos.
- [ ] Cruzamento de dados de autores: Como a literatura valida o isolamento do Kernel sob a filosofia UNIX (onde falhas derivam de má configuração e não da imprevisibilidade do sistema).
- [ ] [cite_start]Validação das hipóteses propostas na introdução[cite: 258].

---

## [cite_start]6. CONCLUSÃO [cite: 130] (Meta: 1 página)
- [ ] [cite_start]Síntese dos achados teóricos principais[cite: 256].
- [ ] [cite_start]Resposta direta ao Problema de Pesquisa[cite: 256].
- [ ] Limitações do estudo e sugestões para futuras investigações (ex: o impacto de eBPF na segurança do Kernel).

---

## [cite_start]7. ELEMENTOS PÓS-TEXTUAIS [cite: 131]
- [ ] [cite_start]REFERÊNCIAS (Mínimo 8, máximo 15 fontes no formato estrito ABNT detalhado no manual)[cite: 98, 132, 259].