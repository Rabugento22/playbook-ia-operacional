# Contexto

## O que o enunciado pede

Levar a cobertura de testes ao repositório inteiro, "determinístico onde der, com juiz onde precisar de julgamento", e montar um pipeline em GitHub Actions que roda a suíte em todo pull request e push, falhando o build quando um prompt regride. O desenho do gate (o que faz o build falhar), o escopo da execução (suíte inteira ou só o que mudou), o custo por PR e a guarda de chaves ficam por conta do aluno, com a justificativa comparando pelo menos duas alternativas em cada decisão.

## Cobertura da biblioteca

| Prompt | Teste | Tipo | Onde |
|---|---|---|---|
| `triagem-de-pods` | `promptfooconfig.yaml` | determinístico + latência e custo | CP08 |
| `nota-de-triagem` | `promptfooconfig.yaml` | determinístico + latência e custo | CP08 |
| `networkpolicy-sentinel` | `promptfooconfig.yaml` | determinístico + latência e custo | CP08 |
| `causa-raiz` | `promptfooconfig.yaml` | juiz LLM (rubrica de 4 critérios) | CP09 |
| `decisao-backpressure` | `promptfooconfig.yaml` | determinístico (estrutura, formato, contas) | T050, [`02-testes.md`](02-testes.md) |
| `migracao-forge-diagnostico` | `promptfooconfig.yaml` | determinístico (estrutura, formato, janela) | T050 |
| `migracao-forge-plano` | `promptfooconfig.yaml` | determinístico | T050 |
| `migracao-forge-execucao` | `promptfooconfig.yaml` | determinístico | T050 |

Os oito prompts têm teste e rodam localmente. Os quatro de saída aberta que não são a `causa-raiz` têm **só a parte determinística**: o enunciado manda usar juiz onde o prompt precisa de julgamento, e esses quatro precisariam de uma rubrica e de uma calibração próprias, como a do CP09. Isso fica como lacuna declarada, a decidir com o Rubens.

## Decisões da T050

- **Mesmo desenho do CP08:** o `promptfoo` lê o `prompt.md` da biblioteca por meio de `providers/carregar-prompt.js`, e as entradas vêm de arquivos `file://`.
- **Um modelo, `qwen3:14b`, com raciocínio ligado**, sem assert de latência (cada chamada leva de 1,5 a 3,5 minutos).
- **Entradas fixas na cadeia:** os elos 2 e 3 usam as saídas reais do CP05 como entrada, e não a saída do elo anterior no mesmo teste.
- **Os asserts seguem o que o próprio prompt exige:** títulos em ordem, formato proibido, e os fatos que a saída precisa conter. Nada foi afrouxado para fazer um teste passar.
