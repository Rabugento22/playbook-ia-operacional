# Execução

## Modelos usados (todos via Ollama, local)

| Modelo | Fornecedor | Parâmetros | Motivo |
|---|---|---|---|
| `qwen3:14b` | Alibaba | `temperature 0`, `num_ctx 8192`, raciocínio desligado | Modelo mais capaz que cabe na GPU, custo zero de API, nenhum dado sai da máquina. Foi também o modelo do meta-prompting. |
| `gpt-oss:20b` | OpenAI | `temperature 0`, `num_ctx 8192`, raciocínio `low` | Segunda família de modelo, para checar se o prompt funciona em outro fornecedor. |

Critérios de escolha: **custo** (zero de API nos dois; o custo real é energia e hardware), **latência** (sem limite neste checkpoint; o limite de 5 s vale a partir do CP08, com modelos menores; os tempos não foram registrados aqui), **qualidade** (os dois mais capazes disponíveis localmente) e **privacidade** (execução local).

## Execução da versão final (v5)

Entradas: [`alerta-1-sentinel.txt`](entradas/alerta-1-sentinel.txt), [`alerta-2-relay.txt`](entradas/alerta-2-relay.txt) e [`alerta-3-forge.txt`](entradas/alerta-3-forge.txt). Saídas copiadas dos arquivos de execução, sem edição.

### Alerta 1 — Sentinel

Entrada:

````text
2026-05-12 14:02:09 UTC [Sentinel] autoscaler hit max replicas (60/60) on sentinel-api,
queue depth on Relay growing 2k/min, CPU avg 88%, tenant stark-industries
sending 4x baseline volume after onboarding new region
````

**`qwen3:14b`**

````text
ALERTA: Sentinel - autoscaler hit max replicas (60/60) on sentinel-api, queue depth on Relay growing 2k/min, tenant stark-industries  
IMPACTO: Serviços do tenant stark-industries podem estar lentos ou com atrasos devido ao aumento no volume de requisições  
HIPÓTESE INICIAL: Aumento no tráfego após onboarding de nova região está sobrecarregando sentinel-api  
AÇÃO IMEDIATA: Verificar se há possibilidade de redistribuir carga ou adicionar novas instâncias em sentinel-api  
ESCALAR PARA: @sentinel-core se não houver redução na taxa de crescimento da fila em 15 minutos
````

**`gpt-oss:20b`**

````text
ALERTA: Sentinel - autoscaler atingiu limite máximo de réplicas em sentinel-api, tenant stark-industries  
IMPACTO: API do Sentinel fica indisponível ou lenta para clientes da stark-industries  
HIPÓTESE INICIAL: aumento de tráfego 4x após onboarding de nova região saturou o autoscaler  
AÇÃO IMEDIATA: reiniciar o autoscaler ou aumentar manualmente o limite de réplicas  
ESCALAR PARA: @sentinel-core se o limite não for ajustado em 15 minutos
````

### Alerta 2 — Relay

Entrada:

````text
2026-05-13 03:11:00 UTC [Relay] ingest reject rate 6% for 8min, tenant wakanda-systems,
buffer saturated after deploy 02:55
````

**`qwen3:14b`**

````text
ALERTA: Relay - ingest reject rate 6% para tenant wakanda-systems  
IMPACTO: Ingestão de dados para o tenant wakanda-systems está lenta ou falhando, afetando processamento de novos dados  
HIPÓTESE INICIAL: Buffer de ingestão está saturado devido à implantação realizada às 02:55  
AÇÃO IMEDIATA: Reverter ou ajustar a implantação que causou a saturação do buffer  
ESCALAR PARA: @relay-core se não houver melhora em 15 minutos
````

**`gpt-oss:20b`**

````text
ALERTA: Relay - ingest reject rate 6% for 8min, tenant wakanda-systems  
IMPACTO: clientes do tenant wakanda-systems não conseguem enviar dados, causando atraso na ingestão.  
HIPÓTESE INICIAL: buffer saturado após deploy 02:55 provocou rejeição de ingestão.  
AÇÃO IMEDIATA: reiniciar o serviço de ingestão do tenant wakanda-systems para liberar buffer.  
ESCALAR PARA: @relay-core se a taxa de rejeição não cair em 15 minutos.
````

### Alerta 3 — Forge

Entrada:

````text
2026-05-13 11:40:22 UTC [Forge] consumer lag 9min and climbing, batch forge-batch-ingest
delayed after previous job failure, downstream Sentinel starting to lag
````

**`qwen3:14b`**

````text
ALERTA: Forge - consumer lag 9min and climbing, batch forge-batch-ingest delayed after previous job failure  
IMPACTO: O processamento de dados pelo sistema Forge está atrasado, causando atrasos no Sentinel  
HIPÓTESE INICIAL: Falha no job anterior causou atraso no processamento de lote  
AÇÃO IMEDIATA: Reexecutar o job falho do batch forge-batch-ingest  
ESCALAR PARA: @data-platform se o lag continuar após 15 minutos
````

**`gpt-oss:20b`**

````text
ALERTA: Forge - consumer lag 9min and climbing, batch forge-batch-ingest  
IMPACTO: Sentinel ingestion lags, afetando o processamento downstream.  
HIPÓTESE INICIAL: O job forge-batch-ingest está travado após falha anterior.  
AÇÃO IMEDIATA: Reiniciar o job forge-batch-ingest e limpar a fila de consumo.  
ESCALAR PARA: @data-platform se o lag não reduzir em 5 minutos.
````

## Execução da variante com exemplos (v5), para comparação

A mesma v5 com a seção de exemplos (as três notas do time) no lugar indicado. Saídas reais, sem edição.

### Alerta 1 — Sentinel

**`qwen3:14b`**

````text
ALERTA: Sentinel - autoscaler hit max replicas (60/60) on sentinel-api, queue depth on Relay growing 2k/min, tenant stark-industries  
IMPACTO: processamento de eventos atrasado para tenant stark-industries  
HIPÓTESE INICIAL: aumento de 4x no volume de eventos após onboarding de nova região  
AÇÃO IMEDIATA: revisar configuração de autoscaler no Sentinel  
ESCALAR PARA: @sentinel-core se queue depth no Relay não estabilizar em 30min
````

**`gpt-oss:20b`**

````text
ALERTA: Sentinel - autoscaler maxed out sentinel-api, Relay queue growing, CPU 88%, tenant stark-industries  
IMPACTO: API indisponível para tenant stark-industries, backlog de mensagens aumenta  
HIPÓTESE INICIAL: onboarding de nova região aumentou volume, saturando autoscaler e Relay  
AÇÃO IMEDIATA: escalar manualmente o Relay e reduzir limite de réplicas do sentinel-api  
ESCALAR PARA: @sentinel-core se a CPU não cair em 10min
````

### Alerta 2 — Relay

**`qwen3:14b`**

````text
ALERTA: Relay - taxa de rejeição de ingestão acima de 6% por 8min, tenant wakanda-systems  
IMPACTO: ingestão de telemetry interrompida para o tenant wakanda-systems  
HIPÓTESE INICIAL: deploy do Relay às 02:55 reduziu o buffer de ingestão  
AÇÃO IMEDIATA: rollback do deploy em progresso  
ESCALAR PARA: @relay-core se a taxa de rejeição não cair em 10min
````

**`gpt-oss:20b`**

````text
ALERTA: Relay - ingest reject rate 6% for 8min, tenant wakanda-systems  
IMPACTO: ingestão de telemetry degradada para tenant wakanda-systems  
HIPÓTESE INICIAL: buffer saturado após deploy 02:55  
AÇÃO IMEDIATA: rollback do deploy 02:55  
ESCALAR PARA: @relay-core se reject não cair em 10min
````

### Alerta 3 — Forge

**`qwen3:14b`**

````text
ALERTA: Forge - lag de ingestão de 9min e crescendo no consumer batch forge-batch-ingest  
IMPACTO: ingestão de telemetry atrasada, causando atraso no Sentinel  
HIPÓTESE INICIAL: falha no job anterior causou atraso no processamento do batch  
AÇÃO IMEDIATA: reiniciar o job de ingestão do batch forge-batch-ingest  
ESCALAR PARA: @data-platform se lag não estabilizar em 30min
````

**`gpt-oss:20b`**

````text
ALERTA: Forge - consumer lag 9min and climbing, batch forge-batch-ingest delayed after previous job failure, downstream Sentinel starting to lag  
IMPACTO: dashboards do Sentinel atrasados para todos os tenants  
HIPÓTESE INICIAL: falha do job anterior interrompeu o fluxo de dados do forge-batch-ingest  
AÇÃO IMEDIATA: reiniciar o consumer forge-batch-ingest  
ESCALAR PARA: @data-platform se lag não cair em 10min
````
