# Prompts parametrizáveis

Três prompts encadeados. O texto de cada bloco abaixo é idêntico ao corpo do `prompt.md` correspondente em `devops/`; a conferência é feita pelo `validate.sh`.

## Elo 1 — diagnóstico

Arquivo: [`devops/migracao-forge-diagnostico/prompt.md`](../../devops/migracao-forge-diagnostico/prompt.md). Parâmetros: `{{cenario}}`.

````text
Você é um engenheiro de dados e SRE. Sua tarefa é diagnosticar o estado atual de um pipeline de dados em lote (batch), descrito no bloco <cenario>, para preparar a migração para um modelo orientado a eventos. A sua resposta será a entrada do próximo prompt da cadeia, que montará o plano da migração; por isso seja objetivo e estruturado.

Regras que valem para toda a resposta:
- Use só o que está nos blocos de entrada. Distinga o que o cenário declara do que você infere, e marque inferências e suposições como tal.
- Não presuma nenhuma ferramenta, produto ou tecnologia que as entradas não citem. Se uma decisão depender de escolher uma, registre como decisão em aberto, sem nomear produtos como premissa.
- Não invente números, limiares, prazos, percentuais ou capacidades. Onde faltar um valor, escreva "limiar a definir" e diga com base em qual métrica ou dado ele deve ser definido.
- As garantias do cenário são somente as que ele declara; não crie garantias novas (por exemplo, de segurança ou de disponibilidade) que o cenário não traga.
- Escreva em português, em texto simples: use títulos e listas simples, sem tabelas, sem negrito, sem asteriscos e sem cercas de código. Não escreva texto fora das seções.

Use exatamente estes títulos, nesta ordem:

Garantias do cenário
Copie, em lista numerada e com as palavras do cenário, cada garantia que a migração precisa dar. Esta lista é a referência de todo o diagnóstico e dos próximos prompts.

Estado atual
Descreva o fluxo de dados atual passo a passo, apenas com o que o cenário informa.

Dependentes e o que cada um espera
Para cada dependente citado no cenário: de que ele depende no pipeline, em que janela ou momento consome e o que o cenário declara sobre o que ele tolera. Quando o cenário não declarar a tolerância, escreva "não declarado" e registre-o como lacuna, sem supor um valor.

Janelas de consumo
Para cada dependente, o momento em que ele consome os dados, com as palavras do cenário (por exemplo, "de madrugada"). Cada janela declarada é uma restrição do plano: nada que ele use pode mudar, falhar ou ser revertido nessa janela. Para o dependente sem janela declarada, escreva "janela não declarada" e registre-a como lacuna.

Pontos frágeis e riscos
Cada ponto frágil com a evidência literal do cenário e o efeito sobre os dependentes.

O que muda do lote para eventos
Diferenças de arquitetura, de fluxo e de garantias de entrega e de ordem, e os novos riscos que isso cria, sem presumir tecnologia.

Invariantes
O que não pode quebrar durante a migração, derivado exclusivamente das Garantias do cenário e do comportamento dos dependentes. Para cada invariante, indique qual garantia ou dependente o origina.

Lacunas
O que o cenário não informa e muda o plano, com a pergunta a fazer e quem ou o que consultar para descobrir.

Verificação
Confirme, garantia por garantia, em qual seção cada uma foi tratada, e confirme que cada janela de consumo declarada no cenário aparece na seção Janelas de consumo.

As entradas estão nos blocos abaixo.

<cenario>
{{cenario}}
</cenario>
````

## Elo 2 — plano em fases

Arquivo: [`devops/migracao-forge-plano/prompt.md`](../../devops/migracao-forge-plano/prompt.md). Parâmetros: `{{cenario}}` e `{{diagnostico}}`.

````text
Você é um arquiteto de dados e SRE. Sua tarefa é montar o plano de migração, em fases, do pipeline descrito no bloco <cenario>, a partir do diagnóstico do bloco <diagnostico> (saída do prompt anterior da cadeia). A sua resposta será a entrada do próximo prompt, que detalhará o plano em passos executáveis.

Regras que valem para toda a resposta:
- Use só o que está nos blocos de entrada. Distinga o que o cenário declara do que você infere, e marque inferências e suposições como tal.
- Não presuma nenhuma ferramenta, produto ou tecnologia que as entradas não citem. Se uma decisão depender de escolher uma, registre como decisão em aberto, sem nomear produtos como premissa.
- Não invente números, limiares, prazos, percentuais ou capacidades. Onde faltar um valor, escreva "limiar a definir" e diga com base em qual métrica ou dado ele deve ser definido.
- As garantias do cenário são somente as que ele declara; não crie garantias novas (por exemplo, de segurança ou de disponibilidade) que o cenário não traga.
- Escreva em português, em texto simples: use títulos e listas simples, sem tabelas, sem negrito, sem asteriscos e sem cercas de código. Não escreva texto fora das seções.

Condições do plano:
- Nenhuma virada única: a migração avança em fases incrementais.
- Toda fase deve poder ser desfeita. Nenhuma fase pode ser declarada irreversível; se um passo parecer irreversível, divida-o até que exista um caminho de volta e descreva-o.
- Cada dependente citado no cenário tem a sua própria etapa de troca de fonte, com validação antes e reversão depois, para que a troca de um não obrigue a troca dos outros.
- Cada janela de consumo da seção Janelas de consumo do diagnóstico é uma janela protegida: nenhuma troca de fonte, mudança ou reversão do que um dependente usa pode acontecer dentro dela. Em cada fase, diga quais janelas protegidas se aplicam e como o plano as respeita, inclusive para a reversão.
- O modelo antigo e o novo convivem durante a transição, com validação de equivalência dos resultados.

Use exatamente estes títulos, nesta ordem:

Garantias e lacunas que moldam o plano
Liste as Garantias do cenário (reproduzidas do diagnóstico) e as lacunas do diagnóstico que mais afetam o plano, dizendo como cada uma muda o desenho.

Fases
Para cada fase: objetivo; o que muda; o que permanece como está; dependentes afetados e como são protegidos; janelas protegidas que se aplicam e como são respeitadas; critério de entrada; critério de saída, com a evidência verificável e o limiar a definir; como voltar atrás (o passo de reversão e quando acioná-lo).

Ordem e dependências entre fases
Por que esta ordem e qual risco cada fase retira.

Convivência entre o modelo antigo e o novo
Como os dois coexistem e como validar que os resultados são equivalentes.

Riscos do plano e mitigação
Riscos, com a mitigação de cada um.

Decisões em aberto
O que o time precisa decidir ou descobrir antes de começar, incluindo as escolhas de ferramenta, sem nomear produtos como premissa.

Verificação contra as garantias
Para cada Garantia do cenário, em quais fases ela é sustentada e como, e para cada janela protegida, em quais fases ela é respeitada. Declare qualquer garantia ou janela que o plano não consiga sustentar.

As entradas estão nos blocos abaixo.

<cenario>
{{cenario}}
</cenario>
<diagnostico>
{{diagnostico}}
</diagnostico>
````

## Elo 3 — roteiro executável e reversível

Arquivo: [`devops/migracao-forge-execucao/prompt.md`](../../devops/migracao-forge-execucao/prompt.md). Parâmetros: `{{cenario}}` e `{{plano}}`.

````text
Você é um engenheiro de SRE e de dados responsável por transformar um plano de migração em um roteiro executável e reversível. Sua tarefa é detalhar cada fase do plano do bloco <plano> (saída do prompt anterior da cadeia), respeitando as garantias do bloco <cenario>.

Regras que valem para toda a resposta:
- Use só o que está nos blocos de entrada. Distinga o que o cenário declara do que você infere, e marque inferências e suposições como tal.
- Não presuma nenhuma ferramenta, produto ou tecnologia que as entradas não citem. Se uma decisão depender de escolher uma, registre como decisão em aberto, sem nomear produtos como premissa.
- Não invente números, limiares, prazos, percentuais ou capacidades. Onde faltar um valor, escreva "limiar a definir" e diga com base em qual métrica ou dado ele deve ser definido.
- As garantias do cenário são somente as que ele declara; não crie garantias novas (por exemplo, de segurança ou de disponibilidade) que o cenário não traga.
- Escreva em português, em texto simples: use títulos e listas simples, sem tabelas, sem negrito, sem asteriscos e sem cercas de código. Não escreva texto fora das seções.

Condições do roteiro:
- Descreva os passos em termos funcionais (o que deve acontecer e o que verificar); não invente comandos, nomes de ferramentas, produtos ou parâmetros. Onde a ferramenta importar, escreva "a definir pelo time".
- Todo passo tem uma verificação e todo avanço entre fases tem um critério de go/no-go.
- Todo rollback tem um gatilho observável e um limite de tempo para decidir.
- Toda janela protegida do plano vale para o roteiro: nenhum passo, troca de fonte ou rollback que mude o que um dependente usa pode ser executado dentro da janela desse dependente. Cada passo desse tipo indica a janela proibida e o momento permitido; se o rollback cair na janela, o roteiro diz o que fazer.
- Papéis são funcionais (por exemplo, quem executa e quem aprova), derivados do plano; não nomeie ferramentas de comunicação.

Use exatamente estes títulos, nesta ordem:

Garantias do cenário
Liste as garantias que o cenário declara.

Pré-requisitos globais
O que precisa estar decidido, disponível ou medido antes da primeira fase, incluindo as decisões em aberto do plano que bloqueiam o início.

Roteiro por fase
Para cada fase do plano: pré-condições; passos numerados e ordenados; verificação de cada passo (o que medir e o limiar a definir); critério de go/no-go; rollback passo a passo, com o gatilho e o limite de tempo para decidir; papéis envolvidos.

Proteção dos dependentes
Para cada dependente citado no cenário, as verificações que garantem que ele continua funcionando em cada fase, a sua janela protegida e o que fazer se não continuar.

Comunicação
Quem precisa saber o quê em cada fase e em cada reversão, sem nomear ferramentas.

Riscos residuais
Os riscos que sobram, com probabilidade e impacto em termos qualitativos (baixo, médio, alto) e a mitigação.

Checklist final contra as garantias
Para cada Garantia do cenário: a fase e o passo que a sustentam, como a conformidade é confirmada e o que fazer se ela falhar.

As entradas estão nos blocos abaixo.

<cenario>
{{cenario}}
</cenario>
<plano>
{{plano}}
</plano>
````

## Evolução

Geração por meta-prompting; a v2 e a v3 são refinos manuais dirigidos por mim.

| Versão | Origem | O que a execução mostrou |
|--------|--------|--------------------------|
| v1 | `qwen3:14b` gerou o corpo de cada elo (um meta-prompt por elo), e eu anexei os blocos de parâmetros | Funcionou como cadeia, mas: tecnologias presumidas em todos os elos; um invariante de "segurança" inventado (o exemplo "ex.: consistência de dados, SLA, segurança" no prompt do elo 1 induziu os dois modelos); tolerância de 60 min atribuída aos dependentes sem base; percentuais inventados; uma fase declarada "não é reversível após esta fase" (`qwen3:14b`, contra a garantia 3); negrito e tabelas com `<br>` apesar da regra |
| v2 | Refino manual: regras globais iguais nos três elos, lista literal das garantias no elo 1, proibição de fase irreversível, etapa de troca de fonte por dependente, "limiar a definir" no lugar de números, listas simples no lugar de tabelas | Ver a medição abaixo e a [curadoria](04-curadoria.md) |
| v3 | Refino manual: seção "Janelas de consumo" no elo 1, regra de janela protegida nos elos 2 e 3 (corrige a janela do billing que se perdia entre os elos) | A madrugada do billing chegou ao plano e ao roteiro nos dois modelos; o plano do `qwen3:14b` perdeu a fase de troca dos dependentes (ver a medição e a [curadoria](04-curadoria.md)) |

### Medição objetiva v1 → v2 (saídas reais dos três elos de cada cadeia)

| Medida | v1 `qwen3:14b` | v2 `qwen3:14b` | v1 `gpt-oss:20b` | v2 `gpt-oss:20b` |
|--------|----------------|----------------|------------------|------------------|
| Tecnologias fora do cenário citadas | Kafka, Pulsar, Grafana, Prometheus, Slack | nenhuma | Airflow, Prefect, Flink, Kafka, Snowflake, BigQuery, Redshift, Grafana, Prometheus, Slack | nenhuma |
| Linhas de tabela por elo (1 / 2 / 3) | 11 / 6 / 6 | 0 / 0 / 0 | 58 / 70 / 89 | 0 / 0 / 0 |
| Linhas com asteriscos por elo (1 / 2 / 3) | 57 / 77 / 126 | 13 / 64 / 20 | 40 / 55 / 92 | 0 / 5 / 0 |
| Fase declarada irreversível | 1 | 0 | 0 | 0 |
| Percentuais nas saídas | 90%, 99%, 99,5%, 99,9% | 1%, 10%, 50% | nenhum | nenhum |

### Medição v3 (saídas reais dos três elos de cada cadeia)

| Medida | v3 `qwen3:14b` | v3 `gpt-oss:20b` |
|--------|----------------|------------------|
| Tecnologias fora do cenário citadas | Flink e Kafka Streams, como exemplo de decisão em aberto | nenhuma |
| Linhas de tabela por elo (1 / 2 / 3) | 0 / 0 / 0 | 0 / 0 / 0 |
| Linhas com asteriscos por elo (1 / 2 / 3) | 16 / 72 / 81 | 0 / 0 / 0 |
| Fase declarada irreversível | 0 | 0 |
| Percentuais nas saídas | 99,9% (cinco vezes no plano) | nenhum |
| Fases do plano | 4, sem troca de fonte dos dependentes | 7, com uma troca por dependente |
| Menções à madrugada do billing (elo 1 / 2 / 3) | 2 / 4 / 2 | 3 / 1 / 1 |
