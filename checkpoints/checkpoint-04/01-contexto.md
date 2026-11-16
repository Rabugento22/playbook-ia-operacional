# Contexto

## Cenário

O Relay é o barramento de eventos por onde passa todo o telemetry dos clientes. Quando um cliente grande dispara muito mais dados que o normal, o Relay recebe mais do que entrega, a fila acumula, o Sentinel atrasa e o alerta que deveria sair na hora também. O Tony Stark (CTO) quer uma estratégia de backpressure. Não existe resposta única: cada caminho tem um preço.

O cenário recebido pelo prompt, em [`entradas/cenario-relay.txt`](entradas/cenario-relay.txt):

````text
Relay (barramento de eventos):
- throughput sustentado: 180k msgs/s
- pico observado no incidente da semana passada: 320k msgs/s por 25min
- retenção atual: 4h
- consumidores: Forge (ingestão), Sentinel (alerting em tempo real)

Restrições do time:
- alerting do Sentinel não pode atrasar mais que 60s (SLA com cliente)
- ingestão do Forge pode atrasar até 15min sem violar SLA
- orçamento de infra do trimestre já está 8% acima do previsto
- Steve Rogers lembra que o barramento antigo perdia mensagens sob pico,
  e perda de telemetry é inaceitável para um produto de observabilidade
````

## As tensões que o prompt precisa fazer o modelo pesar

| Tensão | Dados |
|--------|-------|
| Criticidades diferentes | Sentinel: atraso máximo de 60 s (SLA com cliente). Forge: até 15 min sem violar SLA |
| Orçamento | Já 8% acima do previsto: ampliar infra não é gratuito |
| Perda de dados | Inaceitável; o barramento antigo perdia mensagens sob pico, e isso exclui qualquer caminho que descarte dados |
| Folga de retenção | 4 h de retenção, contra um pico de 25 min |

## O que o cenário não informa

- **A capacidade máxima do Relay.** O dado de 180k msgs/s é o throughput sustentado (a carga normal), e não o limite do sistema. Qualquer conta de "tempo para recuperar o atraso" depende dessa capacidade.
- Quanto do tráfego vem de cada cliente (se um único cliente concentra o pico).
- Se os produtores aceitam ser desacelerados ou têm buffer próprio.
- Quanto custa cada caminho.

Contas que os dados permitem: o excesso no pico é de 320k − 180k = 140k msgs/s por 25 min (1.500 s), ou seja, 210 milhões de mensagens acima da carga normal; a retenção de 4 h equivale a 14.400 s.

## Caminhos em discussão (enunciado)

Priorizar o Sentinel na frente do Forge; guardar o que não foi processado em uma fila separada (dead-letter queue); dividir o Relay por cliente; aumentar automaticamente o número de consumidores. Podem ser combinados. O prompt **não** recebe essa lista: o objetivo é que o modelo proponha e compare caminhos a partir do cenário.

## O que o prompt precisa fazer

Receber o cenário por parâmetro (`{{cenario}}`) e produzir uma análise comparativa que mostre o raciocínio, e não só uma recomendação. O prompt é genérico (não cita o Relay), para reuso em outros barramentos ou filas.

## Privacidade

O cenário é fictício e não contém dados de clientes. Em produção, avalie se nomes de clientes ou de tenants citados no cenário precisam ser mascarados antes de enviar a um modelo externo; as execuções deste checkpoint foram locais.
