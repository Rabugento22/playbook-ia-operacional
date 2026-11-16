# Execução

## Modelos usados (todos via Ollama, local)

| Modelo | Fornecedor | Parâmetros | Motivo |
|---|---|---|---|
| `qwen3:14b` | Alibaba | `temperature 0`, `num_ctx 12288`, raciocínio ligado | Modelo mais capaz que cabe na GPU; o raciocínio ligado ajuda numa análise de causa-raiz; custo zero de API; nenhum dado sai da máquina |
| `gpt-oss:20b` | OpenAI | `temperature 0`, `num_ctx 12288`, raciocínio `medium` | Segunda família de modelo, com raciocínio próprio, para comparar a análise entre fornecedores |

Critérios de escolha: **custo** (zero de API nos dois; o custo real é energia e hardware), **latência** (sem limite neste checkpoint; a análise levou de 1,5 a 2,5 minutos), **qualidade** (os dois mais capazes disponíveis localmente; o raciocínio ligado melhora a cadeia causal) e **privacidade** (execução local, sem envio de dados; ver a [decisão de sanitização](01-contexto.md)).

Entrada: os três artefatos de [`entradas/`](entradas/), colados nos três parâmetros. Saídas copiadas dos arquivos de execução, sem edição.

## Execução da versão final (v5)

### `qwen3:14b` (139 s, 2.927 tokens de saída)

````text
Linha do Tempo:  
- 2026-05-13 02:00 UTC: Início do reindex job (configuração: `reindex_job:schedule: "0 2 * * *"`).  
- 2026-05-13 08:02 UTC: Progresso do reindex task (40% concluído, 3.8M/10M docs) (log: `[INFO] reindex task [88123] progress`).  
- 2026-05-13 08:14 UTC: GC young (620ms, heap 4.9gb→3.1gb/8gb) (log: `[WARN] [gc][young] duration [620ms]`).  
- 2026-05-13 08:30 UTC: search_p99_ms = 1100ms, indexed_docs_per_s = 4100, heap_used_pct = 68% (métrica).  
- 2026-05-13 08:41 UTC: Throttling de indexing (log: `[INFO] now throttling indexing for shard [logs-2026.05][7]`).  
- 2026-05-13 09:00 UTC: search_p99_ms = 2300ms, indexed_docs_per_s = 9800, heap_used_pct = 79% (métrica).  
- 2026-05-13 09:03 UTC: Write thread pool queue at 150/200 (log: `[WARN] write thread pool queue at [150/200]`).  
- 2026-05-13 09:12 UTC: GC old (1.1s, heap 6.3gb→5.9gb/8gb) (log: `[WARN] [gc][old] duration [1.1s]`).  
- 2026-05-13 09:20 UTC: Progresso do reindex task (40% concluído) (log: `[INFO] reindex task [88123] progress`).  
- 2026-05-13 09:31 UTC: Circuit breaker usage 6.9gb/8gb (log: `[WARN] [parent] usage [6.9gb/8gb]`).  
- 2026-05-13 09:44 UTC: Slow query (2380ms) (log: `[WARN] slow query on shard [logs-2026.05][7]`).  
- 2026-05-13 09:51 UTC: Write thread pool queue at 188/200 (log: `[WARN] write thread pool queue at [188/200]`).  
- 2026-05-13 09:58 UTC: Write thread pool full (200/200), rejeição de bulk (log: `[WARN] write thread pool queue full [200/200], rejecting bulk`).  
- 2026-05-13 09:58 UTC: Circuit breaker tripped (7.7gb/8gb) (log: `[WARN] [parent] circuit breaker tripped`).  
- 2026-05-13 10:00 UTC: search_p99_ms = 6700ms, indexed_docs_per_s = 12400, heap_used_pct = 94% (métrica).  

Causa-Raiz:  
- Reindex job demorado e mal dimensionado (configuração: `reindex_job:avg_duration_min: 90`), que exige mais recursos do que o cluster pode suportar (evidência: reindex task ainda em execução às 09:58, com 41% concluído, e métricas de heap_used_pct e indexed_docs_per_s crescendo exponencialmente).  

Mecanismo:  
1. Reindex job iniciado às 02:00, mas com duração real muito superior à esperada (evidência: log de 09:58 mostra 41% concluído, enquanto a configuração prevê término às 03:30).  
2. Aumento de indexed_docs_per_s (de 4200 em 08:00 para 12400 em 10:00) sobrecarrega o cluster (evidência: métricas).  
3. GCs frequentes (young e old) devido à alta utilização de heap (evidência: logs de GCs em 08:14, 09:12, 09:58).  
4. Throttling de indexing e rejeições de bulk devido à saturação do thread pool (evidência: logs de 08:41, 09:58).  
5. Circuit breaker tripped por uso excessivo de memória (evidência: log de 09:58).  
6. Sintoma visível: search_p99_ms atinge 6700ms e circuit breaking exceptions (evidência: métricas de 10:00 e logs de 09:58–10:00).  

Efeitos/Consequências:  
- Aumento exponencial de search_p99_ms (etapa 6).  
- Rejeições de bulk requests (etapa 4).  
- Circuit breaking exceptions (etapa 5).  
- Throttling de indexing (etapa 3).  

Correlações:  
- O horário do reindex job (02:00) coincide com o início da degradação, mas não há dados de outros nós para confirmar se o problema é isolado a `cerebro-node-3`.  
- A queda de cache_hit_pct (de 74% em 08:00 para 29% em 10:00) está correlacionada, mas não há evidência direta de que a cache seja a causa.  

Grau de Confiança:  
- **Média** (Justificativa: A hipótese principal (reindex job mal dimensionado) explica a sobrecarga de recursos, GCs, rejeições de bulk e circuit breaking. No entanto, não explica por que o reindex job está tomando tanto tempo — falta evidência de dados de volume, complexidade de queries ou shard distribution. Além disso, não há logs de outros nós para confirmar se o problema é cluster-wide).  

Limitações dos Dados:  
- Ausência de logs de outros nós para determinar se o problema é isolado a `cerebro-node-3`.  
- Não há métricas de tempo de execução real do reindex job (apenas o progresso em porcentagem).  
- Não há dados sobre o volume de dados sendo reindexado ou a complexidade das queries.  
- Hipóteses alternativas não descartadas: falha em shards específicos, configuração inadequada de shards/replicas (12 shards com 1 replica), ou falta de recursos (JVM heap de 8GB).  
- Dados adicionais necessários: logs de outros nós, métricas de tempo de execução do reindex job, volume de dados, e análise de queries.  

Ações:  
- **Conter agora**:  
  - Interromper o reindex job imediatamente para evitar saturação adicional (ação reversível).  
  - Aumentar temporariamente o limite de memória do JVM (se possível) para evitar circuit breaking.  
- **Corrigir depois**:  
  - Reavaliar a configuração do reindex job (duração, frequência, volume de dados).  
  - Ajustar o número de shards e replicas (12 shards com 1 replica podem ser insuficientes para o volume de dados).  
  - Aumentar o JVM heap (8GB pode ser insuficiente com indexed_docs_per_s de 12400).  
- **Não fazer ainda**:  
  - Não aumentar recursos (como adicionar nós) sem entender o motivo do reindex job demorado.  
  - Não alterar a configuração de shards/replicas sem análise de impacto no volume de dados.
````

### `gpt-oss:20b` (93 s, 4.070 tokens de saída)

````text
Linha do Tempo:  
- 2026‑05‑13 08:00 UTC – Métricas: search_p99 = 850 ms, indexed_docs_per_s = 4200, heap_used_pct = 61 %, cache_hit_pct = 74 % (Evidência: <metricas>).  
- 2026‑05‑13 08:02 11,540 – Log: reindex task [88123] progress 38 % (created 3.8 M/10 M) (Evidência: <logs>).  
- 2026‑05‑13 08:14 33,019 – Log: GC young duration 620 ms, heap 4.9 gb→3.1 gb (Evidência: <logs>).  
- 2026‑05‑13 08:41 07,222 – Log: IndexingMemoryController throttling shard [logs‑2026.05][7] (Evidência: <logs>).  
- 2026‑05‑13 09:00 UTC – Métricas: search_p99 = 2300 ms, indexed_docs_per_s = 9800, heap_used_pct = 79 %, cache_hit_pct = 58 % (Evidência: <metricas>).  
- 2026‑05‑13 09:03 55,810 – Log: ThreadPool queue at 150/200 (Evidência: <logs>).  
- 2026‑05‑13 09:12 48,402 – Log: GC old duration 1.1 s, heap 6.3 gb→5.9 gb (Evidência: <logs>).  
- 2026‑05‑13 09:20 02,118 – Log: reindex task progress 40 % (created 4.0 M/10 M) (Evidência: <logs>).  
- 2026‑05‑13 09:30 UTC – Métricas: search_p99 = 4100 ms, indexed_docs_per_s = 11200, heap_used_pct = 88 %, cache_hit_pct = 41 % (Evidência: <metricas>).  
- 2026‑05‑13 09:31 17,653 – Log: HierarchyCircuitBreakerService warning, usage 6.9 gb/8 gb (86 %) (Evidência: <logs>).  
- 2026‑05‑13 09:44 29,901 – Log: slow query 2380 ms (Evidência: <logs>).  
- 2026‑05‑13 09:51 08,377 – Log: ThreadPool queue at 188/200 (Evidência: <logs>).  
- 2026‑05‑13 09:58 41,102 – Log: ThreadPool queue full, rejecting bulk (EsRejectedExecutionException) (Evidência: <logs>).  
- 2026‑05‑13 09:58 43,210 – Log: GC old duration 1.8 s, heap 7.6 gb→7.4 gb (Evidência: <logs>).  
- 2026‑05‑13 09:58 44,005 – Log: reindex task still running 41 % (Evidência: <logs>).  
- 2026‑05‑13 09:58 45,889 – Log: IndexingMemoryController throttling shard (Evidência: <logs>).  
- 2026‑05‑13 09:58 46,330 – Log: search took 5031 ms (timeout 5000 ms) (Evidência: <logs>).  
- 2026‑05‑13 09:58 46,512 – Log: search returned partial results (11/12 shards) (Evidência: <logs>).  
- 2026‑05‑13 09:58 46,701 – Log: HierarchyCircuitBreakerService tripped, usage 7.7 gb/8 gb (96 %) (Evidência: <logs>).  
- 2026‑05‑13 09:58 47,001 – Log: query cache eviction rate spiking, hit_ratio 0.29 (Evidência: <logs>).  
- 2026‑05‑13 10:01 12,778 – Log: CircuitBreakingException (Data too large) (Evidência: <logs>).  
- 2026‑05‑13 10:03 39,255 – Log: ThreadPool rejected 1284 bulk requests in last 5 min (Evidência: <logs>).  
- 2026‑05‑13 10:05 50,640 – Log: all shards failed for index [logs‑2026.05] on 3 of last 20 queries (Evidência: <logs>).  
- 2026‑05‑13 10:00 UTC – Métricas: search_p99 = 6700 ms, indexed_docs_per_s = 12400, heap_used_pct = 94 %, cache_hit_pct = 29 % (Evidência: <metricas>).

Causa‑Raiz:  
O job de reindexação iniciado em 08:02 (despite being scheduled for 02:00) consumiu grande quantidade de memória e CPU, saturando o heap de 8 GB e acionando o circuit breaker, o que provocou a degradação de busca.  
(Evidência: reindex task progress, IndexingMemoryController throttling, GC logs, HierarchyCircuitBreakerService warnings, search slow/partial results, CircuitBreakingException).

Mecanismo:  
1. Reindexação iniciada em 08:02, processando 3.8 M de 10 M docs (Evidência: log 08:02).  
2. Índice de documentos por segundo aumenta de 4200 a 12400 (Evidência: métricas 08:00‑10:00).  
3. O aumento de escrita gera GC young e old frequentes, reduzindo heap disponível (Evidência: logs 08:14, 09:12, 09:58).  
4. IndexingMemoryController detecta buffer acima do limite e começa a throttling (Evidência: log 08:41, 09:58).  
5. HierarchyCircuitBreakerService avisa que o uso de memória está próximo do limite (Evidência: logs 09:31, 09:58).  
6. O thread pool de escrita atinge a fila máxima e rejeita bulk requests (Evidência: logs 09:58, 10:03).  
7. As consultas de busca excedem o timeout e retornam resultados parciais (Evidência: logs 09:58).  
8. Circuit breaker dispara, bloqueando consultas que excedem 7.9 GB (Evidência: log 10:01).  
9. Resultado final: falhas de busca em 3 de 20 queries (Evidência: log 10:05).

Efeitos/Consequências:  
- Aumento do tempo de resposta de busca (search_p99 de 850 ms a 6700 ms) – etapa 6.  
- Redução da taxa de hit do cache (74 % a 29 %) – etapa 6.  
- Rejeição de bulk requests, causando backlog de indexação – etapa 6.  
- Falhas de consulta (CircuitBreakingException, all shards failed) – etapas 7‑9.  
- Saturação do heap, risco de OutOfMemory – etapa 3.

Correlações:  
- Aumento do índice de documentos por segundo (metricas) corre com a degradação de busca, mas não prova causalidade direta.  
- O horário de início do job (08:02) corre com a degradação, mas pode ser consequência de outro fator (por ex., trigger manual).  
- O tamanho do cache de consulta (512 MB) corre com a queda de hit_ratio, mas não explica o circuit breaker.

Grau de Confiança:  
Alta.  
Justificativa: A sequência de eventos (reindexação, GC, throttling, circuit breaker, falhas de busca) é consistente em logs e métricas. Todos os sintomas são explicados pela pressão de memória causada pelo job de reindexação. Nenhum dado relevante contradiz essa cadeia causal.

Limitações dos Dados:  
- Não há logs de outros nós do cluster; a análise assume que o comportamento observado em cerebro‑node‑3 reflete o cluster inteiro.  
- Falta informação sobre outras tarefas de indexação que possam ter ocorrido simultaneamente.  
- Não há métricas detalhadas de uso de memória por shard ou por thread pool.  
- O motivo exato pelo qual o job iniciou em 08:02 em vez de 02:00 não está claro (manual trigger, erro de agendamento, etc.).

Hipóteses alternativas não descartadas:  
- O job de reindexação pode ter sido executado com um batch size muito grande, aumentando a pressão de memória.  
- O tamanho do cache de consulta pode estar insuficiente, contribuindo para a queda de hit_ratio.  
- O cluster pode estar subdimensionado em relação ao volume de dados (heap 8 GB pode ser insuficiente).

Dados adicionais necessários:  
- Logs de todos os nós para confirmar que a pressão de memória é global.  
- Métricas de uso de memória por shard e por thread pool.  
- Configuração detalhada do job de reindexação (batch size, refresh interval, etc.).  
- Histórico de outras tarefas de indexação ou reindexação.

Ações:  

Conter agora:  
- Pausar ou reduzir a taxa de reindexação (por ex., limitar o número de shards simultâneos ou diminuir o batch size).  
- Aumentar temporariamente o limite do thread pool de escrita (se possível) para evitar rejeições.  
- Desativar ou reduzir o refresh_interval (de 1 s) durante a reindexação para diminuir overhead.  
- Monitorar heap e GC em tempo real; se necessário, liberar memória manualmente (restart node).  

Corrigir depois:  
- Reagendar o job de reindexação para horário de menor carga (ex.: 02:00 conforme configurado).  
- Aumentar o heap do JVM (ex.: 12 GB) se o volume de dados justificar.  
- Aumentar o tamanho do query cache (ex.: 1 GB) para melhorar hit_ratio.  
- Otimizar o job de reindexação: usar smaller batch size, disable refresh entre batches, usar bulk API com tamanho adequado.  
- Revisar a configuração do circuit breaker (threshold, parent limit) para evitar falhas prematuras.  
- Implementar monitoramento de métricas de memória por shard e alertas de GC.  

Não fazer ainda:  
- Alterar a configuração de replicas ou shards sem dados de impacto.  
- Aumentar drasticamente o heap sem confirmação de necessidade.  
- Desativar o circuit breaker, pois pode levar a OutOfMemory.
````

## Execução com os identificadores mascarados (v5)

Os mesmos artefatos com `cerebro-node-3` trocado por `NODE-A`, `logs-2026.05` por `INDEX-A` e `88123` por `TASK-1`, no `qwen3:14b` (154 s, 3.169 tokens de saída). Nenhum dos três identificadores originais aparece na saída.

````text
Linha do Tempo:  
- [2026-05-13 02:00 UTC] Reindex job agendado (Evidência: configuração `reindex_job:schedule: "0 2 * * *"`).  
- [2026-05-13 08:02 UTC] Reindex task [TASK-1] (38% concluído) (Evidência: log `[INFO] reindex task [TASK-1] progress, created [3.8M]/[10M] docs`).  
- [2026-05-13 08:14 UTC] GC young (620ms) (Evidência: log `[WARN] [gc][young] duration [620ms]`).  
- [2026-05-13 08:30 UTC] search_p99_ms = 1100ms, indexed_docs_per_s = 4100, heap_used_pct = 68% (Evidência: métricas).  
- [2026-05-13 08:41 UTC] Throttling de indexação (Evidência: log `[INFO] now throttling indexing for shard [INDEX-A][7]`).  
- [2026-05-13 09:00 UTC] search_p99_ms = 2300ms, indexed_docs_per_s = 9800, heap_used_pct = 79% (Evidência: métricas).  
- [2026-05-13 09:03 UTC] Write thread pool queue = 150/200 (Evidência: log `[WARN] write thread pool queue at [150/200]`).  
- [2026-05-13 09:12 UTC] GC old (1.1s) (Evidência: log `[WARN] [gc][old] duration [1.1s]`).  
- [2026-05-13 09:20 UTC] Reindex task [TASK-1] (40% concluído) (Evidência: log `[INFO] reindex task [TASK-1] progress, created [4.0M]/[10M] docs`).  
- [2026-05-13 09:31 UTC] Circuit breaker usage = 86% (Evidência: log `[WARN] [parent] usage [6.9gb/8gb]`).  
- [2026-05-13 09:44 UTC] Query lento (2380ms) (Evidência: log `[WARN] slow query on shard [INDEX-A][7] took [2380ms]`).  
- [2026-05-13 09:51 UTC] Write thread pool queue = 188/200 (Evidência: log `[WARN] write thread pool queue at [188/200]`).  
- [2026-05-13 09:58 UTC] Write thread pool rejeitou bulk (Evidência: log `[WARN] write thread pool queue full [200/200], rejecting bulk`).  
- [2026-05-13 09:58 UTC] Circuit breaker tripped (Evidência: log `[WARN] [parent] circuit breaker tripped, usage [7.7gb/8gb]`).  
- [2026-05-13 10:01 UTC] CircuitBreakingException (Evidência: log `[ERROR] CircuitBreakingException: [parent] Data too large, would be [7.9gb/8gb]`).  

Causa-Raiz:  
- Reindex job agendado para 02:00 UTC, mas está consumindo recursos por mais de 90 minutos (Evidência: log `[INFO] reindex task [TASK-1] still running, created [4.1M]/[10M] docs (41%)` às 09:58 UTC, que está 7h58m após o início).  

Mecanismo:  
1. Reindex job agendado para 02:00 UTC, mas está demorando mais de 90 minutos (Evidência: log `[INFO] reindex task [TASK-1] still running` às 09:58 UTC).  
2. Aumento de indexed_docs_per_s de 4200 (08:00) para 12400 (10:00) (Evidência: métricas).  
3. Heap_used_pct subiu de 61% (08:00) para 94% (10:00) (Evidência: métricas).  
4. Circuit breaker tripped devido ao uso de 7.7gb/8gb (Evidência: log `[WARN] [parent] circuit breaker tripped`).  
5. Write thread pool rejeitou bulk requests (Evidência: log `[WARN] write thread pool queue full [200/200], rejecting bulk`).  
6. Search_p99_ms subiu de 850ms (08:00) para 6700ms (10:00) (Evidência: métricas).  

Efeitos/Consequências:  
- Aumento de latência de busca (search_p99_ms) (etapa 6).  
- Rejeição de bulk requests (etapa 5).  
- Circuit breaker tripped (etapa 4).  
- Throttling de indexação (etapa 2).  

Correlações:  
- O horário do dia (reindex job agendado para 02:00 UTC, mas degradação visível a partir de 08:00 UTC).  
- Aumento de GC (logs de GC young e old).  

Grau de Confiança:  
- **Média** (Justificativa: A hipótese principal (reindex job demorado) explica o aumento de indexed_docs_per_s, heap_used_pct e circuit breaker tripped. No entanto, não explica por que o reindex job está demorando mais de 90 minutos, já que a configuração indica que ele normalmente termina em ~03:30 UTC. Além disso, não há logs de outros nós para confirmar se o problema é isolado a NODE-A).  

Limitações dos Dados:  
- Ausência de logs de outros nós para verificar se o problema é isolado a NODE-A.  
- Não há informações sobre o tamanho dos dados sendo reindexados ou a eficiência do processo.  
- Não há registros de quando o reindex job terminou, apenas que ele estava em execução às 09:58 UTC.  

Ações:  
- **Conter agora**:  
  - Interromper o reindex job imediatamente para evitar saturação de recursos (Evidência: log `[INFO] reindex task [TASK-1] still running` às 09:58 UTC).  
  - Reduzir a taxa de indexação temporariamente para aliviar a pressão no circuit breaker (Evidência: log `[INFO] now throttling indexing for shard [INDEX-A][7]`).  
- **Corrigir depois**:  
  - Revisar a configuração do reindex job (tempo de execução, tamanho de dados) para evitar sobrecarga (Evidência: configuração `reindex_job:avg_duration_min: 90`).  
  - Aumentar o limite de memória (JVM heap) ou otimizar o uso do query cache (Evidência: configuração `jvm_heap: 8g` e `query_cache:size_mb: 512`).  
- **Não fazer ainda**:  
  - Não aumentar recursos (como adicionar nós) sem investigar se o reindex job está configurado corretamente.  
  - Não alterar a configuração de refresh_interval (1s) sem analisar impactos em tempo real.
````
