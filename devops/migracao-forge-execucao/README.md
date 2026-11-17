---
nome: Migração de lote para eventos, elo 3: roteiro executável e reversível
descricao: Detalha cada fase do plano em passos, verificações, critérios de go/no-go e rollback com gatilho e limite de tempo, e confere o resultado contra as garantias do cenário.
versao: 1.0.0
tags: [migracao, engenharia-de-dados, runbook, cadeia-de-prompts]
inputs:
  - nome: cenario
    descricao: Estado atual do pipeline em lote e o que a migração precisa garantir
  - nome: plano
    descricao: Saída do elo 2 da cadeia (migracao-forge-plano)
---

# Migração de lote para eventos, elo 3: roteiro executável e reversível

## Objetivo

Terceiro elo da cadeia. Recebe o cenário em `{{cenario}}` e o plano em `{{plano}}` e detalha cada fase em um roteiro executável e reversível: pré-condições, passos numerados, verificação de cada passo, critério de go/no-go, rollback com gatilho e limite de tempo, papéis, proteção de cada dependente, comunicação, riscos residuais e um checklist final contra as garantias do cenário.

## Posição na cadeia

- Elo 3 de 3. Recebe a saída do [`migracao-forge-plano`](../migracao-forge-plano/) em `{{plano}}`.
- É o último elo da cadeia.

A cadeia existe porque a migração é grande demais para um prompt só: cada elo faz uma coisa e entrega uma saída estruturada ao seguinte.

## Quando usar

Quando o plano em fases estiver aceito e for preciso transformá-lo em roteiro de execução.

## Como usar

1. Copie o texto de [`prompt.md`](prompt.md) (depois do frontmatter).
2. Troque os placeholders pelos valores indicados no frontmatter; a saída do elo anterior entra sem edição.
3. Revise a saída antes de passar ao próximo elo: erros se propagam pela cadeia.

## Exemplo

Trecho real da saída do `gpt-oss:20b` (via Ollama), executando a cadeia sobre o cenário do Forge ([`cenario-forge.txt`](../../checkpoints/checkpoint-05/entradas/cenario-forge.txt)):

```text
Se Cerebro não continuar funcionando: reverter configuração imediatamente (rollback da fase 5).  

Relatórios de billing da Pepper  
Verificação de continuidade: logs de execução e métricas de latência antes e depois da troca.  
Janela protegida: suposta madrugada; troca deve ocorrer fora da madrugada.  
Se relatórios não continuarem funcionando: reverter configuração imediatamente (rollback da fase 6).  
```

As execuções completas dos dois modelos estão em [`03-execucao.md`](../../checkpoints/checkpoint-05/03-execucao.md).

## Limitações

- Os limites de tempo para decidir um rollback (por exemplo, "30 minutos") foram inventados pelo `gpt-oss:20b`, e o `qwen3:14b` usou "2 horas"; o prompt manda deixá-los a definir, e não impede.
- Papéis como "líder de SRE" ou "time de arquitetura" são suposições do modelo.
- A janela do billing chega ao roteiro nos dois modelos, mas o `gpt-oss:20b` a cita só na proteção dos dependentes, não nos passos de cada fase.
- Uma execução da cadeia por modelo; a variação entre execuções não foi medida.
- **Teste (CP10):** `promptfooconfig.yaml` verifica títulos, formato e fatos da saída, sem avaliar a qualidade do raciocínio; a proibição de asteriscos reprova com o `qwen3:14b`. Detalhes em [`checkpoint-10`](../../checkpoints/checkpoint-10/).

## Documentação do caminho

Contexto, evolução dos prompts, execuções e curadoria estão em [`checkpoints/checkpoint-05/`](../../checkpoints/checkpoint-05/).
