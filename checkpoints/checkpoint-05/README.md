# Checkpoint 05 — Migrando o Forge de lote para tempo real

## Objetivo

Construir a **cadeia de prompts** parametrizáveis que quebra a migração do Forge (de lote para orientado a eventos) em etapas, cada elo recebendo a saída do anterior: diagnóstico, plano em fases e roteiro executável e reversível.

## Onde estão os prompts

Um prompt por elo, em [`devops/`](../../devops/), cada um versão `1.0.0`:

| Elo | Prompt | Parâmetros |
|-----|--------|-----------|
| 1 | [`migracao-forge-diagnostico`](../../devops/migracao-forge-diagnostico/) | `cenario` |
| 2 | [`migracao-forge-plano`](../../devops/migracao-forge-plano/) | `cenario`, `diagnostico` (saída do elo 1) |
| 3 | [`migracao-forge-execucao`](../../devops/migracao-forge-execucao/) | `cenario`, `plano` (saída do elo 2) |

Esta pasta guarda o caminho percorrido.

## Arquivos

| Arquivo | Conteúdo |
|---------|----------|
| [`01-contexto.md`](01-contexto.md) | O cenário, as garantias da migração e o desenho da cadeia |
| [`02-prompt.md`](02-prompt.md) | Os três prompts finais e a evolução v1 → v2, com medições |
| [`03-execucao.md`](03-execucao.md) | Modelos, motivo e output real de cada elo, em duas cadeias completas |
| [`04-curadoria.md`](04-curadoria.md) | Framework por elo, refinamentos, avaliação e limitações |
| [`entradas/`](entradas/) | O cenário do Forge, transcrito |

## Resumo do resultado

Cadeia gerada por meta-prompting (`qwen3:14b`) com refino manual dirigido, executada duas vezes, uma com `qwen3:14b` e outra com `gpt-oss:20b` (via Ollama), cada elo com a saída real do anterior. A v2 eliminou tecnologias presumidas, fases irreversíveis e tabelas; a v3 acrescentou as janelas de consumo, e a madrugada do billing passou a chegar ao plano e ao roteiro nos dois modelos. A cadeia do `gpt-oss:20b` produziu um plano de sete fases reversíveis, com uma fase de troca para cada dependente. **Falhas que permanecem:** o `gpt-oss:20b` rebaixa a madrugada a "suposição"; o plano do `qwen3:14b` perdeu a fase de troca dos dependentes na v3 e ainda inventa limiares numéricos.
