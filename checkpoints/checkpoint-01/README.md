# Checkpoint 01 — O primeiro prompt do playbook

## Objetivo

Construir o prompt parametrizável de **triagem de pods** do cluster onde o Sentinel está hospedado: recebe um snapshot (`kubectl get`, `describe` e `logs`) e devolve os pods problemáticos com causa provável, evidência e ação para o plantão, reconhecendo quando não há nada problemático.

## Onde está o prompt

O prompt versionado da biblioteca fica em [`devops/triagem-de-pods/`](../../devops/triagem-de-pods/) (`prompt.md` e `README.md`, versão `1.0.0`). Esta pasta guarda o caminho percorrido até ele.

## Arquivos

| Arquivo | Conteúdo |
|---------|----------|
| [`01-contexto.md`](01-contexto.md) | O problema, os requisitos do PDF e as decisões de escopo |
| [`02-prompt.md`](02-prompt.md) | Prompt parametrizável final e a evolução v1 → v2 → v3 |
| [`03-execucao.md`](03-execucao.md) | Modelos, motivo e output real nas 3 entradas |
| [`04-curadoria.md`](04-curadoria.md) | Framework escolhido, refinamentos e limitações |
| [`entradas/`](entradas/) | Os 3 snapshots do enunciado, transcritos |

## Resumo do resultado

Prompt gerado por meta-prompting em 3 rodadas, executado nas 3 entradas com `qwen3:14b` (Alibaba) e `gpt-oss:20b` (OpenAI), via Ollama. Os dois modelos identificam o pod `sentinel-api-7d9c8b6f4-h4m2t` (OOMKilled), os dois pods da Entrada 2 e reconhecem a Entrada 3 como saudável.
