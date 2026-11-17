# Execução

## Modelos usados (todos via Ollama, local)

| Modelo | Fornecedor | Parâmetros | Motivo |
|---|---|---|---|
| `qwen3:14b` | Alibaba | `temperature 0`, `num_ctx 12288`, raciocínio ligado | Modelo mais capaz que cabe na GPU; custo zero de API; nenhum dado sai da máquina. Foi também o gerador dos prompts |
| `gpt-oss:20b` | OpenAI | `temperature 0`, `num_ctx 12288`, raciocínio `medium` | Segunda família de modelo; o raciocínio ajuda a manter coerência entre fases |

Critérios de escolha: **custo** (zero de API nos dois; o custo real é energia e hardware), **latência** (sem limite neste checkpoint; cada elo levou de 44 s a 172 s), **qualidade** (os dois mais capazes disponíveis localmente) e **privacidade** (execução local; o cenário é fictício).

Foram executadas **duas cadeias completas**, uma por modelo. Em cada uma, o elo 2 recebeu a saída real do elo 1 em `{{diagnostico}}`, e o elo 3 recebeu a saída real do elo 2 em `{{plano}}`, sem edição. Entrada: [`entradas/cenario-forge.txt`](entradas/cenario-forge.txt). Saídas copiadas dos arquivos de execução, sem edição, da versão final (v3).

## Cadeia com `qwen3:14b`

### Elo 1: diagnóstico (63 s, 1.407 tokens de saída)

````text
Garantias do cenário  
1. Consumir do Relay continuamente, processando em pequenos blocos no lugar do lote de 1h.  
2. Manter quem depende do Forge funcionando durante a transição.  
3. Nada de virada única (big-bang): a migração tem que ir em passos e poder voltar atrás.  

Estado atual  
- Ingestão: job em cron acorda a cada 60min (forge-batch-ingest).  
- Transformação: 14 etapas de processamento encadeadas (em Spark), ~40min no total.  
- Destino: grava em tabelas no data warehouse, particionadas por hora.  
- Ponto frágil: se um lote falha, o próximo acumula o dobro de volume.  

Dependentes e o que cada um espera  
- **Sentinel**: depende das tabelas agregadas do Forge. Tolerância não declarada.  
- **Cerebro**: depende dos eventos transformados do Forge. Tolerância não declarada.  
- **Relatórios de billing da Pepper**: dependem dos dados do Forge. Tolerância não declarada.  

Janelas de consumo  
- **Sentinel**: janela não declarada.  
- **Cerebro**: janela não declarada.  
- **Relatórios de billing da Pepper**: consomem de madrugada.  

Pontos frágeis e riscos  
- **Ponto frágil**: se um lote falha, o próximo acumula o dobro de volume. Efeito: sobrecarga no processamento, risco de falhas em cascata e inconsistências nos dados consumidos pelos dependentes.  

O que muda do lote para eventos  
- **Arquitetura**: migração de processamento em lote para eventos, com consumo contínuo.  
- **Fluxo**: dados processados em pequenos blocos, em vez de lotes de 1h.  
- **Garantias de entrega e ordem**: perda de garantias de ordem e entrega garantida (novo risco de dados perdidos ou fora de ordem).  
- **Novos riscos**: possibilidade de processamento parcial, inconsistências em tempo real e necessidade de buffer para garantir tolerância a falhas.  

Invariantes  
- **Garantia 1**: consumo contínuo do Relay. Origina-se da garantia de consumo contínuo.  
- **Garantia 2**: dependentes (Sentinel, Cerebro, Pepper) devem continuar funcionando. Origina-se da garantia de manter dependências funcionais.  
- **Garantia 3**: migração em passos reversíveis. Origina-se da garantia de evitar big-bang.  

Lacunas  
- **Tolerância dos dependentes**: não há informações sobre tolerância a atrasos, inconsistências ou falhas parciais. Pergunta a fazer: quais são os limites de tolerância de Sentinel, Cerebro e Pepper para atrasos ou dados incompletos? Consultar os responsáveis por cada dependente.  
- **Janelas de consumo**: Sentinel e Cerebro não têm janelas declaradas. Pergunta a fazer: em quais momentos Sentinel e Cerebro consomem os dados? Consultar os responsáveis por cada dependente.  

Verificação  
- Garantia 1: tratada em "O que muda do lote para eventos".  
- Garantia 2: tratada em "Dependentes e o que cada um espera" e "Invariantes".  
- Garantia 3: tratada em "Invariantes".  
- Janelas de consumo: "Relatórios de billing da Pepper" (madrugada) está em "Janelas de consumo". Outras janelas não declaradas estão registradas como lacunas.
````

### Elo 2: plano em fases (157 s, 3.373 tokens de saída)

````text
Garantias e lacunas que moldam o plano  
Garantias do cenário:  
1. Consumir do Relay continuamente, processando em pequenos blocos no lugar do lote de 1h.  
2. Manter quem depende do Forge funcionando durante a transição.  
3. Nada de virada única (big-bang): a migração tem que ir em passos e poder voltar atrás.  

Lacunas do diagnóstico:  
- **Tolerância dos dependentes**: Não há informações sobre tolerância a atrasos, inconsistências ou falhas parciais. Pergunta a fazer: quais são os limites de tolerância de Sentinel, Cerebro e Pepper para atrasos ou dados incompletos? Consultar os responsáveis por cada dependente.  
- **Janelas de consumo**: Sentinel e Cerebro não têm janelas declaradas. Pergunta a fazer: em quais momentos Sentinel e Cerebro consomem os dados? Consultar os responsáveis por cada dependente.  

Fases  
**Fase 1: Ingestão contínua com paralelo do lote antigo**  
- **Objetivo**: Configurar a ingestão contínua do Relay, mantendo o job de lote antigo ativo.  
- **O que muda**: O job de ingestão (forge-batch-ingest) é replicado para consumir do Relay em blocos pequenos, com intervalos ajustáveis.  
- **O que permanece como está**: O job de lote antigo continua rodando, mas com prioridade reduzida.  
- **Dependentes afetados e como são protegidos**: Nenhum dependente é afetado diretamente. O consumo de dados pelos dependentes (Sentinel, Cerebro, Pepper) continua usando as tabelas do data warehouse.  
- **Janelas protegidas que se aplicam**: A janela de consumo da Pepper (madrugada) é respeitada, pois a ingestão contínua não interfere com os dados já processados.  
- **Critério de entrada**: O job de ingestão contínua está configurado e validado.  
- **Critério de saída**: O job de ingestão contínua está processando dados sem falhas, com evidência de logs de consumo e métricas de latência. Limiar a definir: taxa de sucesso do job contínuo (ex: 99,9%).  
- **Como voltar atrás**: Reativar o job de lote antigo e desativar o job contínuo, garantindo que os dados processados pelo contínuo sejam ignorados.  

**Fase 2: Processamento paralelo com validação de equivalência**  
- **Objetivo**: Executar as 14 etapas de transformação em paralelo com o Spark antigo, validando resultados.  
- **O que muda**: Um subconjunto das etapas de transformação (ex: 3 etapas) é reescrito para processar eventos em tempo real, com buffer para tolerância a falhas.  
- **O que permanece como está**: As 14 etapas de Spark antigo continuam ativas, mas com prioridade reduzida.  
- **Dependentes afetados e como são protegidos**: Nenhum dependente é afetado diretamente. Os dados processados pelos dependentes continuam vindo do Spark antigo.  
- **Janelas protegidas que se aplicam**: A janela de consumo da Pepper (madrugada) é respeitada, pois os dados processados pelo novo pipeline não são consumidos durante esse período.  
- **Critério de entrada**: O pipeline de transformação contínua está processando dados sem falhas, com resultados equivalentes aos do Spark antigo.  
- **Critério de saída**: A validação de equivalência entre os resultados do Spark antigo e do novo pipeline está completa, com evidência de comparações de métricas (ex: 99,9% de concordância). Limiar a definir: percentual de concordância entre resultados (ex: 99,9%).  
- **Como voltar atrás**: Reativar o Spark antigo e desativar o pipeline de transformação contínua, garantindo que os dados processados pelo novo pipeline sejam ignorados.  

**Fase 3: Armazenamento paralelo com validação de compatibilidade**  
- **Objetivo**: Gravar os dados processados pelo novo pipeline em tabelas paralelas ao data warehouse antigo, validando compatibilidade.  
- **O que muda**: Os dados processados pelo novo pipeline são gravados em tabelas com partição por evento (em vez de por hora), com suporte a consultas compatíveis com os dependentes.  
- **O que permanece como está**: As tabelas do data warehouse antigo continuam ativas, mas com prioridade reduzida.  
- **Dependentes afetados e como são protegidos**: Nenhum dependente é afetado diretamente. Os dependentes continuam usando as tabelas do data warehouse antigo.  
- **Janelas protegidas que se aplicam**: A janela de consumo da Pepper (madrugada) é respeitada, pois os dados gravados pelo novo pipeline não são consumidos durante esse período.  
- **Critério de entrada**: As tabelas do novo pipeline estão gravando dados sem falhas, com compatibilidade verificada.  
- **Critério de saída**: A validação de compatibilidade entre as tabelas do data warehouse antigo e do novo pipeline está completa, com evidência de consultas bem-sucedidas. Limiar a definir: percentual de consultas bem-sucedidas (ex: 99,9%).  
- **Como voltar atrás**: Reativar as tabelas do data warehouse antigo e desativar as tabelas do novo pipeline, garantindo que os dados gravados pelo novo pipeline sejam ignorados.  

**Fase 4: Decomissão do pipeline antigo**  
- **Objetivo**: Desativar o job de lote, o Spark antigo e as tabelas do data warehouse antigo, migrando totalmente para o novo pipeline.  
- **O que muda**: O job de lote, o Spark antigo e as tabelas do data warehouse antigo são desativados.  
- **O que permanece como está**: Nenhum.  
- **Dependentes afetados e como são protegidos**: Nenhum dependente é afetado diretamente, pois os dados são fornecidos pelo novo pipeline.  
- **Janelas protegidas que se aplicam**: A janela de consumo da Pepper (madrugada) é respeitada, pois os dados são fornecidos pelo novo pipeline.  
- **Critério de entrada**: Todos os dependentes estão usando exclusivamente os dados do novo pipeline, com validação completa.  
- **Critério de saída**: O novo pipeline está operando sem falhas, com evidência de logs de consumo e métricas de latência. Limiar a definir: taxa de sucesso do novo pipeline (ex: 99,9%).  
- **Como voltar atrás**: Reativar o job de lote, o Spark antigo e as tabelas do data warehouse antigo, garantindo que os dados do novo pipeline sejam ignorados.  

Ordem e dependências entre fases  
- **Fase 1 → Fase 2**: A ingestão contínua é pré-requisito para a transformação paralela, pois os dados processados pelo novo pipeline dependem da ingestão contínua.  
- **Fase 2 → Fase 3**: A transformação paralela é pré-requisito para o armazenamento paralelo, pois os dados gravados pelo novo pipeline dependem da transformação contínua.  
- **Fase 3 → Fase 4**: O armazenamento paralelo é pré-requisito para a decomissão do pipeline antigo, pois os dependentes dependem dos dados gravados pelo novo pipeline.  

Convivência entre o modelo antigo e o novo  
- **Coexistência**: Durante as fases 1 a 3, o modelo antigo e o novo coexistem, com os dependentes usando exclusivamente os dados do modelo antigo.  
- **Validação de equivalência**: Em cada fase, os resultados do novo pipeline são comparados com os do modelo antigo, usando métricas como concordância de dados, latência e consistência.  

Riscos do plano e mitigação  
- **Risco 1**: Dados perdidos ou fora de ordem no novo pipeline.  
  - **Mitigação**: Implementar buffer para tolerância a falhas e validar a ordem dos dados em tempo real.  
- **Risco 2**: Dependentes não tolerando atrasos ou inconsistências.  
  - **Mitigação**: Consultar os responsáveis pelos dependentes para entender limites de tolerância e ajustar o plano conforme necessário.  
- **Risco 3**: Falha na reversão de uma fase.  
  - **Mitigação**: Garantir que cada fase tenha um caminho de reversão claro, com backup dos dados e configurações do modelo antigo.  

Decisões em aberto  
- **Escolha de ferramenta para processamento contínuo**: Qual tecnologia será usada para substituir o Spark (ex: Apache Flink, Kafka Streams)?  
- **Definição de limiares para validação**: Quais métricas serão usadas para definir limiares de sucesso (ex: taxa de sucesso, percentual de concordância)?  
- **Definição de janelas de consumo para Sentinel e Cerebro**: Em quais momentos Sentinel e Cerebro consomem os dados?  

Verificação contra as garantias  
- **Garantia 1 (consumo contínuo do Relay)**:  
  - **Fase 1**: Sustentada pela ingestão contínua configurada.  
  - **Fase 2**: Sustentada pela ingestão contínua mantida.  
  - **Fase 3**: Sustentada pela ingestão contínua mantida.  
  - **Fase 4**: Sustentada pela ingestão contínua mantida.  
- **Garantia 2 (dependentes funcionando)**:  
  - **Fase 1**: Sustentada pelo uso exclusivo do modelo antigo pelos dependentes.  
  - **Fase 2**: Sustentada pelo uso exclusivo do modelo antigo pelos dependentes.  
  - **Fase 3**: Sustentada pelo uso exclusivo do modelo antigo pelos dependentes.  
  - **Fase 4**: Sustentada pelo uso exclusivo do novo modelo pelos dependentes.  
- **Garantia 3 (migração em passos reversíveis)**:  
  - **Fase 1**: Sustentada pela reversão do job contínuo.  
  - **Fase 2**: Sustentada pela reversão do pipeline de transformação.  
  - **Fase 3**: Sustentada pela reversão das tabelas do novo pipeline.  
  - **Fase 4**: Sustentada pela reversão do novo pipeline.  
- **Janelas protegidas**:  
  - **Fase 1**: Respeitada pela não alteração da janela de consumo da Pepper.  
  - **Fase 2**: Respeitada pela não alteração da janela de consumo da Pepper.  
  - **Fase 3**: Respeitada pela não alteração da janela de consumo da Pepper.  
  - **Fase 4**: Respeitada pela não alteração da janela de consumo da Pepper.
````

### Elo 3: roteiro executável e reversível (172 s, 3.374 tokens de saída)

````text
Garantias do cenário  
- Consumir do Relay continuamente, processando em pequenos blocos no lugar do lote de 1h.  
- Manter quem depende do Forge funcionando durante a transição.  
- Nada de virada única (big-bang): a migração tem que ir em passos e poder voltar atrás.  

Pré-requisitos globais  
- Decisão sobre a ferramenta para processamento contínuo (ex: Apache Flink, Kafka Streams) a definir pelo time.  
- Definição de limiares para validação (ex: taxa de sucesso, percentual de concordância) a definir com base em métricas de latência, consistência e concordância de dados.  
- Informações sobre janelas de consumo de Sentinel e Cerebro a definir com base em consultas aos responsáveis por cada dependente.  

Roteiro por fase  
**Fase 1: Ingestão contínua com paralelo do lote antigo**  
- **Pré-condições**:  
  - O job de ingestão (forge-batch-ingest) está ativo e sem falhas.  
  - A ferramenta para processamento contínuo foi escolhida e configurada.  
- **Passos**:  
  1. Configurar o job de ingestão contínua para consumir do Relay em blocos pequenos.  
  2. Validar que o job contínuo está processando dados sem falhas.  
  3. Garantir que o job de lote antigo continue ativo, com prioridade reduzida.  
- **Verificação de cada passo**:  
  - Passo 1: Logs de consumo do Relay e métricas de latência (limiar a definir: taxa de sucesso do job contínuo).  
  - Passo 2: Métricas de latência e consistência dos dados processados (limiar a definir: taxa de sucesso do job contínuo).  
  - Passo 3: Verificação de que o job de lote antigo está ativo e com prioridade reduzida.  
- **Critério de go/no-go**:  
  - Avançar para a Fase 2 apenas se o job contínuo estiver processando dados com sucesso (limiar a definir).  
- **Rollback**:  
  - **Gatilho**: Falha no job contínuo ou não atingimento do limiar de sucesso.  
  - **Limite de tempo**: 2 horas para decidir.  
  - **Passos**: Reativar o job de lote antigo e desativar o job contínuo, garantindo que os dados processados pelo contínuo sejam ignorados.  
- **Papéis envolvidos**:  
  - Executar: Equipe de SRE.  
  - Aprovar: Equipe de arquitetura.  

**Fase 2: Processamento paralelo com validação de equivalência**  
- **Pré-condições**:  
  - O job contínuo está ativo e processando dados com sucesso.  
  - As 14 etapas de transformação do Spark estão ativas.  
- **Passos**:  
  1. Reescrever um subconjunto das etapas de transformação para processar eventos em tempo real.  
  2. Validar que os resultados do novo pipeline são equivalentes aos do Spark antigo.  
  3. Garantir que o Spark antigo continue ativo, com prioridade reduzida.  
- **Verificação de cada passo**:  
  - Passo 1: Logs de processamento e métricas de latência (limiar a definir: taxa de sucesso do novo pipeline).  
  - Passo 2: Comparação de métricas entre os pipelines (limiar a definir: percentual de concordância).  
  - Passo 3: Verificação de que o Spark antigo está ativo e com prioridade reduzida.  
- **Critério de go/no-go**:  
  - Avançar para a Fase 3 apenas se a validação de equivalência estiver completa (limiar a definir).  
- **Rollback**:  
  - **Gatilho**: Falha na validação de equivalência ou não atingimento do limiar de concordância.  
  - **Limite de tempo**: 2 horas para decidir.  
  - **Passos**: Reativar o Spark antigo e desativar o novo pipeline, garantindo que os dados processados pelo novo pipeline sejam ignorados.  
- **Papéis envolvidos**:  
  - Executar: Equipe de SRE.  
  - Aprovar: Equipe de arquitetura.  

**Fase 3: Armazenamento paralelo com validação de compatibilidade**  
- **Pré-condições**:  
  - O novo pipeline de transformação está ativo e validado.  
  - As tabelas do data warehouse antigo estão ativas.  
- **Passos**:  
  1. Gravar os dados processados pelo novo pipeline em tabelas paralelas ao data warehouse antigo.  
  2. Validar que as tabelas do novo pipeline são compatíveis com os dependentes.  
  3. Garantir que as tabelas do data warehouse antigo continuem ativas, com prioridade reduzida.  
- **Verificação de cada passo**:  
  - Passo 1: Logs de gravação e métricas de latência (limiar a definir: taxa de sucesso do novo pipeline).  
  - Passo 2: Consultas bem-sucedidas nos dependentes (limiar a definir: percentual de consultas bem-sucedidas).  
  - Passo 3: Verificação de que as tabelas do data warehouse antigo estão ativas e com prioridade reduzida.  
- **Critério de go/no-go**:  
  - Avançar para a Fase 4 apenas se a validação de compatibilidade estiver completa (limiar a definir).  
- **Rollback**:  
  - **Gatilho**: Falha na validação de compatibilidade ou não atingimento do limiar de consultas bem-sucedidas.  
  - **Limite de tempo**: 2 horas para decidir.  
  - **Passos**: Reativar as tabelas do data warehouse antigo e desativar as tabelas do novo pipeline, garantindo que os dados gravados pelo novo pipeline sejam ignorados.  
- **Papéis envolvidos**:  
  - Executar: Equipe de SRE.  
  - Aprovar: Equipe de arquitetura.  

**Fase 4: Decomissão do pipeline antigo**  
- **Pré-condições**:  
  - O novo pipeline está ativo e validado.  
  - Todos os dependentes estão usando exclusivamente os dados do novo pipeline.  
- **Passos**:  
  1. Desativar o job de lote, o Spark antigo e as tabelas do data warehouse antigo.  
  2. Validar que os dependentes estão usando exclusivamente os dados do novo pipeline.  
- **Verificação de cada passo**:  
  - Passo 1: Logs de desativação e métricas de latência (limiar a definir: taxa de sucesso do novo pipeline).  
  - Passo 2: Consultas bem-sucedidas nos dependentes (limiar a definir: percentual de consultas bem-sucedidas).  
- **Critério de go/no-go**:  
  - Concluir a migração apenas se todos os dependentes estiverem usando exclusivamente os dados do novo pipeline.  
- **Rollback**:  
  - **Gatilho**: Falha na validação de uso exclusivo ou não atingimento do limiar de consultas bem-sucedidas.  
  - **Limite de tempo**: 2 horas para decidir.  
  - **Passos**: Reativar o job de lote, o Spark antigo e as tabelas do data warehouse antigo, garantindo que os dados do novo pipeline sejam ignorados.  
- **Papéis envolvidos**:  
  - Executar: Equipe de SRE.  
  - Aprovar: Equipe de arquitetura.  

Proteção dos dependentes  
- **Sentinel**:  
  - **Verificações**: Consultas bem-sucedidas nas tabelas do data warehouse antigo.  
  - **Janela protegida**: Não há janela declarada.  
  - **Ação se falhar**: Reativar o pipeline antigo e desativar o novo.  
- **Cerebro**:  
  - **Verificações**: Consultas bem-sucedidas nas tabelas do data warehouse antigo.  
  - **Janela protegida**: Não há janela declarada.  
  - **Ação se falhar**: Reativar o pipeline antigo e desativar o novo.  
- **Pepper**:  
  - **Verificações**: Consultas bem-sucedidas nas tabelas do data warehouse antigo durante a madrugada.  
  - **Janela protegida**: Madrugada.  
  - **Ação se falhar**: Reativar o pipeline antigo e desativar o novo.  

Comunicação  
- **Fase 1**:  
  - Informar a equipe de arquitetura sobre a configuração do job contínuo.  
  - Informar a equipe de operações sobre a ativação do job contínuo.  
- **Fase 2**:  
  - Informar a equipe de arquitetura sobre a validação de equivalência.  
  - Informar a equipe de operações sobre a ativação do novo pipeline.  
- **Fase 3**:  
  - Informar a equipe de arquitetura sobre a validação de compatibilidade.  
  - Informar a equipe de operações sobre a gravação em tabelas paralelas.  
- **Fase 4**:  
  - Informar a equipe de arquitetura sobre a decomissão do pipeline antigo.  
  - Informar a equipe de operações sobre a ativação exclusiva do novo pipeline.  
- **Rollback**:  
  - Informar a equipe de arquitetura e operações sobre a reativação do pipeline antigo.  

Riscos residuais  
- **Risco 1**: Dados perdidos ou fora de ordem no novo pipeline.  
  - **Probabilidade**: Médio.  
  - **Impacto**: Alto.  
  - **Mitigação**: Implementar buffer para tolerância a falhas e validar a ordem dos dados em tempo real.  
- **Risco 2**: Dependentes não tolerando atrasos ou inconsistências.  
  - **Probabilidade**: Médio.  
  - **Impacto**: Alto.  
  - **Mitigação**: Consultar os responsáveis pelos dependentes para entender limites de tolerância e ajustar o plano conforme necessário.  
- **Risco 3**: Falha na reversão de uma fase.  
  - **Probabilidade**: Baixo.  
  - **Impacto**: Médio.  
  - **Mitigação**: Garantir que cada fase tenha um caminho de reversão claro, com backup dos dados e configurações do modelo antigo.  

Checklist final contra as garantias  
- **Garantia 1 (consumo contínuo do Relay)**:  
  - **Fase 1**: Sustentada pela ingestão contínua configurada.  
  - **Conformidade**: Verificação de logs de consumo e métricas de latência.  
  - **Ação se falhar**: Reativar o job de lote antigo e desativar o job contínuo.  
- **Garantia 2 (dependentes funcionando)**:  
  - **Fase 1-3**: Sustentada pelo uso exclusivo do modelo antigo pelos dependentes.  
  - **Conformidade**: Verificação de consultas bem-sucedidas nos dependentes.  
  - **Ação se falhar**: Reativar o pipeline antigo e desativar o novo.  
- **Garantia 3 (migração em passos reversíveis)**:  
  - **Fase 1-4**: Sustentada pela reversão de cada fase.  
  - **Conformidade**: Verificação de que cada fase tem um caminho de reversão claro.  
  - **Ação se falhar**: Reativar o pipeline antigo e desativar o novo.
````

## Cadeia com `gpt-oss:20b`

### Elo 1: diagnóstico (44 s, 1.736 tokens de saída)

````text
Garantias do cenário  
1. consumir do Relay continuamente, processando em pequenos blocos no lugar do lote de 1h  
2. manter quem depende do Forge funcionando durante a transição  
3. nada de virada única (big-bang): a migração tem que ir em passos e poder voltar atrás  

Estado atual  
1. job de ingestão em cron que acorda a cada 60min (forge‑batch‑ingest)  
2. 14 etapas de processamento encadeadas em Spark, totalizando ~40min  
3. gravação em tabelas no data warehouse, particionadas por hora  
4. ponto frágil: se um lote falha, o próximo acumula o dobro de volume  

Dependentes e o que cada um espera  
1. Sentinel  
   - depende: lê as tabelas agregadas  
   - consome: janela não declarada  
   - tolerância: não declarado (lacuna)  
2. Cerebro  
   - depende: indexa os eventos transformados  
   - consome: janela não declarada  
   - tolerância: não declarado (lacuna)  
3. Relatórios de billing da Pepper  
   - depende: rodam de madrugada  
   - consome: janela não declarada (suposição que é madrugada)  
   - tolerância: não declarado (lacuna)  

Janelas de consumo  
1. Sentinel – janela não declarada  
2. Cerebro – janela não declarada  
3. Relatórios de billing da Pepper – janela não declarada (suposição de madrugada)  

Pontos frágeis e riscos  
1. falha de lote → próximo lote acumula dobro de volume (ponto frágil declarado)  
2. job de ingestão em cron pode falhar e perder dados entre execuções (inferência)  
3. 14 etapas de Spark podem falhar, interrompendo o fluxo (inferência)  
4. escrita em tabelas particionadas por hora pode causar duplicação ou perda de registros se falhar (inferência)  
5. dependentes podem ficar sem dados ou com dados incompletos se o pipeline falhar (inferência)  

O que muda do lote para eventos  
1. consumo contínuo do Relay em vez de batch de 1h  
2. processamento em blocos pequenos, exigindo tratamento de ordem e entrega garantida (inferência)  
3. necessidade de idempotência e tolerância a duplicação (inferência)  
4. risco de eventos fora de ordem ou perdidos, exigindo mecanismos de compensação (inferência)  

Invariantes  
1. dependentes devem continuar funcionando durante a transição (garantia 2)  
2. migração deve ser incremental e reversível (garantia 3)  
3. dados transformados devem estar disponíveis para dependentes sem interrupção (derivado de garantias e dependentes)  

Lacunas  
1. qual é o formato e protocolo do Relay? – consultar equipe de infra.  
2. qual a tolerância de latência e perda de dados dos dependentes? – consultar usuários finais.  
3. janela exata de consumo dos relatórios de billing? – consultar equipe de billing.  
4. métricas de sucesso e falha do job de ingestão? – consultar logs e monitoramento.  
5. requisitos de ordem de eventos no novo modelo? – consultar arquitetos de dados.  

Verificação  
- Garantia 1 tratada em "O que muda do lote para eventos" e "Estado atual"  
- Garantia 2 tratada em "Dependentes e o que cada um espera" e "Invariantes"  
- Garantia 3 tratada em "Invariantes"  
- Todas as janelas declaradas (nenhuma) aparecem em "Janelas de consumo" (janela não declarada)
````

### Elo 2: plano em fases (60 s, 2.746 tokens de saída)

````text
Garantias e lacunas que moldam o plano  
Garantias do cenário  
1. consumir do Relay continuamente, processando em pequenos blocos no lugar do lote de 1h  
2. manter quem depende do Forge funcionando durante a transição  
3. nada de virada única (big-bang): a migração tem que ir em passos e poder voltar atrás  

Lacunas do diagnóstico que mais afetam o plano  
- Falta de informação sobre o formato e protocolo do Relay – influencia na escolha de mecanismo de ingestão.  
- Falta de definição de janela de consumo dos dependentes – influencia quando pode ocorrer troca de fonte.  
- Falta de métricas de tolerância a latência e perda de dados – influencia limiares de sucesso em cada fase.  
- Falta de definição de tolerância de falha de lote – influencia estratégia de compensação e idempotência.  

Fases  
Fase 1 – Implantar ingestão paralela do Relay  
Objetivo: iniciar a coleta de eventos do Relay sem interromper o job cron atual.  
O que muda: criação de um job que consome do Relay em pequenos blocos e grava em uma nova tabela de staging.  
O que permanece: job cron continua ativo, Spark 14 etapas continuam em batch.  
Dependentes afetados: nenhum (todos continuam lendo as tabelas antigas).  
Janelas protegidas: nenhuma janela declarada, portanto nenhuma restrição de janela a ser respeitada.  
Critério de entrada: job cron ativo e funcionando.  
Critério de saída: job de ingestão do Relay ativo, sem erros de consumo, e dados gravados na tabela de staging. Evidência: logs de consumo, contagem de eventos. Limiar a definir: número mínimo de eventos por bloco.  
Como voltar atrás: desativar o job de ingestão do Relay e remover a tabela de staging.  

Fase 2 – Adicionar processamento em blocos pequenos  
Objetivo: processar os eventos da tabela de staging em blocos pequenos usando as 14 etapas de Spark, produzindo resultados em uma nova tabela de saída.  
O que muda: criação de um job Spark que lê a tabela de staging em micro‑batches e grava em tabela de saída.  
O que permanece: job cron continua produzindo dados na tabela antiga.  
Dependentes afetados: nenhum (dependentes continuam lendo a tabela antiga).  
Janelas protegidas: nenhuma.  
Critério de entrada: job de ingestão do Relay ativo e tabela de staging populada.  
Critério de saída: job Spark em micro‑batches ativo, dados gravados na tabela de saída, sem erros. Evidência: logs de Spark, contagem de registros. Limiar a definir: tempo máximo de processamento por bloco.  
Como voltar atrás: desativar o job Spark em micro‑batches e remover a tabela de saída.  

Fase 3 – Validar equivalência de resultados  
Objetivo: garantir que os dados produzidos pela nova pipeline são equivalentes aos produzidos pela pipeline antiga.  
O que muda: execução paralela das duas pipelines e comparação de resultados.  
O que permanece: ambas as pipelines continuam ativas.  
Dependentes afetados: nenhum.  
Janelas protegidas: nenhuma.  
Critério de entrada: ambas as pipelines ativas.  
Critério de saída: relatório de equivalência sem divergências significativas. Evidência: comparação de agregados, métricas de divergência. Limiar a definir: percentual máximo de divergência aceitável.  
Como voltar atrás: manter ambas as pipelines ativas; não há reversão necessária.  

Fase 4 – Trocar dependente Sentinel para a nova fonte  
Objetivo: fazer Sentinel ler a tabela de saída em vez da tabela antiga.  
O que muda: alteração de configuração de leitura de Sentinel.  
O que permanece: pipeline antiga continua produzindo dados na tabela antiga.  
Dependentes afetados: Sentinel.  
Janelas protegidas: janela de consumo de Sentinel (não declarada). Respeito: a troca só ocorre fora da janela, se existir.  
Critério de entrada: equivalência validada.  
Critério de saída: Sentinel lendo a tabela de saída, sem perda de dados. Evidência: logs de leitura, métricas de latência. Limiar a definir: tempo máximo de atraso entre ingestão e leitura.  
Como voltar atrás: reconfigurar Sentinel para ler a tabela antiga.  

Fase 5 – Trocar dependente Cerebro para a nova fonte  
Objetivo: fazer Cerebro indexar eventos da tabela de saída.  
O que muda: alteração de configuração de leitura de Cerebro.  
O que permanece: pipeline antiga continua produzindo dados na tabela antiga.  
Dependentes afetados: Cerebro.  
Janelas protegidas: janela de consumo de Cerebro (não declarada). Respeito: troca fora da janela.  
Critério de entrada: equivalência validada e Sentinel funcionando.  
Critério de saída: Cerebro indexando a tabela de saída, sem perda de dados. Evidência: logs de indexação, métricas de latência. Limiar a definir: tempo máximo de atraso.  
Como voltar atrás: reconfigurar Cerebro para a tabela antiga.  

Fase 6 – Trocar dependente Relatórios de billing da Pepper  
Objetivo: fazer os relatórios ler a tabela de saída.  
O que muda: alteração de configuração de leitura dos relatórios.  
O que permanece: pipeline antiga continua produzindo dados na tabela antiga.  
Dependentes afetados: Relatórios de billing.  
Janelas protegidas: janela de consumo de relatórios (suposição de madrugada). Respeito: troca fora da madrugada.  
Critério de entrada: equivalência validada e dependentes anteriores funcionando.  
Critério de saída: relatórios lendo a tabela de saída, sem perda de dados. Evidência: logs de execução, métricas de latência. Limiar a definir: tempo máximo de atraso.  
Como voltar atrás: reconfigurar relatórios para a tabela antiga.  

Fase 7 – Desativar job cron e pipeline antiga  
Objetivo: remover a fonte antiga e consolidar a nova pipeline.  
O que muda: desativação do job cron e das 14 etapas de Spark em batch.  
O que permanece: job de ingestão do Relay, job Spark em micro‑batches, dependentes lendo a tabela de saída.  
Dependentes afetados: nenhum.  
Janelas protegidas: nenhuma.  
Critério de entrada: todos os dependentes funcionando com a nova fonte.  
Critério de saída: job cron e pipeline antiga desativados, apenas a nova pipeline ativa. Evidência: logs de desativação, ausência de execuções do job cron. Limiar a definir: tempo máximo de inatividade do job cron.  
Como voltar atrás: reativar job cron e pipeline antiga.  

Ordem e dependências entre fases  
A ordem segue a necessidade de garantir que cada dependente tenha sua fonte trocada apenas depois que a nova pipeline esteja validada e funcionando.  
Risco de cada fase:  
- Fase 1: risco de consumo falho do Relay – mitigado por monitoramento de logs.  
- Fase 2: risco de falha de processamento em micro‑batches – mitigado por tolerância a falhas e reprocessamento.  
- Fase 3: risco de divergência de dados – mitigado por comparação detalhada e limiares definidos.  
- Fases 4‑6: risco de interrupção de dependentes – mitigado por troca fora das janelas de consumo e validação pré‑troca.  
- Fase 7: risco de perda de dados se dependentes não estiverem totalmente migrados – mitigado por verificação de que todas as dependências já usam a nova fonte.  

Convivência entre o modelo antigo e o novo  
Durante as fases 1 a 6, as duas pipelines coexistem. O job cron continua produzindo dados na tabela antiga enquanto o job de ingestão do Relay e o job Spark em micro‑batches produzem dados na tabela de saída. Cada dependente continua lendo sua fonte antiga até que a fase de troca seja concluída. A validação de equivalência garante que os resultados sejam consistentes antes de qualquer troca.  

Riscos do plano e mitigação  
1. Falha de ingestão do Relay – monitoramento de logs, alertas, reprocessamento de blocos.  
2. Falha de processamento em micro‑batches – tolerância a falhas, reprocessamento, checkpoints.  
3. Divergência de dados entre pipelines – comparação automática, limiares de divergência, revisão manual.  
4. Interrupção de dependentes durante troca – troca fora das janelas de consumo, validação de que a nova fonte está pronta.  
5. Perda de dados ao desativar job cron – verificação de que todas as dependências já usam a nova fonte antes da desativação.  

Decisões em aberto  
- Qual formato e protocolo do Relay será usado para ingestão.  
- Qual a tolerância de latência e perda de dados dos dependentes.  
- Qual a janela exata de consumo dos relatórios de billing.  
- Quais métricas de sucesso e falha do job cron e do job Spark em micro‑batches.  
- Qual a política de idempotência e compensação para eventos fora de ordem.  

Verificação contra as garantias  
Garantia 1 – consumir do Relay continuamente, processando em pequenos blocos no lugar do lote de 1h  
Sustentada nas fases 1, 2 e 3, onde a ingestão do Relay e o processamento em micro‑batches são implementados e validados.  

Garantia 2 – manter quem depende do Forge funcionando durante a transição  
Sustentada em todas as fases, pois cada dependente continua lendo a fonte antiga até que sua fase de troca seja concluída.  

Garantia 3 – nada de virada única (big-bang): a migração tem que ir em passos e poder voltar atrás  
Sustentada por design de fases reversíveis; cada fase tem um passo de reversão explícito.  

Janelas protegidas – nenhuma janela declarada no diagnóstico.  
Como o plano respeita: nenhuma troca de fonte ocorre dentro de uma janela, pois não há janela declarada; caso uma janela seja identificada, as fases de troca de dependentes (4‑6) devem ser agendadas fora dela.  

Qualquer garantia ou janela que o plano não consiga sustentar  
Nenhuma garantia declarada não é sustentada.  
Nenhuma janela declarada não é sustentada.
````

### Elo 3: roteiro executável e reversível (76 s, 3.400 tokens de saída)

````text
Garantias do cenário  
1. consumir do Relay continuamente, processando em pequenos blocos no lugar do lote de 1h  
2. manter quem depende do Forge funcionando durante a transição  
3. nada de virada única (big-bang): a migração tem que ir em passos e poder voltar atrás  

Pré-requisitos globais  
- job cron “forge-batch-ingest” ativo e funcionando (INFERÊNCIA)  
- pipeline Spark de 14 etapas em batch ativo (INFERÊNCIA)  
- tabelas de destino no data warehouse particionadas por hora já existentes (INFERÊNCIA)  
- dependentes Sentinel, Cerebro e relatórios de billing configurados para ler as tabelas antigas (INFERÊNCIA)  
- definição de métricas de tolerância a latência e perda de dados ainda em aberto (SUPOSIÇÃO)  
- definição de janela de consumo dos dependentes ainda em aberto (SUPOSIÇÃO)  
- definição de limiares de sucesso em cada fase ainda em aberto (SUPOSIÇÃO)  

Roteiro por fase  

Fase 1 – Implantar ingestão paralela do Relay  
Pré-condições: job cron ativo, pipeline batch ativo, tabelas antigas disponíveis.  
Passos:  
1.1 Criar job de ingestão que consome do Relay em blocos pequenos e grava em tabela de staging (a definir pelo time).  
1.2 Iniciar o job de ingestão.  
Verificação:  
- logs de consumo mostram que blocos são lidos sem erros.  
- contagem de eventos na tabela de staging aumenta.  
Go/no‑go: se o job falhar em 3 blocos consecutivos ou se a contagem de eventos não crescer, abortar.  
Rollback: desativar o job de ingestão e remover a tabela de staging.  
Gatilho: erro de consumo detectado nos logs.  
Limite de tempo: tempo limite a definir (baseado em SLA de disponibilidade).  
Papéis:  
- Executar: Engenheiro de Dados.  
- Aprovar: Líder de SRE.  

Fase 2 – Adicionar processamento em blocos pequenos  
Pré-condições: job de ingestão ativo, tabela de staging populada.  
Passos:  
2.1 Criar job Spark que lê a tabela de staging em micro‑batches e grava em tabela de saída (a definir pelo time).  
2.2 Iniciar o job Spark em micro‑batches.  
Verificação:  
- logs de Spark mostram execução sem erros.  
- contagem de registros na tabela de saída aumenta.  
Go/no‑go: se o job falhar em 3 micro‑batches consecutivos ou se a contagem de registros não crescer, abortar.  
Rollback: desativar o job Spark e remover a tabela de saída.  
Gatilho: falha de processamento detectada nos logs.  
Limite de tempo: tempo limite a definir (baseado em SLA de latência).  
Papéis:  
- Executar: Engenheiro de Dados.  
- Aprovar: Líder de SRE.  

Fase 3 – Validar equivalência de resultados  
Pré-condições: job cron ativo, job de ingestão ativo, job Spark ativo.  
Passos:  
3.1 Executar comparação paralela entre tabelas antigas e de saída usando métricas de agregação (a definir pelo time).  
3.2 Gerar relatório de equivalência.  
Verificação:  
- relatório mostra divergência abaixo do limiar a definir.  
Go/no‑go: se divergência exceder limiar, abortar.  
Rollback: manter ambas as pipelines ativas; não há reversão necessária.  
Gatilho: divergência detectada no relatório.  
Limite de tempo: tempo limite a definir (baseado em SLA de validação).  
Papéis:  
- Executar: Engenheiro de Dados.  
- Aprovar: Líder de SRE.  

Fase 4 – Trocar dependente Sentinel para a nova fonte  
Pré-condições: equivalência validada, job cron ativo, job Spark ativo.  
Passos:  
4.1 Alterar configuração de leitura do Sentinel para apontar para tabela de saída (a definir pelo time).  
4.2 Verificar que Sentinel está lendo a nova tabela.  
Verificação:  
- logs de leitura mostram acesso à tabela de saída.  
- métricas de latência dentro do limiar a definir.  
Go/no‑go: se Sentinel falhar em ler a nova tabela ou se latência exceder limiar, abortar.  
Rollback: reconfigurar Sentinel para a tabela antiga.  
Gatilho: falha de leitura ou latência alta detectada nos logs.  
Limite de tempo: tempo limite a definir (baseado em SLA de dependente).  
Papéis:  
- Executar: Engenheiro de Dados.  
- Aprovar: Líder de SRE.  

Fase 5 – Trocar dependente Cerebro para a nova fonte  
Pré-condições: equivalência validada, Sentinel funcionando na nova fonte.  
Passos:  
5.1 Alterar configuração de leitura do Cerebro para apontar para tabela de saída (a definir pelo time).  
5.2 Verificar que Cerebro está indexando a nova tabela.  
Verificação:  
- logs de indexação mostram acesso à tabela de saída.  
- métricas de latência dentro do limiar a definir.  
Go/no‑go: se Cerebro falhar em indexar a nova tabela ou se latência exceder limiar, abortar.  
Rollback: reconfigurar Cerebro para a tabela antiga.  
Gatilho: falha de indexação ou latência alta detectada nos logs.  
Limite de tempo: tempo limite a definir (baseado em SLA de dependente).  
Papéis:  
- Executar: Engenheiro de Dados.  
- Aprovar: Líder de SRE.  

Fase 6 – Trocar dependente Relatórios de billing da Pepper  
Pré-condições: equivalência validada, Cerebro funcionando na nova fonte.  
Passos:  
6.1 Alterar configuração de leitura dos relatórios para apontar para tabela de saída (a definir pelo time).  
6.2 Verificar que relatórios estão lendo a nova tabela.  
Verificação:  
- logs de execução mostram acesso à tabela de saída.  
- métricas de latência dentro do limiar a definir.  
Go/no‑go: se relatórios falharem em ler a nova tabela ou se latência exceder limiar, abortar.  
Rollback: reconfigurar relatórios para a tabela antiga.  
Gatilho: falha de leitura ou latência alta detectada nos logs.  
Limite de tempo: tempo limite a definir (baseado em SLA de dependente).  
Papéis:  
- Executar: Engenheiro de Dados.  
- Aprovar: Líder de SRE.  

Fase 7 – Desativar job cron e pipeline antiga  
Pré-condições: todos os dependentes funcionando na nova fonte.  
Passos:  
7.1 Desativar job cron “forge-batch-ingest”.  
7.2 Desativar pipeline Spark de 14 etapas em batch.  
Verificação:  
- logs mostram que job cron e pipeline batch não foram executados.  
- nenhuma escrita ocorre nas tabelas antigas.  
Go/no‑go: se algum job ainda estiver ativo ou se houver escrita nas tabelas antigas, abortar.  
Rollback: reativar job cron e pipeline batch.  
Gatilho: detecção de execução residual nos logs.  
Limite de tempo: tempo limite a definir (baseado em SLA de disponibilidade).  
Papéis:  
- Executar: Engenheiro de Dados.  
- Aprovar: Líder de SRE.  

Proteção dos dependentes  

Sentinel  
Verificação de continuidade: logs de leitura e métricas de latência antes e depois da troca.  
Janela protegida: não declarada; se identificada, troca deve ocorrer fora da janela.  
Se Sentinel não continuar funcionando: reverter configuração imediatamente (rollback da fase 4).  

Cerebro  
Verificação de continuidade: logs de indexação e métricas de latência antes e depois da troca.  
Janela protegida: não declarada; se identificada, troca deve ocorrer fora da janela.  
Se Cerebro não continuar funcionando: reverter configuração imediatamente (rollback da fase 5).  

Relatórios de billing da Pepper  
Verificação de continuidade: logs de execução e métricas de latência antes e depois da troca.  
Janela protegida: suposta madrugada; troca deve ocorrer fora da madrugada.  
Se relatórios não continuarem funcionando: reverter configuração imediatamente (rollback da fase 6).  

Comunicação  

Fase 1: notificar equipe de dados sobre criação do job de ingestão.  
Fase 2: notificar equipe de dados sobre criação do job Spark.  
Fase 3: notificar equipe de dados e dependentes sobre início da validação de equivalência.  
Fase 4: notificar Sentinel responsável sobre mudança de fonte.  
Fase 5: notificar Cerebro responsável sobre mudança de fonte.  
Fase 6: notificar equipe de billing sobre mudança de fonte.  
Fase 7: notificar equipe de dados sobre desativação do job cron e pipeline batch.  
Rollback: em cada fase, notificar equipe de dados e dependentes sobre reversão e motivo.  

Riscos residuais  
Risco 1: falha de ingestão do Relay. Probabilidade: médio. Impacto: alto. Mitigação: monitoramento de logs, alertas, reprocessamento de blocos.  
Risco 2: falha de processamento em micro‑batches. Probabilidade: médio. Impacto: alto. Mitigação: tolerância a falhas, checkpoints, reprocessamento.  
Risco 3: divergência de dados entre pipelines. Probabilidade: baixo. Impacto: alto. Mitigação: comparação automática, limiares de divergência, revisão manual.  
Risco 4: interrupção de dependentes durante troca. Probabilidade: baixo. Impacto: médio. Mitigação: troca fora das janelas de consumo, validação pré‑troca.  
Risco 5: perda de dados ao desativar job cron. Probabilidade: baixo. Impacto: alto. Mitigação: verificação de que todas as dependências já usam a nova fonte antes da desativação.  

Checklist final contra as garantias  

Garantia 1 – consumir do Relay continuamente, processando em pequenos blocos no lugar do lote de 1h  
Fase 1 passo 1.1/1.2 e Fase 2 passo 2.1/2.2 sustentam.  
Conformidade confirmada por logs de consumo e contagem de eventos na tabela de staging e na tabela de saída.  
Se falhar: abortar fase, reverter e investigar causa.  

Garantia 2 – manter quem depende do Forge funcionando durante a transição  
Fase 1 a 6 garantem que dependentes continuam lendo tabelas antigas até troca.  
Conformidade confirmada por logs de leitura e métricas de latência dos dependentes.  
Se dependente parar de funcionar: reverter fase correspondente imediatamente.  

Garantia 3 – nada de virada única (big-bang): a migração tem que ir em passos e poder voltar atrás  
Cada fase possui passo de rollback explícito e gatilho observável.  
Conformidade confirmada por existência de procedimentos de rollback e por testes de reversão em ambiente de homologação.  
Se rollback não puder ser executado dentro do limite de tempo: notificar equipe de SRE e considerar parada de emergência.
````
