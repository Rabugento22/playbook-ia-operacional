# Checkpoint 06 — Endurecendo a NetworkPolicy do Sentinel

## Objetivo

Construir o prompt parametrizável que recebe um manifesto de NetworkPolicy permissivo, o padrão da Aegis e o mapa de serviços, e devolve a política corrigida; e conduzir a verificação e o refino dessa política (v1, o que a verificação apontou, v2, v3 e v4).

## Onde está o prompt

O prompt versionado fica em [`devops/networkpolicy-sentinel/`](../../devops/networkpolicy-sentinel/) (`prompt.md` e `README.md`, versão `1.0.0`). Esta pasta guarda o caminho percorrido.

## Arquivos

| Arquivo | Conteúdo |
|---------|----------|
| [`01-contexto.md`](01-contexto.md) | O manifesto barrado, o padrão, o mapa e o que eles não dizem |
| [`02-prompt.md`](02-prompt.md) | Prompt final, a evolução P1 → P2 e os prompts de verificação e refino |
| [`03-execucao.md`](03-execucao.md) | Modelos, motivo e o output real de cada iteração, nos dois modelos |
| [`04-curadoria.md`](04-curadoria.md) | Framework, o que cada verificação apontou, avaliação e limitações |
| [`entradas/`](entradas/) | O manifesto permissivo, o padrão e o mapa de serviços, transcritos |

## Resumo do resultado

Prompt por meta-prompting com refino manual dirigido, executado em `qwen3:14b` e `gpt-oss:20b` via Ollama. **A verificação feita pelo próprio modelo falhou:** acertou os defeitos semânticos (default-deny ausente, label de namespace inventado) e errou os estruturais, aprovando uma política com `ports` fora do lugar (o `gpt-oss:20b`) e apontando defeitos que não existiam (o `qwen3:14b`). Um validador determinístico meu acusou o erro, e a v4, dirigida por ele, ficou com 9 de 9 itens do padrão e 2 de 2 recomendados nos dois modelos. A política não foi aplicada em um cluster.
