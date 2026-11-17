# Rubrica

Os quatro critérios e a escala vêm do enunciado do CP09 e não foram alterados. Os **descritores de cada nota** (o que separa 0, 1 e 2) são nossos: o enunciado dá só "0 = não atende, 1 = parcial, 2 = atende", e um juiz precisa de âncoras para dar a mesma nota duas vezes.

## O caso avaliado

A saída do prompt [`devops/causa-raiz`](../../devops/causa-raiz/) para os artefatos do [checkpoint 03](../checkpoint-03/) (degradação do Cerebro). O que os dados sustentam:

- A reindexação agendada às 02:00 (tarefa `88123`, 10 milhões de documentos, normalmente 90 minutos) estava em 41% às 10:00 e quase não avançou na janela (38%, 40%, 41%).
- O heap subiu de 61% para 94%; o circuit breaker de memória disparou a 96% (09:58); o pool de escrita encheu e rejeitou bulk; as buscas estouraram o timeout de 5 s e devolveram resultado parcial (11 de 12 shards).
- O cache de query caiu de 74% para 29% de acerto: é efeito da pressão de memória, não causa.
- Os dados **não** dizem por que a reindexação andou tão devagar, nem de onde veio a alta de vazão de indexação (de 4.100 para 12.400 docs/s a partir das 09:00), e não trazem CPU, disco, tamanho de segmentos nem logs de outros nós.

## Critérios, escala de 0 a 2

| # | Critério | 0: não atende | 1: parcial | 2: atende |
|---|----------|---------------|------------|-----------|
| 1 | **Causa-raiz correta** | Aponta como causa-raiz um sintoma (latência, timeout, queda do cache, circuit breaker, heap alto) ou uma causa que os dados não sustentam | Cita a reindexação travada, mas como um fator entre vários, sem dizer que ela é a condição inicial; ou aponta a pressão de memória como causa sem ligá-la à reindexação | Aponta a reindexação travada ou lenta como condição inicial e a liga, em cadeia, à saturação do heap, ao circuit breaker e aos timeouts de busca |
| 2 | **Correlação × causa** | Trata um efeito como causa (por exemplo, o cache hit baixo explicando a lentidão), ou não separa causa de consequência | Separa os efeitos principais, mas mistura correlação com causalidade em algum ponto, ou não separa o que é apenas correlação | Trata a queda do cache (e a latência) como efeito e diz expressamente o que varia junto sem que a relação causal esteja demonstrada (por exemplo, o salto da vazão de indexação) |
| 3 | **Ação proporcional** | Ação sem relação com o diagnóstico, ou destrutiva e desproporcional (apagar o índice, reiniciar o cluster inteiro como primeira medida) | Ação coerente com o diagnóstico, mas sub ou superdimensionada: só "monitorar", ou uma mudança estrutural (aumentar o cluster) como primeiro passo, sem uma contenção reversível | Contenção reversível e de menor alcance ligada à causa (pausar, reagendar ou limitar a reindexação) e correção posterior separada (rever heap, limites, agenda) |
| 4 | **Honestidade epistêmica** | Afirma a causa com certeza total, sem limitações, ou inventa dados que não estão nos artefatos | Reconhece limitações de forma genérica ("faltam dados") sem dizer quais, ou dá confiança sem justificar | Diz o que os dados não permitem concluir (por que a reindexação andou devagar, a origem da vazão, o heap já em 61% antes, a falta de CPU, disco e outros nós) e dá um grau de confiança justificado |

## Aprovação

- **Nota total** = soma dos quatro critérios, de 0 a 8.
- **Aprovada** quando a nota total é **maior ou igual a 6** e **nenhum critério é 0**.
- Reprovada em qualquer outro caso, mesmo com total 6 ou mais (por exemplo, 2, 2, 2, 0 reprova).

## Como o juiz usa a rubrica

O juiz recebe a rubrica, os fatos do caso e a saída a avaliar, e devolve as quatro notas com uma justificativa curta de cada uma. O total e a aprovação são calculados a partir das notas; o texto que o juiz escreve sobre aprovar ou reprovar não conta. Isso evita que o juiz some errado. O arquivo de configuração e o texto do juiz estão em `devops/causa-raiz/promptfooconfig.yaml` (ver o fim deste arquivo, depois da configuração).
