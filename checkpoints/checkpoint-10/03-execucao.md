# Execução

## T050: testes dos prompts restantes

Todas as execuções usam o `promptfoo` 0.125.1 com [`providers/ollama-local.js`](../../providers/ollama-local.js) (Ollama, `cost: 0`), `qwen3:14b` (Alibaba) com raciocínio ligado, `temperature 0`, `num_ctx 12288`, `--no-cache -j 1`, um caso por prompt. Escolhi o `qwen3:14b` porque foi o modelo da cadeia do CP05 e porque a cadeia usa como entrada fixa as saídas reais dele. Os arquivos brutos estão em [`resultados/`](resultados/), com os caminhos da máquina trocados por `<repo>`.

Critérios de escolha do modelo: **custo** (zero de API), **latência** (de 1,5 a 3,5 minutos por chamada; estes testes não têm assert de latência, porque o limite de 5 s do enunciado vale para os prompts de saída estruturada), **qualidade** (o modelo mais capaz que cabe na GPU) e **privacidade** (execução local, dados fictícios).

## Entradas fixas da cadeia

O plano precisa do diagnóstico e o roteiro precisa do plano. Em vez de encadear as chamadas dentro do teste, cada elo recebe como entrada a **saída real do CP05** com o `qwen3:14b` (sem edição), guardada em [`entradas/`](entradas/): [`diagnostico-qwen3-14b.txt`](entradas/diagnostico-qwen3-14b.txt) e [`plano-qwen3-14b.txt`](entradas/plano-qwen3-14b.txt). Assim cada teste mede um prompt só, e uma falha no elo 1 não derruba os outros.

## O que cada teste verifica

| Prompt | Verificações determinísticas |
|---|---|
| `decisao-backpressure` | Os 6 títulos em ordem; sem cercas de código nem asteriscos; tabela com barras verticais; pelo menos 3 caminhos; as contas do pico (excedente de 140 mil msgs/s e volume acumulado de 210 milhões) |
| `migracao-forge-diagnostico` | Os 9 títulos em ordem; sem cercas nem asteriscos; a janela de madrugada **dentro da seção** Janelas de consumo (a falha da v1 do CP05); os 3 dependentes; a garantia de não haver virada única |
| `migracao-forge-plano` | Os 7 títulos em ordem; sem cercas nem asteriscos; "madrugada" pelo menos 2 vezes; os 3 dependentes; caminho de reversão |
| `migracao-forge-execucao` | Os 7 títulos em ordem; sem cercas nem asteriscos; "madrugada"; go/no-go; gatilho; limite de tempo |

Todos têm o assert `cost` (custo de no máximo US$ 0,01), que passa sempre porque o provedor local devolve zero.

## Resultado

| Prompt | Resultado | Asserts | Duração da chamada | Tokens de saída | Asserts que reprovaram |
|---|---|---|---|---|---|
| `decisao-backpressure` | REPROVOU | 5 de 8 | 128 s | 2278 | `not-contains` '*'; `regex` '140[\\s.,]?000|140\\s?k'; `regex` '210[\\s.,]?000[\\s.,]?000|210\\s?(M|milh)' |
| `migracao-forge-diagnostico` | REPROVOU | 6 de 7 | 84 s | 1543 | `not-contains` '*' |
| `migracao-forge-plano` | REPROVOU | 6 de 7 | 164 s | 2827 | `not-contains` '*' |
| `migracao-forge-execucao` | REPROVOU | 7 de 8 | 201 s | 3118 | `not-contains` '*' |

Todos os quatro **reprovaram** na rodada final. Detalhes de cada reprovação:

### `decisao-backpressure`

- `not-contains` `*`: Expected output to not contain "*"
- `regex` `140[\s.,]?000|140\s?k`: Expected output to match regex "140[\s.,]?000|140\s?k"
- `regex` `210[\s.,]?000[\s.,]?000|210\s?(M|milh)`: Expected output to match regex "210[\s.,]?000[\s.,]?000|210\s?(M|milh)"

Asteriscos na saída: 212.

Saída completa (128 s):

````text
Reformulação do cenário  
**Fatos:**  
- Relay (barramento de eventos) tem throughput sustentado de 180k msgs/s e pico observado de 320k msgs/s por 25 minutos.  
- Retenção atual é de 4h.  
- Consumidores são Forge (ingestão) e Sentinel (alerting em tempo real).  

**Restrições rígidas:**  
- Alerting do Sentinel não pode atrasar mais que 60s (SLA com cliente).  
- Perda de mensagens é inaceitável (viola SLA de observabilidade).  

**Restrições flexíveis:**  
- Ingestão do Forge pode atrasar até 15min sem violar SLA.  
- Orçamento de infra do trimestre está 8% acima do previsto.  

**Condições a verificar:**  
- Capacidade máxima do sistema (não informada no cenário).  
- Possibilidade de escalar recursos (ex.: armazenamento, processamento).  
- Comportamento de priorização entre consumidores (ex.: Sentinel vs. Forge).  

---

Contas  
1. **Volume de carga no pico:**  
   320k msgs/s × 25 min × 60 s/min = **480.000.000 mensagens**.  

2. **Capacidade do sistema:**  
   - Throughput sustentado (180k msgs/s) × 4h × 3600 s/h = **2.592.000.000 mensagens/hora**.  
   - Retenção atual (4h) × 180k msgs/s = **2.592.000.000 mensagens**.  
   - **Capacidade máxima do sistema (incógnita):** Se for menor que 480M mensagens, o pico excederá a capacidade.  

3. **Atraso acumulado:**  
   - Para Sentinel (SLA 60s): Se o sistema não escalar, o atraso excederá o SLA.  
   - Para Forge (SLA 15min): Atraso tolerável, mas depende da capacidade de buffer.  

---

Caminhos propostos  
**Caminho 1: Buffer com priorização (ex.: Kafka Streams + prioritização de mensagens)**  
- **Como funciona:** Mensagens são armazenadas em um buffer com priorização (Sentinel > Forge). Durante picos, Forge é descartado se o buffer estourar.  
- **Comportamento:**  
  - **Sentinel:** Atraso mantido dentro de 60s (buffer garante prioridade).  
  - **Forge:** Mensagens podem ser descartadas (viola SLA se não houver buffer suficiente).  
- **Prós:** Garante SLA de Sentinel.  
- **Contras:** Perda de mensagens de Forge (se buffer insuficiente).  
- **Riscos:** Descarte de mensagens de Forge pode impactar integridade de dados.  
- **Custo e complexidade:** Alto (requer configuração de priorização e monitoramento).  
- **Condições para funcionar:** Capacidade do buffer ≥ 480M mensagens (ou escalabilidade dinâmica).  

**Caminho 2: Rate limiting com escala automática (ex.: AWS Lambda + SQS)**  
- **Como funciona:** Limita a taxa de entrada para 180k msgs/s, escalando recursos (ex.: mais workers) durante picos.  
- **Comportamento:**  
  - **Sentinel:** Atraso excede 60s se picos não forem mitigados.  
  - **Forge:** Atraso tolerável (15min).  
- **Prós:** Escalabilidade automática.  
- **Contras:** Não garante SLA de Sentinel (sem buffer).  
- **Riscos:** Perda de mensagens se escala insuficiente.  
- **Custo e complexidade:** Médio (requer configuração de escala automática).  
- **Condições para funcionar:** Capacidade de escala ≥ 320k msgs/s.  

**Caminho 3: Híbrido (buffer + rate limiting + fallback para arquivos)**  
- **Como funciona:** Combina buffer para Sentinel, rate limiting para Forge e armazenamento em disco para mensagens não processadas.  
- **Comportamento:**  
  - **Sentinel:** Atraso mantido dentro de 60s (buffer).  
  - **Forge:** Mensagens armazenadas em disco e processadas após o pico.  
- **Prós:** Garante SLA de Sentinel e preserva mensagens de Forge.  
- **Contras:** Complexidade e custo elevados.  
- **Riscos:** Latência adicional para Forge (até 15min).  
- **Custo e complexidade:** Alto (requer armazenamento em disco e sincronização).  
- **Condições para funcionar:** Capacidade de armazenamento ≥ 480M mensagens.  

---

Tabela comparativa  
| Critério | Caminho 1 | Caminho 2 | Caminho 3 |  
|---------|-----------|-----------|-----------|  
| SLA Sentinel (≤60s) | atende | não atende | atende |  
| Perda de mensagens | parcial (Forge) | não atende | não atende |  
| SLA Forge (≤15min) | parcial (descarte) | atende | atende |  
| Orçamento | alto | médio | alto |  
| Escalabilidade | depende de buffer | depende de escala | depende de armazenamento |  
| Complexidade | alto | médio | alto |  

---

Recomendação  
**Caminho 3 (híbrido) é recomendado** porque:  
- **Atende SLA de Sentinel** (buffer prioriza mensagens críticas).  
- **Preserva mensagens de Forge** (armazenamento em disco).  
- **Aceita atraso de Forge** (até 15min, dentro do SLA).  
- **Sacrifica:** Orçamento (custo alto) e complexidade (requer armazenamento e sincronização).  

**Cálculos para o pico:**  
- 480M mensagens no pico.  
- Buffer de Sentinel (ex.: 100M mensagens) + armazenamento em disco (380M mensagens).  
- Tempo para processar Forge após o pico: 380M / 180k ≈ **36,1h** (fora do SLA de 15min, mas tolerável).  

**Por que os demais foram descartados:**  
- **Caminho 1:** Perde mensagens de Forge (viola SLA se buffer insuficiente).  
- **Caminho 2:** Não garante SLA de Sentinel (sem buffer).  

---

Limites e validação  
- **Limites da análise:**  
  - Capacidade máxima do sistema não informada (necessário validar com testes de carga).  
  - Orçamento atual (8% acima do previsto) pode limitar escalabilidade.  
- **Validação:**  
  - Testar throughput máximo com buffer e armazenamento em disco.  
  - Medir atraso de Sentinel e Forge durante picos simulados.  
  - Revisar decisão se:  
    - Capacidade do sistema for menor que 480M mensagens.  
    - Orçamento não permitir armazenamento em disco.  
    - SLA de Sentinel for alterado (ex.: tolerância maior).
````

### `migracao-forge-diagnostico`

- `not-contains` `*`: Expected output to not contain "*"

Asteriscos na saída: 92.

Saída completa (84 s):

````text
Garantias do cenário  
1. Consumir do Relay continuamente, processando em pequenos blocos no lugar do lote de 1h.  
2. Manter quem depende do Forge funcionando durante a transição.  
3. Nada de virada única (big-bang): a migração tem que ir em passos e poder voltar atrás.  

Estado atual  
- Ingestão: um job em cron acorda a cada 60min (o "forge-batch-ingest").  
- Transformação: 14 etapas de processamento encadeadas (em Spark), ~40min no total.  
- Destino: grava em tabelas no data warehouse, particionadas por hora.  
- Ponto frágil: se um lote falha, o próximo acumula o dobro de volume.  

Dependentes e o que cada um espera  
- **Sentinel**: depende das tabelas agregadas do Forge. Não há declaração sobre tolerância a atrasos ou inconsistências.  
- **Cerebro**: indexa os eventos transformados. Não há declaração sobre tolerância a atrasos ou inconsistências.  
- **Relatórios de billing da Pepper**: consomem os dados de madrugada. Não há declaração sobre tolerância a atrasos ou inconsistências.  

Janelas de consumo  
- **Sentinel**: janela não declarada.  
- **Cerebro**: janela não declarada.  
- **Relatórios de billing da Pepper**: consomem de madrugada.  

Pontos frágeis e riscos  
- **Ponto frágil**: se um lote falha, o próximo acumula o dobro de volume. Efeito: aumento de carga no pipeline e risco de falhas em cascata.  
- **Risco de migração**: a transição para processamento contínuo pode gerar inconsistências se os dependentes não tolerarem atrasos ou dados parciais.  

O que muda do lote para eventos  
- **Arquitetura**: processamento contínuo em vez de lote de 1h.  
- **Fluxo**: dados consumidos continuamente, em pequenos blocos, ao invés de lotes periódicos.  
- **Garantias de entrega**: possibilidade de perda de dados parciais se não houver mecanismos de compensação.  
- **Ordem**: perda de garantia de ordem temporal se os eventos não forem processados em sequência.  
- **Novos riscos**: dependências podem falhar se não estiverem preparadas para dados parciais ou atrasos.  

Invariantes  
- **Garantia 1**: os dependentes (Sentinel, Cerebro, Pepper) devem continuar funcionando durante a migração.  
- **Garantia 2**: a migração deve ser reversível, garantindo que nenhum dado seja perdido ou corrompido durante a transição.  
- **Garantia 3**: o pipeline não pode ter falhas de virada única, exigindo que cada etapa da migração seja testada e validada antes de avançar.  

Lacunas  
- **Tolerância de Sentinel e Cerebro**: não há declaração sobre tolerância a atrasos ou inconsistências. Pergunta: quais são os limites de tolerância de Sentinel e Cerebro para atrasos ou dados parciais? Consultar os responsáveis por cada dependente.  
- **Janelas de consumo de Sentinel e Cerebro**: não há declaração sobre quando eles consomem os dados. Pergunta: em quais janelas de tempo Sentinel e Cerebro consomem os dados? Consultar os responsáveis por cada dependente.  
- **Mecanismos de compensação**: não há declaração sobre como lidar com dados perdidos ou duplicados durante a migração. Pergunta: quais são os mecanismos de compensação aceitáveis para garantir consistência? Consultar a equipe de arquitetura.  

Verificação  
- **Garantia 1**: tratada em "Invariantes" e "Dependentes e o que cada um espera".  
- **Garantia 2**: tratada em "Invariantes" e "O que muda do lote para eventos".  
- **Garantia 3**: tratada em "Invariantes" e "O que muda do lote para eventos".  
- **Janelas de consumo**: a janela de "madrugada" para os relatórios de billing da Pepper está em "Janelas de consumo". As outras janelas são lacunas.
````

### `migracao-forge-plano`

- `not-contains` `*`: Expected output to not contain "*"

Asteriscos na saída: 260.

Saída completa (164 s):

````text
Garantias e lacunas que moldam o plano  
Garantias do cenário:  
1. Consumir do Relay continuamente, processando em pequenos blocos no lugar do lote de 1h.  
2. Manter quem depende do Forge funcionando durante a transição.  
3. Nada de virada única (big-bang): a migração tem que ir em passos e poder voltar atrás.  

Lacunas do diagnóstico que afetam o plano:  
- **Tolerância dos dependentes**: Não há informações sobre tolerância a atrasos, inconsistências ou falhas parciais. Isso afeta a ordem das fases, pois a migração só pode avançar se os dependentes suportarem a coexistência de modelos antigo e novo.  
- **Janelas de consumo**: Sentinel e Cerebro não têm janelas declaradas. Isso afeta a definição de fases, pois a migração não pode ocorrer durante janelas protegidas não identificadas.  

Fases  
**Fase 1: Validação do novo pipeline com coexistência parcial**  
- **Objetivo**: Validar que o novo pipeline (consumo contínuo do Relay) gera resultados equivalentes ao modelo antigo, sem impactar os dependentes.  
- **O que muda**:  
  - Ingestão: paralelamente ao job atual (forge-batch-ingest), iniciar um novo job que lê do Relay continuamente.  
  - Transformação: executar as 14 etapas do Spark no novo pipeline, mas sem escrever para o data warehouse.  
- **O que permanece como está**:  
  - O job original (forge-batch-ingest) continua ativo.  
  - Os dependentes (Sentinel, Cerebro, Pepper) continuam lendo do data warehouse original.  
- **Dependentes afetados e como são protegidos**:  
  - Nenhum dependente é afetado diretamente, pois o novo pipeline não escreve dados.  
- **Janelas protegidas que se aplicam**:  
  - Nenhuma janela protegida é afetada, pois o novo pipeline não escreve dados.  
- **Critério de entrada**:  
  - O novo pipeline está configurado e rodando sem erros por pelo menos 24 horas.  
- **Critério de saída**:  
  - Evidência verificável: resultados do novo pipeline (sem escrita) são equivalentes aos do modelo antigo.  
  - Limiar a definir: percentual de equivalência entre resultados (ex.: 99,9%) com base em métricas de validação.  
- **Como voltar atrás**:  
  - Desativar o novo pipeline e reativar o job original (forge-batch-ingest) se a validação falhar.  

**Fase 2: Escrita paralela no data warehouse com validação**  
- **Objetivo**: Escrever dados do novo pipeline no data warehouse, mantendo o modelo antigo ativo.  
- **O que muda**:  
  - O novo pipeline começa a escrever em tabelas paralelas no data warehouse (ex.: com prefixo "new_").  
- **O que permanece como está**:  
  - O job original (forge-batch-ingest) continua ativo.  
  - Os dependentes continuam lendo do data warehouse original.  
- **Dependentes afetados e como são protegidos**:  
  - Nenhum dependente é afetado, pois os dados do novo pipeline são escritos em tabelas separadas.  
- **Janelas protegidas que se aplicam**:  
  - Nenhuma janela protegida é afetada, pois os dependentes não leem das tabelas novas.  
- **Critério de entrada**:  
  - O novo pipeline está escrevendo dados no data warehouse por pelo menos 72 horas sem erros.  
- **Critério de saída**:  
  - Evidência verificável: dados das tabelas novas são equivalentes aos das tabelas antigas.  
  - Limiar a definir: percentual de equivalência entre dados (ex.: 99,9%) com base em métricas de validação.  
- **Como voltar atrás**:  
  - Desativar a escrita no novo pipeline e reativar o job original (forge-batch-ingest) se a validação falhar.  

**Fase 3: Redirecionamento gradual dos dependentes para o novo pipeline**  
- **Objetivo**: Redirecionar os dependentes (Sentinel, Cerebro, Pepper) para lerem dados do novo pipeline, mantendo o modelo antigo como fallback.  
- **O que muda**:  
  - Cada dependente é redirecionado para ler das tabelas novas (ex.: "new_") em etapas separadas.  
- **O que permanece como está**:  
  - O job original (forge-batch-ingest) continua ativo até que todos os dependentes sejam migrados.  
- **Dependentes afetados e como são protegidos**:  
  - Cada dependente tem sua própria etapa de redirecionamento, com validação antes e reversão depois.  
- **Janelas protegidas que se aplicam**:  
  - Para **Relatórios de billing da Pepper**: a migração só pode ocorrer fora da janela de consumo (madrugada).  
  - Para **Sentinel** e **Cerebro**: janelas protegidas não declaradas, então a migração só pode ocorrer após definir as janelas com os responsáveis.  
- **Critério de entrada**:  
  - Para cada dependente: a validação de equivalência entre dados antigos e novos está completa.  
- **Critério de saída**:  
  - Evidência verificável: todos os dependentes estão lendo do novo pipeline sem impacto.  
  - Limiar a definir: percentual de sucesso no consumo (ex.: 99,9%) com base em métricas de uso.  
- **Como voltar atrás**:  
  - Reverter o redirecionamento para o dependente e reativar o modelo antigo se a migração causar falhas.  

Ordem e dependências entre fases  
- **Fase 1** é pré-requisito para **Fase 2**, pois a validação do pipeline é necessária antes de escrever dados.  
- **Fase 2** é pré-requisito para **Fase 3**, pois a escrita paralela é necessária antes de redirecionar os dependentes.  
- A ordem evita riscos de falhas em cascata, pois cada fase é reversível e não depende de etapas anteriores além da validação.  

Convivência entre o modelo antigo e o novo  
- Ambos os modelos coexistem durante a transição:  
  - O modelo antigo (forge-batch-ingest) continua ativo até que todos os dependentes sejam migrados.  
  - O modelo novo (consumo contínuo do Relay) é validado em paralelo.  
- Validação de equivalência:  
  - Para cada etapa do pipeline, comparar resultados do modelo antigo e novo usando métricas como precisão, recall e taxa de erro.  
  - Para os dependentes, validar que os dados lidos do novo pipeline geram os mesmos resultados que os do modelo antigo.  

Riscos do plano e mitigação  
- **Risco 1**: Dados inconsistentes entre modelos antigo e novo.  
  - **Mitigação**: Validar equivalência em tempo real com métricas definidas (ex.: 99,9% de precisão).  
- **Risco 2**: Dependentes falham ao migrar para o novo pipeline.  
  - **Mitigação**: Redirecionar dependentes em etapas separadas, com reversão imediata se a migração falhar.  
- **Risco 3**: Janelas protegidas não respeitadas.  
  - **Mitigação**: Para **Pepper**, migrar fora da janela de madrugada. Para **Sentinel** e **Cerebro**, definir janelas protegidas com os responsáveis antes de migrar.  

Decisões em aberto  
- **Escolha de ferramenta para o novo pipeline**: Qual tecnologia será usada para o consumo contínuo do Relay (ex.: Kafka, Pulsar)?  
- **Definição de janelas protegidas para Sentinel e Cerebro**: Consultar os responsáveis para identificar quando esses dependentes consomem dados.  
- **Limiares de validação**: Definir percentuais de equivalência (ex.: 99,9%) para garantir que os resultados sejam equivalentes.  

Verificação contra as garantias  
- **Garantia 1 (consumo contínuo do Relay)**:  
  - **Fase 1**: Validado com o novo pipeline rodando.  
  - **Fase 2**: Validado com a escrita paralela.  
  - **Fase 3**: Validado com o consumo contínuo ativo.  
- **Garantia 2 (dependentes funcionando)**:  
  - **Fase 1**: Validado com os dependentes lendo do modelo antigo.  
  - **Fase 2**: Validado com os dependentes lendo do modelo antigo.  
  - **Fase 3**: Validado com os dependentes lendo do modelo novo.  
- **Garantia 3 (migração em passos reversíveis)**:  
  - **Fase 1**: Reversível com desativação do novo pipeline.  
  - **Fase 2**: Reversível com desativação da escrita no novo pipeline.  
  - **Fase 3**: Reversível com reativação do modelo antigo.  
- **Janelas protegidas**:  
  - **Relatórios de billing da Pepper**: Respeitadas em **Fase 3** (migração fora da madrugada).  
  - **Sentinel** e **Cerebro**: Não respeitadas, pois janelas protegidas não foram definidas.
````

### `migracao-forge-execucao`

- `not-contains` `*`: Expected output to not contain "*"

Asteriscos na saída: 308.

Saída completa (201 s):

````text
Garantias do cenário  
- Consumir do Relay continuamente, processando em pequenos blocos no lugar do lote de 1h.  
- Manter quem depende do Forge funcionando durante a transição.  
- Nada de virada única (big-bang): a migração tem que ir em passos e poder voltar atrás.  

Pré-requisitos globais  
- Decisão sobre a ferramenta para processamento contínuo (ex: Apache Flink, Kafka Streams).  
- Definição de limiares para validação (ex: taxa de sucesso, percentual de concordância).  
- Identificação das janelas de consumo de Sentinel e Cerebro (ex: horários em que consomem dados).  
- Validação de tolerância dos dependentes (Sentinel, Cerebro, Pepper) a atrasos ou inconsistências.  

Roteiro por fase  
**Fase 1: Ingestão contínua com paralelo do lote antigo**  
- **Pré-condições**:  
  - O job de ingestão (forge-batch-ingest) está ativo.  
  - A ferramenta para processamento contínuo foi escolhida.  
- **Passos**:  
  1. Configurar o job de ingestão contínua para consumir do Relay em blocos pequenos.  
  2. Validar que o job contínuo está processando dados sem falhas.  
  3. Garantir que o job de lote antigo continue ativo, com prioridade reduzida.  
- **Verificação de cada passo**:  
  - Passo 1: Logs de consumo do Relay e métricas de latência. Limiar a definir: taxa de sucesso do job contínuo (ex: 99,9%).  
  - Passo 2: Métricas de latência e logs de processamento. Limiar a definir: taxa de sucesso do job contínuo (ex: 99,9%).  
- **Critério de go/no-go**:  
  - Avançar para a Fase 2 apenas se o job contínuo estiver operando com sucesso (limiar a definir).  
- **Rollback**:  
  - Reativar o job de lote antigo e desativar o job contínuo.  
  - **Gatilho**: Falha no job contínuo ou não atingimento do limiar de sucesso.  
  - **Limite de tempo**: 2 horas para decidir se o rollback é necessário.  
- **Papéis envolvidos**:  
  - Executante: Equipe de SRE.  
  - Aprovador: Equipe de arquitetura.  

**Fase 2: Processamento paralelo com validação de equivalência**  
- **Pré-condições**:  
  - O job contínuo está operando com sucesso.  
  - As 14 etapas de transformação estão ativas.  
- **Passos**:  
  1. Reescrever um subconjunto das etapas de transformação para processar eventos em tempo real.  
  2. Validar que os resultados do novo pipeline são equivalentes aos do Spark antigo.  
  3. Garantir que o Spark antigo continue ativo, com prioridade reduzida.  
- **Verificação de cada passo**:  
  - Passo 1: Métricas de concordância entre resultados do novo pipeline e do Spark antigo. Limiar a definir: percentual de concordância (ex: 99,9%).  
  - Passo 2: Comparação de métricas (ex: 99,9% de concordância).  
- **Critério de go/no-go**:  
  - Avançar para a Fase 3 apenas se a validação de equivalência estiver completa (limiar a definir).  
- **Rollback**:  
  - Reativar o Spark antigo e desativar o novo pipeline.  
  - **Gatilho**: Falha na validação de equivalência ou não atingimento do limiar.  
  - **Limite de tempo**: 2 horas para decidir se o rollback é necessário.  
- **Papéis envolvidos**:  
  - Executante: Equipe de SRE.  
  - Aprovador: Equipe de arquitetura.  

**Fase 3: Armazenamento paralelo com validação de compatibilidade**  
- **Pré-condições**:  
  - O novo pipeline de transformação está operando com sucesso.  
  - As tabelas do data warehouse antigo estão ativas.  
- **Passos**:  
  1. Gravar os dados processados pelo novo pipeline em tabelas paralelas ao data warehouse antigo.  
  2. Validar que as tabelas do novo pipeline são compatíveis com os dependentes.  
  3. Garantir que as tabelas do data warehouse antigo continuem ativas, com prioridade reduzida.  
- **Verificação de cada passo**:  
  - Passo 1: Métricas de compatibilidade (ex: 99,9% de consultas bem-sucedidas).  
  - Passo 2: Consultas bem-sucedidas nos dependentes. Limiar a definir: percentual de consultas bem-sucedidas (ex: 99,9%).  
- **Critério de go/no-go**:  
  - Avançar para a Fase 4 apenas se a validação de compatibilidade estiver completa (limiar a definir).  
- **Rollback**:  
  - Reativar as tabelas do data warehouse antigo e desativar as tabelas do novo pipeline.  
  - **Gatilho**: Falha na validação de compatibilidade ou não atingimento do limiar.  
  - **Limite de tempo**: 2 horas para decidir se o rollback é necessário.  
- **Papéis envolvidos**:  
  - Executante: Equipe de SRE.  
  - Aprovador: Equipe de arquitetura.  

**Fase 4: Decomissão do pipeline antigo**  
- **Pré-condições**:  
  - As tabelas do novo pipeline estão operando com sucesso.  
  - Todos os dependentes estão usando exclusivamente os dados do novo pipeline.  
- **Passos**:  
  1. Desativar o job de lote, o Spark antigo e as tabelas do data warehouse antigo.  
  2. Validar que o novo pipeline está operando sem falhas.  
- **Verificação de cada passo**:  
  - Passo 1: Métricas de latência e logs de consumo. Limiar a definir: taxa de sucesso do novo pipeline (ex: 99,9%).  
- **Critério de go/no-go**:  
  - Concluir a migração apenas se o novo pipeline estiver operando com sucesso (limiar a definir).  
- **Rollback**:  
  - Reativar o job de lote, o Spark antigo e as tabelas do data warehouse antigo.  
  - **Gatilho**: Falha no novo pipeline ou não atingimento do limiar.  
  - **Limite de tempo**: 2 horas para decidir se o rollback é necessário.  
- **Papéis envolvidos**:  
  - Executante: Equipe de SRE.  
  - Aprovador: Equipe de arquitetura.  

Proteção dos dependentes  
- **Sentinel**:  
  - **Verificações**: Nenhum dado é alterado durante a migração.  
  - **Janela protegida**: Não há janela declarada.  
  - **Ação se não continuar**: Revisar a tolerância a atrasos ou inconsistências.  
- **Cerebro**:  
  - **Verificações**: Nenhum dado é alterado durante a migração.  
  - **Janela protegida**: Não há janela declarada.  
  - **Ação se não continuar**: Revisar a tolerância a atrasos ou inconsistências.  
- **Pepper**:  
  - **Verificações**: Dados gravados pelo novo pipeline não são consumidos durante a madrugada.  
  - **Janela protegida**: Madrugada.  
  - **Ação se não continuar**: Revisar a tolerância a atrasos ou inconsistências.  

Comunicação  
- **Fase 1**:  
  - Informar a equipe de SRE e arquitetura sobre a configuração do job contínuo.  
- **Fase 2**:  
  - Informar a equipe de SRE e arquitetura sobre a validação de equivalência.  
- **Fase 3**:  
  - Informar a equipe de SRE e arquitetura sobre a validação de compatibilidade.  
- **Fase 4**:  
  - Informar a equipe de SRE e arquitetura sobre a decomissão do pipeline antigo.  
- **Rollback**:  
  - Informar a equipe de SRE e arquitetura sobre a reversão de cada fase.  

Riscos residuais  
- **Risco 1**: Dados perdidos ou fora de ordem no novo pipeline.  
  - **Probabilidade**: Médio.  
  - **Impacto**: Alto.  
  - **Mitigação**: Implementar buffer para tolerância a falhas e validar a ordem dos dados em tempo real.  
- **Risco 2**: Dependentes não tolerando atrasos ou inconsistências.  
  - **Probabilidade**: Médio.  
  - **Impacto**: Alto.  
  - **Mitigação**: Consultar os responsáveis pelos dependentes para entender limites de tolerância.  
- **Risco 3**: Falha na reversão de uma fase.  
  - **Probabilidade**: Baixo.  
  - **Impacto**: Médio.  
  - **Mitigação**: Garantir que cada fase tenha um caminho de reversão claro, com backup dos dados e configurações do modelo antigo.  

Checklist final contra as garantias  
- **Garantia 1 (consumo contínuo do Relay)**:  
  - **Fase 1**: Sustentada pela ingestão contínua configurada.  
  - **Conformidade**: Verificar logs de consumo e métricas de latência.  
  - **Ação se falhar**: Revisar a configuração do job contínuo.  
- **Garantia 2 (dependentes funcionando)**:  
  - **Fase 1-3**: Sustentada pelo uso exclusivo do modelo antigo pelos dependentes.  
  - **Conformidade**: Verificar que os dependentes não estão usando dados do novo pipeline.  
  - **Ação se falhar**: Revisar a tolerância dos dependentes a atrasos ou inconsistências.  
- **Garantia 3 (migração em passos reversíveis)**:  
  - **Fase 1-4**: Sustentada pela reversão de cada fase.  
  - **Conformidade**: Verificar que cada fase tem um caminho de reversão claro.  
  - **Ação se falhar**: Revisar os critérios de go/no-go e rollback.
````

## Leitura dos resultados

- **Os quatro reprovam no mesmo assert: asteriscos.** Todos os prompts mandam não usar asteriscos (negrito), e o `qwen3:14b` usou entre 92 e 308 em cada saída. É o defeito já registrado nos checkpoints 04 e 05 (o modelo ignora a proibição), agora detectado por um teste. Com os asteriscos fora do caminho, `migracao-forge-diagnostico`, `migracao-forge-plano` e `migracao-forge-execucao` passam em todos os outros asserts.
- **O teste achou um erro de conta.** Em `decisao-backpressure`, o `qwen3:14b` calculou o volume total do pico (320 mil msgs/s × 25 min = 480 milhões) e não o excedente sobre a capacidade sustentada (140 mil msgs/s, 210 milhões). É o erro que a curadoria do CP04 já tinha apontado; os dois asserts de número o pegam.
- **A janela de madrugada, que a v1 do CP05 perdia, está nos três elos.** O assert dentro da seção Janelas de consumo passa no diagnóstico, e a palavra aparece no plano e no roteiro. É o teste de regressão da correção do CP05.
- **Dois asserts estavam rígidos demais na primeira rodada** ([`resultados/rodada-1/`](resultados/rodada-1/)): o de "Caminho N" não aceitava a linha com negrito (`**Caminho 1`) e o de "limite de tempo" não aceitava a maiúscula ("Limite de tempo"). Corrigi os dois para aceitar essas variações, que não são defeito do prompt, e rodei de novo `decisao-backpressure` e `migracao-forge-execucao`. Os outros dois não foram repetidos porque os asserts deles não mudaram.
- **O que estes testes não medem:** a qualidade do raciocínio. Não existe juiz para estes quatro prompts (o juiz do CP09 foi calibrado só para a `causa-raiz`). Um juiz para cada um exigiria uma rubrica própria e uma calibração como a do CP09, com a mesma limitação de ruído.
- **Uma execução, um modelo.** Cada prompt rodou uma vez com o `qwen3:14b`. A saída de um modelo de raciocínio varia entre execuções, então um assert perto do limite (por exemplo, "madrugada" pelo menos 2 vezes no plano) pode oscilar.

## T051: o pipeline testado localmente

O workflow ainda não rodou no GitHub (o repositório não foi publicado e o runner não foi registrado). O que foi testado na máquina:

- **Os scripts de ponta a ponta:** `PROMPTS="nota-de-triagem" .github/scripts/rodar-suite.sh` aqueceu os modelos, rodou o `promptfoo`, comparou com a linha de base e terminou com código 0 (`sem regressão em relação à linha de base`, 60 asserts comparados, 1 defeito conhecido que não bloqueia).
- **Uma regressão provocada, de verdade:** troquei o `prompt.md` do `nota-de-triagem` pelo texto da versão `1.0.0` (o formato que fazia o `llama3.2:3b` tratar os rótulos como títulos) e rodei a suíte. O `comparar.js` terminou com **código 1**: `REGRESSÃO: o build falha`, com 12 asserts que passavam na linha de base e passaram a falhar (os rótulos, o handle e o limite de linhas). O prompt foi restaurado em seguida. Resultado bruto e relatório em [`resultados/regressao-provocada-local/`](resultados/regressao-provocada-local/). Isso prova o gate; **não substitui** o run vermelho no GitHub que o enunciado pede (T054).
- **O seletor:** `selecionar.sh` devolve só os prompts cuja pasta mudou (e os elos seguintes da cadeia do Forge), e todos quando muda o provedor ou o pipeline.

O que depende do GitHub e ainda não foi visto: o disparo por pull request e por push, o comentário no PR, o artefato, e o comportamento do runner self-hosted.

