# Checkpoint 10 — O playbook em produção contínua

Em andamento. Este checkpoint leva a cobertura de testes à biblioteca inteira e monta o pipeline no GitHub Actions.

## O que já existe

- [`01-contexto.md`](01-contexto.md): o que o enunciado pede e o estado da cobertura.
- [`02-testes.md`](02-testes.md): os testes dos quatro prompts de saída aberta que faltavam (`decisao-backpressure` e os três elos da cadeia do Forge), idênticos aos arquivos de `devops/`.
- [`03-execucao.md`](03-execucao.md): a execução desses testes (todos reprovam hoje, pelos motivos descritos lá).
- [`02-pipeline.md`](02-pipeline.md): o workflow do GitHub Actions, os scripts do gate e como preparar o runner; testado localmente, ainda sem run no GitHub.
- [`entradas/`](entradas/): as saídas reais do CP05 usadas como entrada fixa dos elos 2 e 3.
- [`resultados/`](resultados/): arquivos brutos do `promptfoo`.

## O que falta

Registrar o runner e publicar o repositório, evidência de execução no GitHub (sucesso e falha provocada num pull request) e a justificativa estendida do gate (T055).
