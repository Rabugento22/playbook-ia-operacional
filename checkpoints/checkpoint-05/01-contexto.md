# Contexto

## O Forge e a mudança

O Forge é o pipeline de dados da Aegis: pega o telemetry e o transforma em tabela consultável. Hoje roda em lote (de hora em hora), como o Steve Rogers montou anos atrás. O Bruce Banner quer um modelo orientado a eventos, em que o Forge consome cada evento do Relay quando ele chega e processa quase em tempo real.

O cenário recebido, em [`entradas/cenario-forge.txt`](entradas/cenario-forge.txt):

````text
Forge hoje:
- ingestão: um job em cron acorda a cada 60min (o "forge-batch-ingest")
- transformação: 14 etapas de processamento encadeadas (em Spark), ~40min no total
- destino: grava em tabelas no data warehouse, particionadas por hora
- ponto frágil: se um lote falha, o próximo acumula o dobro de volume
- quem depende do Forge: Sentinel (lê as tabelas agregadas), Cerebro (indexa
  os eventos transformados) e os relatórios de billing da Pepper (rodam de madrugada)

O que a migração precisa garantir:
- consumir do Relay continuamente, processando em pequenos blocos no lugar do lote de 1h
- manter quem depende do Forge funcionando durante a transição
- nada de virada única (big-bang): a migração tem que ir em passos e poder voltar atrás
````

## As garantias da migração

O cenário declara três garantias, que atravessam toda a cadeia:

1. Consumir do Relay continuamente, processando em pequenos blocos no lugar do lote de 1h.
2. Manter quem depende do Forge funcionando durante a transição.
3. Nada de virada única (big-bang): a migração tem que ir em passos e poder voltar atrás.

## Por que uma cadeia e não um prompt só

A mudança é grande demais para um prompt: um pedido único tende a sair raso e genérico. O enunciado propõe encadear: um prompt diagnostica o estado atual, o seguinte propõe o passo a passo e o terceiro detalha o plano executável e reversível. **O ganho de uma cadeia sobre um prompt único não foi medido neste checkpoint.**

## Desenho da cadeia

| Elo | Entrada | Saída |
|-----|---------|-------|
| 1. Diagnóstico | `cenario` | Garantias literais, estado atual, dependentes, pontos frágeis, o que muda, invariantes, lacunas |
| 2. Plano | `cenario` + `diagnostico` | Fases incrementais e reversíveis, troca de fonte por dependente, convivência, riscos, decisões em aberto |
| 3. Execução | `cenario` + `plano` | Roteiro por fase com passos, verificação, go/no-go e rollback; proteção dos dependentes; checklist final |

O `cenario` entra em todos os elos para que as garantias originais não se percam ao longo da cadeia. Cada elo recebe a saída real do anterior, sem edição.

## O que o cenário não informa

- Volume de dados por lote e taxa de chegada no Relay.
- O que Sentinel, Cerebro e o billing toleram (atraso, duplicidade, ordem); o cenário só diz que o billing roda de madrugada.
- Como o Relay entrega os eventos (garantias de ordem e de entrega).
- Quais ferramentas o time quer usar; o prompt não presume nenhuma.

## Privacidade

O cenário é fictício e não contém dados de clientes. As execuções foram locais.
