# Checkpoint 03 — Causa-raiz da degradação no Cerebro

## Objetivo

Construir o prompt parametrizável que recebe configuração, métricas e logs do Cerebro e leva o modelo à causa-raiz (e não só aos sintomas), registrando a decisão de sanitização dos dados antes de uso com um modelo externo.

## Onde está o prompt

O prompt versionado fica em [`devops/causa-raiz/`](../../devops/causa-raiz/) (`prompt.md` e `README.md`, versão `1.0.0`). Esta pasta guarda o caminho percorrido.

## Arquivos

| Arquivo | Conteúdo |
|---------|----------|
| [`01-contexto.md`](01-contexto.md) | O incidente, a leitura dos artefatos e a **decisão de sanitização** |
| [`02-prompt.md`](02-prompt.md) | Prompt final e a evolução v1 → v5 |
| [`03-execucao.md`](03-execucao.md) | Modelos, motivo e output real, mais a execução com dados sanitizados |
| [`04-curadoria.md`](04-curadoria.md) | Framework, refinamentos, avaliação das saídas e limitações |
| [`entradas/`](entradas/) | Os três artefatos do enunciado, transcritos |

## Resumo do resultado

Prompt gerado por meta-prompting (`qwen3:14b` e `gpt-oss:20b`, via Ollama) com refino manual dirigido. A v5 leva os dois modelos à reindexação travada saturando o heap, passando por GC, throttling, circuit breaker e timeouts de busca. O `qwen3:14b` declarou confiança média e admitiu o que os dados não explicam; o `gpt-oss:20b` repetiu erros de leitura de horário e deu confiança alta sem justificativa suficiente. Com os identificadores mascarados, a conclusão se mantém.
