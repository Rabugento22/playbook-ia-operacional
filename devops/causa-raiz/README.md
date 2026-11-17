---
nome: Análise de causa-raiz de degradação
descricao: Cruza configuração, métricas e logs de um sistema degradado e devolve linha do tempo, cadeia causal, causa-raiz com confiança, limitações dos dados e ações proporcionais.
versao: 1.0.0
tags: [causa-raiz, incidentes, observabilidade, sre]
inputs:
  - nome: config
    descricao: Configuração versionada do sistema (por exemplo, o YAML do cluster), colada sem edição
  - nome: metricas
    descricao: Tabela de métricas da janela do problema (por exemplo, 2 horas em pontos de 30 minutos)
  - nome: logs
    descricao: Trecho de logs de um nó coletado na mesma janela das métricas
---

# Análise de causa-raiz de degradação

## Objetivo

Dar ao plantão um roteiro de raciocínio para degradações como a do Cerebro: o prompt recebe a configuração, as métricas e os logs em `{{config}}`, `{{metricas}}` e `{{logs}}` e leva o modelo a uma cadeia causal numerada, separando causa-raiz, efeitos e correlações, com grau de confiança, limitações dos dados e ações proporcionais ("conter agora" e "corrigir depois").

## Quando usar

- Uma degradação de busca, ingestão ou latência com configuração, métricas e logs da mesma janela disponíveis.
- Para trocar só o pacote de entrada a cada novo incidente, sem reescrever o prompt.
- Não substitui a investigação: é um primeiro diagnóstico a ser confirmado.

## Como usar

1. Cole a configuração, as métricas e os logs sem edição. Antes de enviar a um modelo externo, avalie a sanitização descrita em [`01-contexto.md`](../../checkpoints/checkpoint-03/01-contexto.md).
2. Copie o texto de [`prompt.md`](prompt.md) (depois do frontmatter) e troque os três placeholders.
3. Execute em um modelo com raciocínio; os resultados do CP03 usaram `qwen3:14b` e `gpt-oss:20b`.

## Exemplo

Entrada: os três artefatos do Cerebro em [`checkpoints/checkpoint-03/entradas/`](../../checkpoints/checkpoint-03/entradas/). Trecho da saída real do `qwen3:14b` (via Ollama):

```text
Causa-Raiz:  
- Reindex job demorado e mal dimensionado (configuração: `reindex_job:avg_duration_min: 90`), que exige mais recursos do que o cluster pode suportar (evidência: reindex task ainda em execução às 09:58, com 41% concluído, e métricas de heap_used_pct e indexed_docs_per_s crescendo exponencialmente).  
```

A saída completa dos dois modelos está em [`03-execucao.md`](../../checkpoints/checkpoint-03/03-execucao.md).

## Limitações

- **A qualidade varia entre modelos.** Com o mesmo prompt, o `gpt-oss:20b` afirmou que a reindexação "iniciou em 08:02" (o agendamento é 02:00) e deu confiança alta dizendo que nenhum dado contradiz a cadeia causal, o que não procede; o `qwen3:14b` deu confiança média e admitiu que a hipótese não explica a lentidão da reindexação.
- Os dois modelos propõem, em "conter agora", ações de alcance maior do que o recomendado (aumentar memória, reiniciar nó), apesar da regra de preferir ações reversíveis.
- O prompt não resolve o que os dados não mostram (por exemplo, por que a vazão de indexação dobrou); ele só exige que isso seja declarado.
- Uma execução por modelo; não se mediu a variação entre execuções.
- Os artefatos de um único nó limitam a conclusão sobre o cluster inteiro.

## Gate de qualidade

Este prompt tem saída aberta, então o teste é um juiz LLM, e não regex. [`promptfooconfig.yaml`](promptfooconfig.yaml) gera a análise (`gpt-oss:20b`) e pede ao juiz (`qwen3:14b`, via Ollama) que a pontue em quatro critérios de 0 a 2 ([`rubrica.txt`](rubrica.txt) e [`juiz.txt`](juiz.txt)). A mudança é barrada quando o total fica abaixo de 6 ou algum critério é 0. A rubrica, a calibração e as execuções estão em [`checkpoints/checkpoint-09/`](../../checkpoints/checkpoint-09/).

```bash
promptfoo eval -c devops/causa-raiz/promptfooconfig.yaml --no-cache -j 1
```

## Documentação do caminho

Contexto, decisão de sanitização, evolução do prompt, execuções e curadoria estão em [`checkpoints/checkpoint-03/`](../../checkpoints/checkpoint-03/).
