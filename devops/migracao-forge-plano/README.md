---
nome: Migração de lote para eventos, elo 2: plano em fases
descricao: A partir do cenário e do diagnóstico, monta um plano de migração em fases incrementais e reversíveis, com a troca de fonte de cada dependente, como entrada do roteiro executável.
versao: 1.0.0
tags: [migracao, engenharia-de-dados, plano, cadeia-de-prompts]
inputs:
  - nome: cenario
    descricao: Estado atual do pipeline em lote e o que a migração precisa garantir
  - nome: diagnostico
    descricao: Saída do elo 1 da cadeia (migracao-forge-diagnostico)
---

# Migração de lote para eventos, elo 2: plano em fases

## Objetivo

Segundo elo da cadeia. Recebe o cenário em `{{cenario}}` e o diagnóstico em `{{diagnostico}}` e monta um plano em fases incrementais, sem virada única, com a troca de fonte de cada dependente, critérios de entrada e de saída com evidência, convivência entre o modelo antigo e o novo, e como voltar atrás em cada fase.

## Posição na cadeia

- Elo 2 de 3. Recebe a saída do [`migracao-forge-diagnostico`](../migracao-forge-diagnostico/) em `{{diagnostico}}`.
- A saída segue para o parâmetro `{{plano}}` do [`migracao-forge-execucao`](../migracao-forge-execucao/).

A cadeia existe porque a migração é grande demais para um prompt só: cada elo faz uma coisa e entrega uma saída estruturada ao seguinte.

## Quando usar

Depois do diagnóstico, para propor a sequência de fases a discutir com o time.

## Como usar

1. Copie o texto de [`prompt.md`](prompt.md) (depois do frontmatter).
2. Troque os placeholders pelos valores indicados no frontmatter; a saída do elo anterior entra sem edição.
3. Revise a saída antes de passar ao próximo elo: erros se propagam pela cadeia.

## Exemplo

Trecho real da saída do `gpt-oss:20b` (via Ollama), executando a cadeia sobre o cenário do Forge ([`cenario-forge.txt`](../../checkpoints/checkpoint-05/entradas/cenario-forge.txt)):

```text
Fase 6 – Trocar dependente Relatórios de billing da Pepper  
Objetivo: fazer os relatórios ler a tabela de saída.  
O que muda: alteração de configuração de leitura dos relatórios.  
O que permanece: pipeline antiga continua produzindo dados na tabela antiga.  
Dependentes afetados: Relatórios de billing.  
Janelas protegidas: janela de consumo de relatórios (suposição de madrugada). Respeito: troca fora da madrugada.  
```

As execuções completas dos dois modelos estão em [`03-execucao.md`](../../checkpoints/checkpoint-05/03-execucao.md).

## Limitações

- O `qwen3:14b` incluiu números como limiares (10%, 50%) mesmo com a regra de escrever "limiar a definir"; o `gpt-oss:20b` não.
- Os dois planos respeitam a janela de madrugada do billing, mas o `qwen3:14b` a justifica de forma fraca ("os dados não são consumidos durante esse período") e o `gpt-oss:20b` repete "suposição" do diagnóstico.
- O descomissionamento do modelo antigo (última fase) tem o rollback mais frágil: restaurar o que foi removido depende de backups que o plano só menciona.
- Uma execução da cadeia por modelo; a variação entre execuções não foi medida.
- **Teste (CP10):** `promptfooconfig.yaml` verifica títulos, formato e fatos da saída, sem avaliar a qualidade do raciocínio; a proibição de asteriscos reprova com o `qwen3:14b`. Detalhes em [`checkpoint-10`](../../checkpoints/checkpoint-10/).

## Documentação do caminho

Contexto, evolução dos prompts, execuções e curadoria estão em [`checkpoints/checkpoint-05/`](../../checkpoints/checkpoint-05/).
