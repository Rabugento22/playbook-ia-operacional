# Checkpoint 04 — Segurando a sobrecarga do Relay

## Objetivo

Construir o prompt parametrizável que apoia a decisão de backpressure do Relay: recebe o cenário (estado e restrições) e faz a IA comparar mais de um caminho, pesando prós e contras, antes de recomendar.

## Onde está o prompt

O prompt versionado fica em [`devops/decisao-backpressure/`](../../devops/decisao-backpressure/) (`prompt.md` e `README.md`, versão `1.0.0`). Esta pasta guarda o caminho percorrido.

## Arquivos

| Arquivo | Conteúdo |
|---------|----------|
| [`01-contexto.md`](01-contexto.md) | O cenário, as tensões entre as restrições e o que os dados não dizem |
| [`02-prompt.md`](02-prompt.md) | Prompt final e a evolução v1 → v4 |
| [`03-execucao.md`](03-execucao.md) | Modelos, motivo e output real da v4 |
| [`04-curadoria.md`](04-curadoria.md) | Framework, refinamentos, avaliação das saídas e limitações |
| [`entradas/`](entradas/) | O cenário do Relay, transcrito |

## Resumo do resultado

Prompt por meta-prompting com refino manual dirigido, executado em `qwen3:14b` e `gpt-oss:20b` via Ollama. Os dois comparam três ou quatro caminhos e recomendam uma combinação, mas **com falhas de raciocínio que o prompt reduz e não elimina**: erros de conta, confusão entre volume e taxa, e conclusões sobre orçamento sem base. O valor do prompt está na estrutura que expõe esses pontos para revisão.
