---
nome: Migração de lote para eventos, elo 1: diagnóstico
descricao: Diagnostica o estado atual de um pipeline em lote e lista as garantias, os dependentes, os pontos frágeis, os invariantes e as lacunas, como entrada do plano de migração para eventos.
versao: 1.0.0
tags: [migracao, engenharia-de-dados, diagnostico, cadeia-de-prompts]
inputs:
  - nome: cenario
    descricao: Estado atual do pipeline em lote e o que a migração precisa garantir
---

# Migração de lote para eventos, elo 1: diagnóstico

## Objetivo

Primeiro elo da cadeia de migração de um pipeline de lote para eventos. Recebe o cenário em `{{cenario}}` e devolve um diagnóstico estruturado: as garantias literais do cenário, o estado atual, o que cada dependente espera (e o que **não** está declarado), os pontos frágeis, o que muda do lote para eventos, os invariantes e as lacunas.

## Posição na cadeia

- Elo 1 de 3. É o primeiro elo; não recebe saída de outro prompt.
- A saída segue para o parâmetro `{{diagnostico}}` do [`migracao-forge-plano`](../migracao-forge-plano/).

A cadeia existe porque a migração é grande demais para um prompt só: cada elo faz uma coisa e entrega uma saída estruturada ao seguinte.

## Quando usar

Antes de planejar a migração: para alinhar o time sobre o que existe, quem depende e o que ainda não se sabe.

## Como usar

1. Copie o texto de [`prompt.md`](prompt.md) (depois do frontmatter).
2. Troque os placeholders pelos valores indicados no frontmatter; a saída do elo anterior entra sem edição.
3. Revise a saída antes de passar ao próximo elo: erros se propagam pela cadeia.

## Exemplo

Trecho real da saída do `gpt-oss:20b` (via Ollama), executando a cadeia sobre o cenário do Forge ([`cenario-forge.txt`](../../checkpoints/checkpoint-05/entradas/cenario-forge.txt)):

```text
Janelas de consumo  
1. Sentinel – janela não declarada  
2. Cerebro – janela não declarada  
3. Relatórios de billing da Pepper – janela não declarada (suposição de madrugada)  
```

As execuções completas dos dois modelos estão em [`03-execucao.md`](../../checkpoints/checkpoint-05/03-execucao.md).

## Limitações

- Os dois modelos escreveram o diagnóstico sem tecnologia nomeada e com "não declarado" para as tolerâncias dos dependentes, mas o `qwen3:14b` ainda usou negrito.
- A seção Janelas de consumo levou a madrugada do billing até o plano e o roteiro nos dois modelos, mas o `gpt-oss:20b` a registrou como "suposição", embora o cenário a declare.
- Uma execução da cadeia por modelo; a variação entre execuções não foi medida.

## Documentação do caminho

Contexto, evolução dos prompts, execuções e curadoria estão em [`checkpoints/checkpoint-05/`](../../checkpoints/checkpoint-05/).
