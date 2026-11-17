# Pontuação de referência

## Quem pontuou

**Estas notas foram dadas pelo Claude, a pedido do Rubens, e não pelo Rubens.** O enunciado do CP09 pede que o próprio aluno pontue as saídas; o Rubens delegou a tarefa. Duas ressalvas que afetam a calibração:

- As notas de referência vêm de um modelo, não de um humano. A calibração mede a distância entre o juiz e o Claude. Para valer como calibração humana, as notas precisam ser revistas pelo Rubens (ver "Revisão pendente" abaixo).
- O Claude já tinha visto os totais da primeira rodada do juiz (A 8, B 8, C 6, D 4, E 8, F 8, G 8, H 8) antes de pontuar. Os totais não foram usados na pontuação, que seguiu os descritores de [`02-rubrica.md`](../02-rubrica.md) lendo cada amostra, mas a pontuação não foi cega.

## Notas (C1 causa-raiz, C2 correlação × causa, C3 ação, C4 honestidade)

| Amostra | C1 | C2 | C3 | C4 | Total | Aprovada | Por quê |
|---|---|---|---|---|---|---|---|
| A | 1 | 1 | 1 | 0 | 3 | não | Aponta a carga de indexação como causa e trata a reindexação como parte dela (C1=1). Não separa o cache e o circuit breaker como efeitos nem trata correlação (C2=1). Sem contenção reversível; sugere aumentar o heap e reduzir o escopo (C3=1). Sem limitações e com valores errados ("3,5 horas", "7 a 9 GB de 8 GB") (C4=0). |
| B | 1 | 2 | 2 | 2 | 7 | sim | Liga a reindexação ao heap, ao circuit breaker e aos timeouts, mas diz que não há dado da duração real, embora o log mostre 38% a 41% (C1=1). Cache como efeito e correlação declarada sem prova (C2=2). Pausa a reindexação como contenção e separa a correção posterior (C3=2). Limitações concretas e confiança média justificada (C4=2). |
| C | 1 | 1 | 1 | 1 | 4 | não | Causa-raiz é o heap de 8 GB, com a reindexação ao lado (C1=1). Efeitos e correlações só repetem sintomas (C2=1). A primeira ação é subir o heap para 16 GB (C3=1). Confiança alta, limitações genéricas e leitura errada de valores do log (C4=1). |
| D | 0 | 0 | 0 | 0 | 0 | não | Lista sintomas, sem causa-raiz (C1=0). Sugere ajustar o cache e o circuit breaker, o que é efeito (C2=0). Ações sem relação com a reindexação (C3=0). Sem nenhuma limitação (C4=0). |
| E | 1 | 0 | 1 | 0 | 2 | não | Seis "causas principais", entre elas o cache, o thread pool e o circuit breaker (C1=1, C2=0). Muitas mudanças estruturais, e a primeira medida é reiniciar o job (C3=1). Sem limitações e com parâmetros inventados (C4=0). |
| F | 1 | 1 | 2 | 1 | 5 | não | Reindexação "mal gerenciada" combinada com carga e recursos (C1=1). Efeitos listados, mas o cache entra no mecanismo (C2=1). Suspende a reindexação como contenção (C3=2). Limitações concretas, mas confiança alta e linha do tempo com leituras erradas (C4=1). |
| G | 1 | 0 | 1 | 0 | 2 | não | Quatro "causas raiz", entre elas o cache e o refresh interval (C1=1, C2=0). Só aumenta recursos e muda parâmetros (C3=1). Sem limitações (C4=0). |
| H | 2 | 2 | 2 | 1 | 7 | sim | Reindexação como condição inicial, com a cadeia até as falhas de busca, embora com horário de início errado (C1=2). Cache como efeito e correlação sem prova (C2=2). Pausa a reindexação e deixa o heap para depois (C3=2). Limitações concretas, mas confiança alta (C4=1). |

## Revisão pendente

O Rubens pode revisar qualquer nota. As mais discutíveis: B/C1 e F/C1 (se "reindexação combinada com outros fatores" é 1 ou 2), B/C4 e H/C4 (confiança média contra alta) e F, que ficou em 5, um ponto abaixo do corte. Se alguma nota mudar, a comparação de [`03-execucao.md`](../03-execucao.md) e a curadoria precisam ser refeitas.
