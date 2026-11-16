# Curadoria

## Framework escolhido

**R-I-S-E** (Role, Input, Steps, Expectation), o framework do curso para operações, troubleshooting e incidentes. No prompt: o papel é o engenheiro de observabilidade; o input são os três artefatos, delimitados no fim; os passos são a sequência linha do tempo, causa-raiz, mecanismo, efeitos, correlações, confiança, limitações e ações; a expectativa é o formato de saída com seções fixas. O **T-A-G** (Task, Action, Goal, para relatórios e análises) foi considerado, mas não dá estrutura à sequência de raciocínio que a análise de causa-raiz exige.

O prompt é genérico e não cita o Cerebro nem a reindexação: o time reusa trocando só o pacote, e citar a resposta no prompt tornaria o teste do CP09 trivial.

## O que foi refinado

1. **Estrutura dos parâmetros (v1 → v3):** os placeholders apareciam em vários pontos, depois foram apagados, e só ficaram corretos na terceira rodada, quando o gerador foi trocado para o `gpt-oss:20b` e o bloco final foi especificado. O `qwen3:14b` ignorou o feedback duas vezes seguidas.
2. **Redação e definições (v3 → v4):** texto truncado, hífens não padrão, correlação sem definição, ausência de regra de evidência e de estilo.
3. **Raciocínio (v4 → v5):** a v4 deixava o `qwen3:14b` com confiança alta sem checar o que a hipótese não explica, e levava os dois modelos a ler mal horários e direção das métricas. A v5 exige testar a hipótese contra todos os dados, um único grau de confiança, ações reversíveis em "conter agora" e leitura correta do tempo.

A v4 e a v5 são refinos manuais meus sobre o texto gerado, porque a geração por modelo não incorporou o feedback.

## Efeito da v5 sobre a v4

| Ponto | `qwen3:14b` | `gpt-oss:20b` |
|-------|-------------|---------------|
| Confiança | Alta → **Média**, com a admissão de que a hipótese "não explica por que o reindex job está tomando tanto tempo" | Duas confianças ao mesmo tempo → uma (Alta), mas justificada com "nenhum dado relevante contradiz", o que não procede |
| Vazão de indexação | Continua tratada como etapa do mecanismo, sem explicar por que dobrou | Leitura invertida (queda de 12.400 para 11.200) **corrigida** |
| Início da reindexação | Correto (02:00) | **Continua errado**: "iniciado em 08:02", apesar da regra |
| Ações em "conter agora" | Sem o número "8 GB → 16 GB", mas ainda sugere aumentar a memória da JVM | Pede aumentar o pool de escrita e reiniciar o nó |

## Avaliação das saídas finais

A leitura abaixo é minha, contra os quatro critérios que o CP09 vai formalizar. Não é a calibração do juiz (que exige as notas do Rubens), e por isso não uso notas.

| Critério | `qwen3:14b` | `gpt-oss:20b` |
|----------|-------------|---------------|
| Causa-raiz correta | Parcial: chega à reindexação prolongada saturando recursos, passando por GC, throttling, circuit breaker e p99; chama de "mal dimensionada" sem base | Parcial: cadeia de 9 etapas completa (heap, GC, throttling, fila, circuit breaker, timeouts, exceções), mas atribui à reindexação a alta vazão e erra o início |
| Correlação × causa | Parcial: o cache é tratado como correlação, não como causa, mas não aparece nos efeitos; afirma crescimento "exponencial" sem base | Melhor: o cache está nos efeitos; as correlações são declaradas; erra ao citar o horário de início do job como "correlação" |
| Ação proporcional | Parcial: interromper a reindexação é o certo e reversível; aumentar a memória e rever shards e réplicas passam do que a evidência sustenta | Parcial: pausar a reindexação é o certo, mas reiniciar o nó, mexer no pool e no `refresh_interval` sem evidência é maior; "reagendar para 02:00" já é o agendamento |
| Honestidade epistêmica | Melhor dos dois: confiança média e a lacuna dita com clareza; não aponta que a vazão dobrada fica sem explicação | Lista longa de limitações, mas confiança alta e a afirmação falsa de que nenhum dado contradiz |

Em síntese: nenhum dos dois é um diagnóstico final, e os dois acertam o essencial (a reindexação travada pressionando o heap). O `qwen3:14b` é mais honesto sobre o que não sabe; o `gpt-oss:20b` é mais completo na cadeia e no tratamento do cache, mas sobreconfiante.

## Resultado da sanitização

Com `NODE-A`, `INDEX-A` e `TASK-1` no lugar dos três identificadores, o `qwen3:14b` chegou à mesma causa-raiz (reindexação prolongada), à mesma confiança (média, com a mesma ressalva) e às mesmas ações (interromper a reindexação, reduzir a taxa de indexação), e nenhum identificador original apareceu na saída. Conclusão: mascarar nó, índice e tarefa não degrada a análise, e deve ser feito antes de enviar a um modelo externo.

## Limitações conhecidas

- **Uma execução por modelo**, com `temperature 0`. A comparação v4 contra v5 mistura o efeito do prompt com a variação entre execuções, que não foi medida.
- **A v5 reduz, mas não elimina, os erros de leitura:** o `gpt-oss:20b` repetiu o horário de início errado mesmo com a regra explícita.
- **A sanitização foi verificada em um modelo** e com três identificadores; em produção há mais tipos de dado sensível (ver [contexto](01-contexto.md)).
- O prompt não impede o modelo de propor ações fora de proporção; ele só pede que se evitem. A revisão humana continua necessária.
- Os dados cobrem um único nó; a conclusão para o cluster inteiro é uma hipótese.
