# Curadoria

## Framework escolhido

**T-A-G** (Task, Action, Goal), o framework do curso para relatórios e análises. No prompt: a tarefa é apoiar a decisão de backpressure do cenário; as ações são as sete etapas (reformular, calcular, propor caminhos, detalhar, comparar, recomendar, declarar limites); o objetivo é a recomendação justificada, com os trade-offs e o que validar. O **R-I-S-E** (troubleshooting e incidentes), usado nos CP01 e CP03, foi descartado: aqui não há um incidente a diagnosticar, e sim uma decisão a comparar.

O prompt é genérico e não cita o Relay nem os caminhos do enunciado, para ser reutilizável e para o modelo propor os caminhos em vez de escolher entre os que recebe.

## O que foi refinado

1. **Placeholder (v1 → v2):** o `qwen3:14b` apagou o bloco do parâmetro, de novo (como no CP03). A solução foi pedir só o corpo do prompt e anexar o bloco `<cenario>{{cenario}}</cenario>` depois.
2. **Premissas e rigor (v2 → v3):** os modelos presumiram Kafka, não fizeram a conta do excesso de carga, "garantiram" SLAs sem mecanismo e declararam custo "dentro do orçamento" já estourado. Foram adicionadas regras: não presumir tecnologia, fazer as contas, justificar cada restrição, tratar a diferença de criticidade entre consumidores.
3. **Aritmética e conceitos (v3 → v4):** erros de unidade e de ordem de grandeza e a confusão entre carga observada e capacidade máxima levaram às regras de conferir unidades, distinguir carga de capacidade e checar a recomendação contra as contas.

A v3 e a v4 são refinos manuais meus sobre o texto gerado.

## O que a execução final mostra

O prompt cumpre o pedido do enunciado: os dois modelos comparam mais de um caminho, pesam prós e contras contra as restrições do cenário e só depois recomendam. A análise **não é confiável sem revisão**, e é isso que a curadoria precisa deixar claro:

| Ponto | `qwen3:14b` | `gpt-oss:20b` |
|-------|-------------|---------------|
| Caminhos | 3 (rate limiting com prioridade, escalar com mais retenção, buffer com backpressure) | 4 (escalar o barramento, backpressure nos produtores, isolar o tráfego do Sentinel, compressão e batch) |
| Contas | Volume total do pico (480 M) em vez do excesso; capacidade máxima declarada como incógnita | Excesso e tempo corretos (210 M; 19,4 min); concluiu que o Sentinel precisaria de 3,5 M msgs/s |
| Perda de mensagens | Caminho 1 admite descartar mensagens do Forge, marcado "não atende"; a recomendação o combina com o caminho 3 | Todos "atendem", apoiados na suposição de que os produtores têm buffer local |
| Orçamento | Descarta o caminho caro; afirma o resto "viável" sem custos | Afirma que o isolamento cabe "em poucos nós" sem base |
| Formato | Ignorou a proibição de asteriscos (54 linhas) | Quase obedeceu (5 linhas) |
| Limites declarados | Capacidade máxima não informada; orçamento | Capacidade máxima não informada; suposições listadas (produtores, roteador, capacidade) |

Pontos fortes dos dois: tabela comparativa por critério, plano de validação com teste de carga reproduzindo o pico de 320k msgs/s por 25 min e condições de revisão da decisão. Pontos fracos comuns: tratar o atraso máximo do Sentinel como tempo para esvaziar a fila, e afirmar "dentro do orçamento" sem custo algum nos dados.

## Limitações conhecidas

- **Duas execuções** (uma por modelo), com `temperature 0`; a variação entre execuções não foi medida.
- **A regra de conferir a recomendação contra as contas não impede o erro:** o `gpt-oss:20b` fez as contas certas e depois as contradisse na recomendação.
- **O prompt não ensina o conceito:** os modelos confundiram esvaziar o backlog com respeitar o limite de atraso, e o prompt só manda conferir a coerência, e não explica a diferença.
- O prompt pode levar a caminhos que o time não controla (como desacelerar produtores), e o modelo apenas aponta isso como condição.
- O valor está em estruturar a decisão e expor o que precisa ser validado; a escolha continua sendo humana.
