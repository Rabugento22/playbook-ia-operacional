# Execução

Todas as execuções usam o `promptfoo` 0.125.1 com o provedor local [`providers/ollama-local.js`](../../providers/ollama-local.js) (Ollama, `cost: 0`), `temperature 0`, `num_ctx 12288` e `--no-cache -j 1`. Os arquivos brutos do `promptfoo` estão em [`calibracao/resultados/`](calibracao/resultados/), com os caminhos da máquina trocados por `<repo>`.

## Modelos

| Modelo | Fornecedor | Papel | Motivo |
|--------|-----------|-------|--------|
| `qwen3:14b` | Alibaba (via Ollama) | Gera a análise no gate, com raciocínio ligado; também gerou duas amostras | Foi o modelo mais capaz que cabe na GPU no CP03; a análise leva cerca de 2 a 3 minutos |
| `gpt-oss:20b` | OpenAI (via Ollama) | **Juiz** (raciocínio `low`); também gerou duas amostras | Em seis versões do juiz, foi o que mais se aproximou das notas de referência (ver abaixo). **Troca o `qwen3:14b` como juiz, previsto na D14** |
| `gemma3:4b` e `llama3.2:3b` | Google e Meta (via Ollama) | Só geraram amostras de qualidade baixa para a calibração | Já usados no CP08; saídas piores que as dos modelos grandes |

Critérios de escolha: **custo** (zero de API), **latência** (sem limite neste checkpoint: gerar leva de 2 a 3 minutos e julgar leva cerca de 1 minuto), **qualidade** (a do juiz é o assunto da calibração) e **privacidade** (execução local, dados fictícios).

## Amostras para a calibração

Oito saídas reais e sem edição, com códigos neutros em [`amostras/`](amostras/); a chave está em [`amostras/CHAVE.md`](amostras/CHAVE.md). O "pedido solto" é um prompt de uma linha que escrevi só para obter respostas de qualidade diferente do prompt `causa-raiz`.

| Amostra | Modelo | Prompt | Tempo | Tokens de saída |
|---|---|---|---|---|
| A | gemma3:4b | pedido solto | 14,0 s | 1.184 |
| B | qwen3:14b | prompt causa-raiz | 132,2 s | 2.339 |
| C | llama3.2:3b | prompt causa-raiz | 16,3 s | 1.567 |
| D | llama3.2:3b | pedido solto | 5,6 s | 600 |
| E | gpt-oss:20b | pedido solto | 81,6 s | 3.325 |
| F | gemma3:4b | prompt causa-raiz | 30,8 s | 1.959 |
| G | qwen3:14b | pedido solto | 137,2 s | 2.324 |
| H | gpt-oss:20b | prompt causa-raiz | 105,8 s | 4.386 |

As notas de referência estão em [`calibracao/pontuacao-referencia.md`](calibracao/pontuacao-referencia.md). **É a avaliação do Rubens, adotada por ele; as notas foram propostas pelo Claude** (ver as ressalvas lá).

## Versões do juiz e distância para a referência

Cada versão foi rodada nas oito amostras. "Critérios com diferença maior que 1" conta em quantos dos 32 pares (8 amostras × 4 critérios) o juiz se afasta mais de 1 ponto da referência; o enunciado pede zero. "Decisão igual" compara aprovada ou reprovada pela regra (total ≥ 6 e nenhum critério 0), recalculada a partir das quatro notas.

| Versão | O que mudou | Juiz | Critérios com diferença maior que 1 | Decisão igual |
|---|---|---|---|---|
| v1 | Uma chamada pontua os quatro critérios e soma | `qwen3:14b`, raciocínio desligado | 5 | 4 de 8 |
| v2 | Regras de rigor por critério e soma conferida | `qwen3:14b`, desligado | 4 | 5 de 8 |
| v3 | Fatos do caso marcados como "não fazem parte da análise"; exigir citação literal | `qwen3:14b`, desligado | 3 (4 de 8 sem nota legível: aspas duplas quebravam o JSON) | 1 de 4 |
| v4 | Citações entre aspas simples; raciocínio ligado | `qwen3:14b`, ligado | 3 (2 de 8 sem nota legível) | 3 de 6 |
| v5 | **Uma chamada por critério**; o total e a regra de aprovação saem do `gate.js` | `qwen3:14b`, desligado | 3 | 6 de 8 |
| v6 | Tirei dos fatos a frase sobre as lacunas, que o juiz copiava como se fosse da análise | `qwen3:14b`, desligado | 2 | 6 de 8 |
| v8 | Troca do juiz | `gpt-oss:20b`, `low` | 1 | 7 de 8 |
| v9 | Tirei dos fatos a frase "o cache é efeito"; a citação precisa mostrar o que o descritor pede | `gpt-oss:20b`, `low` | 1 | 8 de 8 (execução 1) e 7 de 8 (execução 2) |
| v10 | Regra extra: olhar o título da seção para saber se algo é causa ou efeito | `gpt-oss:20b`, `low` | 1 | 6 de 8 |

A v10 foi **descartada** (piorou a decisão) e a v9 é a final. O raciocínio ligado do `qwen3:14b` não ajudou: na v4 as notas continuaram longe, e numa tentativa com o desenho da v6 nas amostras E e G ([`juiz-v7-qwen-raciocinio-ligado-E-G.json`](calibracao/resultados/juiz-v7-qwen-raciocinio-ligado-E-G.json)) a avaliação da E passou do limite de 300 s do `fetch` do Node e falhou, e a G ficou em `[1, 2, 2, 0]` contra `[1, 0, 1, 0]` da referência. Os textos de cada versão estão em [`calibracao/versoes-do-juiz/`](calibracao/versoes-do-juiz/); os resultados, em [`calibracao/resultados/`](calibracao/resultados/).

### A v9 não é determinística

O mesmo juiz (mesmo texto, `temperature 0`) foi rodado duas vezes nas mesmas oito amostras. As notas, de C1 a C4, em cada execução e na referência:

| Amostra | Referência | Execução 1 | Execução 2 | Aprovada (ref / 1 / 2) |
|---|---|---|---|---|
| A | [1, 1, 1, 0] = 3 | [1, 1, 2, 0] = 4 | [1, 1, 0, 0] = 2 | não / não / não |
| B | [1, 2, 2, 2] = 7 | [2, 1, 2, 2] = 7 | [2, 2, 2, 2] = 8 | sim / sim / sim |
| C | [1, 1, 1, 1] = 4 | [0, 1, 1, 2] = 4 | [0, 1, 1, 2] = 4 | não / não / não |
| D | [0, 0, 0, 0] = 0 | [1, 1, 1, 0] = 3 | [1, 1, 1, 0] = 3 | não / não / não |
| E | [1, 0, 1, 0] = 2 | [2, 2, 2, 0] = 6 | [2, 1, 2, 0] = 5 | não / não / não |
| F | [1, 1, 2, 1] = 5 | [0, 1, 2, 2] = 5 | [1, 2, 2, 2] = 7 | não / não / sim |
| G | [1, 0, 1, 0] = 2 | [2, 1, 1, 0] = 4 | [1, 2, 1, 0] = 4 | não / não / não |
| H | [2, 2, 2, 1] = 7 | [2, 2, 2, 2] = 8 | [2, 1, 2, 2] = 7 | sim / sim / sim |

Seis das oito amostras tiveram alguma nota diferente entre as duas execuções, e a amostra A variou 2 pontos no C3 (2 contra 0). Em cada execução um par ficou a 2 pontos da referência (E/C2 na execução 1 e G/C2 na execução 2). Detalhes e consequências na [`04-curadoria.md`](04-curadoria.md).

## Execução do gate no prompt real

`promptfoo eval -c devops/causa-raiz/promptfooconfig.yaml --no-cache -j 1`: o `qwen3:14b` gera a análise do CP03 com o prompt `devops/causa-raiz` e o `gpt-oss:20b` pontua. Duração total: 3 min 30 s. Resultado: **aprovada, 7 de 8** (`C1=2; C2=2; C3=1; C4=2`). Arquivos: [`gate-causa-raiz.json`](calibracao/resultados/gate-causa-raiz.json) e [`gate-causa-raiz.console.txt`](calibracao/resultados/gate-causa-raiz.console.txt).

Notas e justificativas do juiz:

- C1 = 2: 2: 'O reindex_job foi agendado para 02:00, mas está executando há mais de 11 horas'
- C2 = 2: 2: 'A queda de cache_hit_pct está correlacionada com o aumento de search_p99_ms, mas não há evidência direta de que o cache seja a causa.'
- C3 = 1: 1: 'Interromper o reindex_job imediatamente para evitar sobrecarga adicional'
- C4 = 2: 2: 'Não há logs de outros nós para confirmar se o problema é isolado a cerebro-node-3.'

Veredito do `gate.js`: `C1=2; C2=2; C3=1; C4=2; total=7/8. Aprovada (total >= 6 e nenhum critério zerado).`

Análise gerada (165 s):

````text
Linha do Tempo:  
- 2026-05-13 08:00 UTC: Configuração do reindex_job agendado para 02:00 (Evidência: configuração).  
- 2026-05-13 08:02:11 UTC: Início do reindex task [88123] (38% concluído) (Evidência: logs).  
- 2026-05-13 08:14:33 UTC: GC young com duração de 620ms (Evidência: logs).  
- 2026-05-13 08:30 UTC: search_p99_ms aumenta para 1100ms (Evidência: métricas).  
- 2026-05-13 08:41:07 UTC: Throttling de indexação para shard [logs-2026.05][7] (Evidência: logs).  
- 2026-05-13 09:00 UTC: search_p99_ms atinge 2300ms e indexed_docs_per_s atinge 9800 (Evidência: métricas).  
- 2026-05-13 09:03:55 UTC: Fila do thread pool write atinge 150/200 (Evidência: logs).  
- 2026-05-13 09:12:48 UTC: GC old com duração de 1.1s (Evidência: logs).  
- 2026-05-13 09:20:02 UTC: Reindex task [88123] atinge 40% (Evidência: logs).  
- 2026-05-13 09:31:17 UTC: Uso do circuit breaker parent atinge 86% (Evidência: logs).  
- 2026-05-13 09:44:29 UTC: Query lenta em shard [logs-2026.05][7] (2380ms) (Evidência: logs).  
- 2026-05-13 09:58:45 UTC: Search retorna resultados parciais (11/12 shards) (Evidência: logs).  
- 2026-05-13 10:00 UTC: search_p99_ms atinge 6700ms e cache_hit_pct cai para 29% (Evidência: métricas).  

Causa-Raiz:  
- Configuração do reindex_job com duração média de 90 minutos, mas o job está executando há mais de 11 horas (Evidência: logs e configuração).  

Mecanismo:  
1. O reindex_job foi agendado para 02:00, mas está executando há mais de 11 horas (Evidência: logs de 08:02:11 e configuração).  
2. A alta taxa de indexação (indexed_docs_per_s de 12400) sobrecarrega a memória (heap_used_pct de 94%) (Evidência: métricas de 10:00 UTC).  
3. O JVM heap de 8GB é insuficiente para o volume de dados, causando GCs frequentes (Evidência: logs de GC young e old).  
4. O circuit breaker parent é acionado devido ao uso de memória excedente (7.7gb/8gb) (Evidência: logs de 09:58:46).  
5. Throttling de indexação e rejeição de bulk requests (Evidência: logs de 09:58:45 e 09:58:46).  
6. Aumento exponencial de search_p99_ms (de 850ms para 6700ms) e queda de cache_hit_pct (de 74% para 29%) (Evidência: métricas de 08:00 a 10:00 UTC).  

Efeitos/Consequências:  
- Aumento de search_p99_ms (etapa 6).  
- Rejeição de bulk requests (etapa 5).  
- Falha em 11/12 shards (etapa 5).  
- Queda de cache_hit_pct (etapa 6).  

Correlações:  
- O reindex_job está agendado para 02:00, mas não há logs de outros nós para confirmar se o problema é isolado a cerebro-node-3.  
- A queda de cache_hit_pct está correlacionada com o aumento de search_p99_ms, mas não há evidência direta de que o cache seja a causa.  

Grau de Confiança:  
- Alta (Justificativa: A configuração do reindex_job com duração média de 90 minutos e a execução prolongada de 11 horas explicam a sobrecarga de memória e GCs. A falta de logs de outros nós e a ausência de métricas de outros nós limitam a confiança total, mas a evidência disponível sustenta a hipótese principal).  

Limitações dos Dados:  
- Não há logs de outros nós para confirmar se o problema é isolado a cerebro-node-3.  
- Não há métricas de uso de CPU ou disco para complementar a análise.  
- Hipóteses alternativas não descartadas: falhas em outros componentes (ex.: drivers de disco, configurações de shard).  
- Dados adicionais necessários: logs de outros nós, métricas de CPU e disco, e detalhes sobre a carga de dados durante o reindex.  

Ações:  
- Conter agora:  
  - Interromper o reindex_job imediatamente para evitar sobrecarga adicional (Evidência: logs de 08:02:11).  
  - Aumentar temporariamente o JVM heap para 12GB para mitigar o circuit breaker (Evidência: métricas de heap_used_pct de 94%).  
- Corrigir depois:  
  - Reconfigurar o reindex_job para executar em horários de baixa carga (Evidência: configuração de schedule).  
  - Aumentar o número de shards ou replicas para distribuir a carga (Evidência: configuração de shards=12 e replicas_per_shard=1).  
  - Revisar a configuração do query_cache (size_mb=512) para evitar evicção excessiva (Evidência: logs de query cache eviction rate spiking).  
- Não fazer ainda:  
  - Não aumentar recursos sem validar se o reindex_job é essencial.  
  - Não alterar a configuração de refresh_interval sem análise de impacto na consistência.
````

### O gate reprova abaixo do corte

Pela regra do `gate.js` (total ≥ 6 e nenhum critério 0), as notas da execução 1 aprovam duas amostras (B e H) e reprovam seis; as da execução 2 aprovam três (B, F e H) e reprovam cinco. Entre as reprovadas nas duas execuções estão a D (a pior), a A, a C e a G (sem limitações). A F, que a referência reprova com 5, foi aprovada na execução 2. Uma regressão que fizesse o prompt produzir texto como o das amostras A, C, D e G seria barrada nas duas execuções; a execução com regressão provocada no pipeline fica para o CP10.

Observação: as execuções 1 e 2 estão em arquivos separados porque a execução 1 ainda não tinha o `gate.js` (o `success` do arquivo da execução 1 vem da regra de cada `llm-rubric`, e não da regra de aprovação); as notas por critério são as mesmas que o juiz deu.
