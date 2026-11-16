# Checkpoint 02 — Padronizando as notas de triagem

## Objetivo

Construir o prompt parametrizável que transforma um alerta cru do Sentinel em uma nota de triagem padronizada de cinco rótulos, e justificar o método usado para ensinar o padrão ao modelo.

## Onde está o prompt

O prompt versionado fica em [`devops/nota-de-triagem/`](../../devops/nota-de-triagem/) (`prompt.md` e `README.md`, versão `1.0.0`). Esta pasta guarda o caminho percorrido.

## Arquivos

| Arquivo | Conteúdo |
|---------|----------|
| [`01-contexto.md`](01-contexto.md) | O problema, as duas listas do enunciado e as decisões de escopo |
| [`02-prompt.md`](02-prompt.md) | Prompt final e a evolução das duas variantes (regras e exemplos) |
| [`03-execucao.md`](03-execucao.md) | Modelos, motivo e output real nos 3 alertas |
| [`04-curadoria.md`](04-curadoria.md) | Método escolhido com evidência, refinamentos e limitações |
| [`entradas/`](entradas/) | Os 3 alertas crus e os exemplos de formato do time |

## Resumo do resultado

Comparei o ensino do padrão por **exemplos** (C-A-R-E) e por **regras e formato** (R-T-F). Com o resto do prompt igual, os exemplos fizeram os modelos reaproveitar o conteúdo deles (49 trechos de 4 palavras contra 11 sem exemplos), sem ganho de formato. O prompt final ensina por regras. Executado com `qwen3:14b` e `gpt-oss:20b` via Ollama, as seis notas ficaram no padrão.
