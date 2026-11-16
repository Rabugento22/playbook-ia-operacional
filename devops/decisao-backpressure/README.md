---
nome: Decisão de backpressure
descricao: Compara pelo menos três caminhos para segurar o excesso de carga em um barramento de eventos, pesando prós e contras contra as restrições do cenário antes de recomendar.
versao: 1.0.0
tags: [backpressure, arquitetura, decisao, filas]
inputs:
  - nome: cenario
    descricao: Estado atual do sistema (throughput, picos, retenção, consumidores) e as restrições do time (SLAs, orçamento, perda de dados)
---

# Decisão de backpressure

## Objetivo

Apoiar uma decisão de arquitetura cara e sem resposta única: como segurar o excesso de carga em um barramento de eventos. O prompt recebe o cenário em `{{cenario}}` (estado e restrições) e leva o modelo a reformular o cenário, fazer as contas que os dados permitem, propor pelo menos três caminhos com mecanismos diferentes, compará-los contra as restrições e só então recomendar, declarando os limites da análise.

## Quando usar

- Antes de escolher uma estratégia de backpressure, filas, priorização ou isolamento de tráfego.
- Para estruturar a discussão do time, e não para substituí-la: o raciocínio importa tanto quanto a recomendação.
- Com um cenário que traga carga, capacidade conhecida, SLAs, orçamento e restrições de perda de dados.

## Como usar

1. Escreva o cenário (estado atual e restrições) em texto simples, sem omitir o que é inaceitável para o time.
2. Copie o texto de [`prompt.md`](prompt.md) (depois do frontmatter) e troque `{{cenario}}`.
3. Execute em um modelo com raciocínio e **confira as contas**: nos testes, os dois modelos erraram unidades ou conceitos.

## Exemplo

Entrada: [`cenario-relay.txt`](../../checkpoints/checkpoint-04/entradas/cenario-relay.txt) (Relay, SLA de 60 s para o Sentinel, 15 min para o Forge, orçamento 8% acima, perda inaceitável). A saída completa dos dois modelos, via Ollama, está em [`03-execucao.md`](../../checkpoints/checkpoint-04/03-execucao.md). Trecho das contas do `gpt-oss:20b`:

```text
Excesso de carga: 320 000 – 180 000 = 140 000 msgs/s.  
Duração do pico: 25 min = 1 500 s.  
Volume acumulado no pico: 140 000 msgs/s × 1 500 s = 210 000 000 msgs (210 M).  
```

## Limitações

- **As recomendações dos modelos não são confiáveis sem revisão.** O `gpt-oss:20b` concluiu que o Sentinel precisaria consumir "≥ 3,5 M msgs/s", confundindo drenar o backlog em 60 s com o atraso máximo de 60 s; o `qwen3:14b` calculou o volume total do pico (480 M) em vez do excesso e recomendou combinar um caminho que admite descartar mensagens, mesmo com perda inaceitável.
- O cenário informa o throughput sustentado, não a capacidade máxima do barramento. O prompt manda tratá-la como incógnita; nos testes, só o `qwen3:14b` fez isso de forma explícita, e o `gpt-oss:20b` voltou a usar 180 k msgs/s como capacidade.
- O `qwen3:14b` ignorou a proibição de asteriscos (54 linhas da resposta com asteriscos); o `gpt-oss:20b` quase obedeceu (5 linhas).
- Os modelos afirmam que a solução fica "dentro do orçamento" sem custos no cenário para sustentar isso.
- Uma execução por modelo; a variação entre execuções não foi medida.

## Documentação do caminho

Contexto, evolução do prompt, execuções e curadoria estão em [`checkpoints/checkpoint-04/`](../../checkpoints/checkpoint-04/).
