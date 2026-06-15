### **1. INTRODUÇÃO**

**1.1 Problema de Pesquisa** De que maneira os mecanismos nativos do Kernel Linux — especificamente Namespaces, Control Groups (Cgroups) e o subsistema Netfilter — atuam de forma integrada na arquitetura do sistema operacional para garantir o isolamento de recursos e o endurecimento de segurança em ambientes de virtualização e containers?

**1.2 Objetivo Geral** Analisar, sob a ótica da arquitetura de sistemas de informação, a viabilidade, o funcionamento interno e a eficácia das estruturas nativas do Kernel Linux no isolamento espacial, controle de recursos e segurança periférica de rede em ambientes virtualizados de alta densidade.

**1.3 Objetivos Específicos**

- Investigar a mecânica dos Namespaces no Kernel Linux, identificando como o isolamento de contextos (PID, NET, MNT, entre outros) mitiga riscos de escalada de privilégios.
    
- Avaliar o papel do subsistema Control Groups (Cgroups V1 e V2) na limitação determinística de recursos de hardware (CPU, Memória e I/O) e na prevenção de ataques de negação de serviço internos (DoS).
    
- Examinar a arquitetura do ecossistema Netfilter/Nftables como barreira de segurança nativa a nível de kernel para filtragem e controle de tráfego de rede inter-containers.

**1.4 Justificativa**

A relevância deste estudo fundamenta-se na necessidade crítica de garantir a resiliência, a segurança e a eficiência operacional em infraestruturas de TI modernas, onde a consolidação de servidores por meio de contêineres e virtualização tornou-se o padrão de mercado.

Em primeiro lugar, mapeia-se o risco associado à ausência de limites operacionais diretamente gerenciados pelo Kernel. Processos ou contêineres descontrolados que operam sem restrições de _hardware_ tendem a exaurir os recursos de CPU e memória do _host_. Esse cenário culmina na degradação severa ou na interrupção de processos vitais do sistema operacional hospedeiro, comprometendo inclusive a persistência de registros de auditoria (_logs_). Do ponto de vista da segurança e governança corporativa, a perda ou o atraso na escrita de _logs_ inviabiliza a detecção de incidentes e a resposta rápida a anomalias, gerando uma vulnerabilidade sistêmica.

Em segundo lugar, justifica-se a abordagem nativa e artesanal sobre as soluções automatizadas conhecidas como "caixas pretas". Embora instaladores automáticos facilitem o desdobramento inicial, eles operam sob premissas genéricas que desconsideram as especificidades e a elasticidade necessárias para cenários de alta complexidade. Compreender e configurar as ferramentas de forma nativa permite alinhar a infraestrutura exatamente às demandas específicas do negócio, maximizando o determinismo do Kernel Linux e mitigando o risco de comportamentos imprevisíveis decorrentes de camadas de abstração desnecessárias.

Por fim, sob a perspectiva do valor estratégico para grandes corporações e consultorias globais de tecnologia, evidencia-se a demanda por profissionais que dominem a arquitetura do sistema de dentro para fora. Ambientes de produção reais frequentemente divergem do planejamento idealizado. Diante de falhas complexas onde ferramentas comerciais e automações falham, o corpo técnico dotado de profundo conhecimento sobre os internos do Kernel possui a competência necessária para realizar diagnósticos cirúrgicos e resoluções em tempo real (_troubleshooting_ avançado). Esse domínio técnico traduz-se diretamente em redução do Tempo Médio de Reparo (MTTR), continuidade dos negócios e preservação dos Acordos de Nível de Serviço (SLA) dos clientes.

