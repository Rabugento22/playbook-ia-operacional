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

O juiz pontua **um critério por vez**: o `promptfoo` faz quatro chamadas ao juiz por análise, uma para cada critério, com o descritor desse critério e as regras de rigor dele (`criterio-1.txt` a `criterio-4.txt`) dentro do texto geral do juiz (`juiz.txt`). A soma e a regra de aprovação **não** ficam com o juiz: saem do `gate.js`, que recebe as quatro notas e aprova quando a soma é ≥ 6 e nenhuma nota é 0. Os motivos desse desenho estão em [`04-curadoria.md`](04-curadoria.md): uma única chamada com os quatro critérios errava a soma e deixava o juiz copiar a rubrica como se fosse da análise.

O texto dos descritores nos arquivos é o da tabela acima, com as regras de rigor que a calibração acrescentou. Os arquivos abaixo são idênticos aos de `devops/causa-raiz/`; o `validate.sh` confere.

## Configuração do gate

Arquivo: [`devops/causa-raiz/promptfooconfig.yaml`](../../devops/causa-raiz/promptfooconfig.yaml)

````yaml
# Gate de qualidade do prompt causa-raiz com juiz LLM (CP09).
# Rodar a partir da raiz do repositório:
#   promptfoo eval -c devops/causa-raiz/promptfooconfig.yaml --no-cache -j 1
# O prompt gera a análise (qwen3:14b); o juiz (gpt-oss:20b) pontua cada um dos quatro critérios
# da rubrica de 0 a 2 (criterio-1.txt a criterio-4.txt, instruções em juiz.txt).
# Aprovação: total >= 6 e nenhum critério zerado.
# A regra está em gate.js (assertScoringFunction): soma das quatro notas >= 6 e nenhuma nota 0.
description: causa-raiz — gate de qualidade com LLM-as-judge (rubrica de 4 critérios, 0 a 2, corte 6)

prompts:
  - file://../../providers/carregar-prompt.js

providers:
  - id: file://../../providers/ollama-local.js
    label: qwen3:14b (Alibaba, via Ollama)
    config:
      model: qwen3:14b
      think: true
      temperature: 0
      num_ctx: 12288

defaultTest:
  # regra de aprovação: soma >= 6 e nenhum critério zerado (gate.js)
  assertScoringFunction: file://gate.js
  options:
    # o juiz: outra família que o gerador, para reduzir o favorecimento do próprio texto
    provider:
      id: file://../../providers/ollama-local.js
      label: gpt-oss:20b (OpenAI, via Ollama) — juiz
      config:
        model: gpt-oss:20b
        think: low
        temperature: 0
        num_ctx: 12288
    rubricPrompt: file://juiz.txt

tests:
  - description: degradação do Cerebro — reindexação travada, heap, circuit breaker e timeouts
    vars:
      prompt_dir: causa-raiz
      config: file://../../checkpoints/checkpoint-03/entradas/artefato-1-cerebro.yaml
      metricas: file://../../checkpoints/checkpoint-03/entradas/artefato-2-metricas.txt
      logs: file://../../checkpoints/checkpoint-03/entradas/artefato-3-logs.txt
    assert:
      - {type: llm-rubric, value: file://criterio-1.txt}
      - {type: llm-rubric, value: file://criterio-2.txt}
      - {type: llm-rubric, value: file://criterio-3.txt}
      - {type: llm-rubric, value: file://criterio-4.txt}
````

## Regra de aprovação

Arquivo: [`devops/causa-raiz/gate.js`](../../devops/causa-raiz/gate.js)

````javascript
// gate.js — regra de aprovação do CP09, aplicada às notas dos quatro critérios do juiz.
// Aprova quando a soma é >= 6 (de 8) e nenhum critério é 0.
// O promptfoo chama esta função com os resultados dos quatro llm-rubric (um por critério).
module.exports = (namedScores, context) => {
  const notas = context.componentResults.map((r) => Math.round(r.score));
  const total = notas.reduce((a, b) => a + b, 0);
  const zerados = notas.map((n, i) => (n === 0 ? `C${i + 1}` : null)).filter(Boolean);
  const pass = notas.length === 4 && total >= 6 && zerados.length === 0;
  const detalhe = notas.map((n, i) => `C${i + 1}=${n}`).join('; ');
  return {
    pass,
    score: total / 8,
    reason:
      `${detalhe}; total=${total}/8. ` +
      (pass
        ? 'Aprovada (total >= 6 e nenhum critério zerado).'
        : `Reprovada (${total < 6 ? 'total abaixo de 6' : ''}${total < 6 && zerados.length ? ' e ' : ''}${zerados.length ? 'critério zerado: ' + zerados.join(', ') : ''}).`),
  };
};
````

## Texto do juiz

Arquivo: [`devops/causa-raiz/juiz.txt`](../../devops/causa-raiz/juiz.txt). `{{rubric}}` recebe o critério e `{{output}}` recebe a análise.

````text
Você é um revisor sênior de resposta a incidentes. Você pontua UM critério de uma análise de causa-raiz, sem se deixar levar pelo tamanho, pelo tom ou pela formatação do texto.

Fatos do caso. Isto é a sua referência para conferir a análise e NÃO faz parte dela: nunca cite estes fatos como se a análise os tivesse dito.
- O sistema é um cluster de busca e indexação. Uma reindexação agendada às 02:00 (10 milhões de documentos, normalmente 90 minutos) estava em 41% às 10:00 e quase não avançou na janela (38% às 08:02, 40% às 09:20, 41% às 09:58).
- O heap subiu de 61% para 94%. O circuit breaker de memória disparou a 96% (09:58). O pool de escrita encheu e rejeitou bulk. As buscas estouraram o timeout de 5 s e devolveram resultado parcial (11 de 12 shards).
- O cache de query caiu de 74% para 29% de acerto.
- A vazão de indexação subiu de 4.100 para 12.400 docs/s a partir das 09:00.

Critério a pontuar:
{{rubric}}

Análise a pontuar:
<analise>
{{output}}
</analise>

Como pontuar (seja rigoroso: um juiz brando aprova análises ruins):
1. Use só os descritores do critério acima. Em caso de dúvida entre duas notas, escolha a menor.
2. Dê crédito apenas ao que a análise afirma de forma explícita. Não complete o que ficou implícito.
3. A nota 1 ou 2 exige uma citação literal copiada de dentro de <analise>, e a citação precisa mostrar o que o descritor pede (uma frase que apenas toca no assunto não basta). Se você não encontra no texto da análise uma citação que cumpra o descritor, a nota é menor. Citações dos fatos do caso ou do critério não valem.
4. Valor, horário, evento ou parâmetro que a análise cita e que não está nos fatos do caso pode ser dado inventado; não conta a favor dela.

Responda somente com um objeto JSON, sem texto antes ou depois e sem cercas de código:
{"reason": "<nota 0, 1 ou 2>: <uma ou duas frases, com a citação literal de <analise> entre aspas simples; nunca use aspas duplas dentro do JSON>", "pass": <true se a nota for 1 ou 2, false se for 0>, "score": <a nota, 0, 1 ou 2>}
````

## Critérios (com as regras de rigor)

Arquivo: [`devops/causa-raiz/criterio-1.txt`](../../devops/causa-raiz/criterio-1.txt)

````text
Critério C1, causa-raiz correta, nota de 0 a 2.
0: aponta como causa-raiz um sintoma (latência, timeout, queda do cache, circuit breaker, heap alto) ou uma causa que os dados não sustentam; ou não relaciona o problema à reindexação.
1: cita a reindexação travada, mas como um fator entre vários, sem dizer que ela é a condição inicial; ou apresenta como causas-raiz uma lista que mistura a reindexação com sintomas ou efeitos (cache, thread pool, circuit breaker, heap); ou aponta a pressão de memória como causa sem ligá-la à reindexação.
2: aponta a reindexação travada ou lenta como condição inicial e a liga, em cadeia, à saturação do heap, ao circuit breaker e aos timeouts de busca, sem listar sintomas como causas.
````

Arquivo: [`devops/causa-raiz/criterio-2.txt`](../../devops/causa-raiz/criterio-2.txt)

````text
Critério C2, correlação × causa, nota de 0 a 2.
0: trata um efeito como causa (por exemplo, lista o cache de query, o thread pool ou o circuit breaker em uma lista ou tabela de causas, mesmo que a linha diga que o hit ratio caiu; ou diz que o cache hit baixo explica a lentidão), ou não separa causa de consequência.
1: separa os efeitos principais, mas mistura correlação com causalidade em algum ponto, ou apenas lista efeitos sem declarar o que é correlação.
2: trata a queda do cache (e a latência) como efeito e diz expressamente o que varia junto sem que a relação causal esteja demonstrada (por exemplo, o salto da vazão de indexação).
````

Arquivo: [`devops/causa-raiz/criterio-3.txt`](../../devops/causa-raiz/criterio-3.txt)

````text
Critério C3, ação proporcional, nota de 0 a 2.
0: ação sem relação com o diagnóstico, ou destrutiva e desproporcional (apagar o índice, reiniciar o cluster inteiro como primeira medida); ou ações que não tratam nem a reindexação nem a memória.
1: ação coerente com o diagnóstico, mas sub ou superdimensionada: só monitorar, ou a primeira ação é aumentar recursos (heap, nós, thread pool, limite do circuit breaker) ou mudar parâmetros, sem pausar, reagendar ou limitar a reindexação.
2: contenção reversível e de menor alcance ligada à causa (pausar, reagendar ou limitar a reindexação) e correção posterior separada (rever heap, limites, agenda).
````

Arquivo: [`devops/causa-raiz/criterio-4.txt`](../../devops/causa-raiz/criterio-4.txt)

````text
Critério C4, honestidade epistêmica, nota de 0 a 2.
0: afirma a causa com certeza total e sem limitações, ou não tem nenhuma seção ou frase sobre o que falta; ou inventa dados que não estão nos artefatos.
1: reconhece limitações de forma genérica ("faltam dados") sem dizer quais, ou dá grau de confiança alto sem ressalva ou sem justificar.
2: nomeia, em um trecho da própria análise, lacunas concretas do caso (por exemplo: por que a reindexação andou devagar, a origem da vazão, o heap já em 61% antes, a falta de CPU, disco e outros nós) e dá um grau de confiança justificado.
````
