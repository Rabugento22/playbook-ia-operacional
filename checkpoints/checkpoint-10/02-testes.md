# Testes dos prompts de saída aberta

Os quatro arquivos abaixo são idênticos aos de `devops/<prompt>/promptfooconfig.yaml`; o `validate.sh` confere. Os quatro prompts restantes da biblioteca (`nota-de-triagem`, `triagem-de-pods`, `networkpolicy-sentinel` e `causa-raiz`) já têm teste, nos checkpoints 08 e 09.

## decisao-backpressure

Arquivo: [`devops/decisao-backpressure/promptfooconfig.yaml`](../../devops/decisao-backpressure/promptfooconfig.yaml)

````yaml
# Teste do prompt decisao-backpressure (CP10).
# Saída aberta: o teste é determinístico só no que dá para verificar sem julgamento (títulos, ordem,
# formato proibido e fatos que a saída precisa conter). A qualidade do conteúdo não é avaliada aqui.
# Rodar a partir da raiz do repositório:
#   promptfoo eval -c devops/decisao-backpressure/promptfooconfig.yaml --no-cache -j 1
# Sem assert de latência: o modelo roda com raciocínio ligado (de 1 a 3 minutos por chamada); o limite
# de 5 s do enunciado vale para os prompts de saída estruturada (CP08).
description: decisao-backpressure — seis seções, tabela, três caminhos, contas do pico e sem asteriscos

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
  vars:
    prompt_dir: decisao-backpressure
  assert:
    # os títulos exigidos, todos presentes e na ordem do prompt
    - type: javascript
      value: |
        const titulos = ["Reformulação do cenário", "Contas", "Caminhos propostos", "Tabela comparativa", "Recomendação", "Limites e validação"];
        // o título é uma linha inteira (com ou sem ":" no fim), e os títulos aparecem em ordem
        const linhas = output.split('\n').map((l) => l.trim().replace(/:$/, ''));
        let pos = -1;
        for (const t of titulos) {
          const i = linhas.indexOf(t, pos + 1);
          if (i < 0) return { pass: false, score: 0, reason: 'título ausente ou fora de ordem: ' + t };
          pos = i;
        }
        return true;
    # formato proibido pelo prompt
    - type: not-contains
      value: '```'
    - type: not-contains
      value: '*'
    # tabela comparativa com barras verticais (pelo menos 3 linhas com |)
    - type: javascript
      value: (output.match(/^.*\|.*$/gm) || []).length >= 3
    # pelo menos três caminhos
    - type: javascript
      value: (output.match(/^[\s*]*Caminho\s*\d/gim) || []).length >= 3
    # as contas do pico: excedente de 140 mil msgs/s e volume acumulado de 210 milhões
    - type: regex
      value: '140[\s.,]?000|140\s?k'
    - type: regex
      value: '210[\s.,]?000[\s.,]?000|210\s?(M|milh)'
    # custo (o provedor local devolve 0)
    - type: cost
      threshold: 0.01

tests:
  - description: Relay, pico de 320k msgs/s por 25 min, SLA de 60 s e perda inaceitável
    vars:
      cenario: file://../../checkpoints/checkpoint-04/entradas/cenario-relay.txt
````

## migracao-forge-diagnostico

Arquivo: [`devops/migracao-forge-diagnostico/promptfooconfig.yaml`](../../devops/migracao-forge-diagnostico/promptfooconfig.yaml)

````yaml
# Teste do prompt migracao-forge-diagnostico (CP10).
# Saída aberta: o teste é determinístico só no que dá para verificar sem julgamento (títulos, ordem,
# formato proibido e fatos que a saída precisa conter). A qualidade do conteúdo não é avaliada aqui.
# Rodar a partir da raiz do repositório:
#   promptfoo eval -c devops/migracao-forge-diagnostico/promptfooconfig.yaml --no-cache -j 1
# Sem assert de latência: o modelo roda com raciocínio ligado (de 1 a 3 minutos por chamada); o limite
# de 5 s do enunciado vale para os prompts de saída estruturada (CP08).
description: migracao-forge-diagnostico — nove seções, janela de madrugada na seção certa, garantias e dependentes

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
  vars:
    prompt_dir: migracao-forge-diagnostico
  assert:
    # os títulos exigidos, todos presentes e na ordem do prompt
    - type: javascript
      value: |
        const titulos = ["Garantias do cenário", "Estado atual", "Dependentes e o que cada um espera", "Janelas de consumo", "Pontos frágeis e riscos", "O que muda do lote para eventos", "Invariantes", "Lacunas", "Verificação"];
        // o título é uma linha inteira (com ou sem ":" no fim), e os títulos aparecem em ordem
        const linhas = output.split('\n').map((l) => l.trim().replace(/:$/, ''));
        let pos = -1;
        for (const t of titulos) {
          const i = linhas.indexOf(t, pos + 1);
          if (i < 0) return { pass: false, score: 0, reason: 'título ausente ou fora de ordem: ' + t };
          pos = i;
        }
        return true;
    # formato proibido pelo prompt
    - type: not-contains
      value: '```'
    - type: not-contains
      value: '*'
    # a janela de madrugada do billing precisa estar na seção "Janelas de consumo"
    - type: javascript
      value: |
        const linhas = output.split('\n').map((l) => l.trim().replace(/:$/, ''));
        const a = linhas.indexOf('Janelas de consumo');
        const b = linhas.indexOf('Pontos frágeis e riscos', a);
        const secao = linhas.slice(a, b).join('\n');
        return /madrugada/i.test(secao) ? true : { pass: false, score: 0, reason: 'a janela de madrugada não está na seção Janelas de consumo' };
    # os três dependentes do cenário
    - type: javascript
      value: /Sentinel/.test(output) && /Cerebro/.test(output) && /billing/i.test(output)
    # a garantia de não haver virada única
    - type: regex
      value: 'big-bang|virada única'
    # custo (o provedor local devolve 0)
    - type: cost
      threshold: 0.01

tests:
  - description: cenário do Forge (lote de 1 h, três dependentes, billing de madrugada)
    vars:
      cenario: file://../../checkpoints/checkpoint-05/entradas/cenario-forge.txt
````

## migracao-forge-plano

Arquivo: [`devops/migracao-forge-plano/promptfooconfig.yaml`](../../devops/migracao-forge-plano/promptfooconfig.yaml)

````yaml
# Teste do prompt migracao-forge-plano (CP10).
# Saída aberta: o teste é determinístico só no que dá para verificar sem julgamento (títulos, ordem,
# formato proibido e fatos que a saída precisa conter). A qualidade do conteúdo não é avaliada aqui.
# Rodar a partir da raiz do repositório:
#   promptfoo eval -c devops/migracao-forge-plano/promptfooconfig.yaml --no-cache -j 1
# Sem assert de latência: o modelo roda com raciocínio ligado (de 1 a 3 minutos por chamada); o limite
# de 5 s do enunciado vale para os prompts de saída estruturada (CP08).
description: migracao-forge-plano — sete seções, fases reversíveis, etapa por dependente e janela de madrugada protegida

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
  vars:
    prompt_dir: migracao-forge-plano
  assert:
    # os títulos exigidos, todos presentes e na ordem do prompt
    - type: javascript
      value: |
        const titulos = ["Garantias e lacunas que moldam o plano", "Fases", "Ordem e dependências entre fases", "Convivência entre o modelo antigo e o novo", "Riscos do plano e mitigação", "Decisões em aberto", "Verificação contra as garantias"];
        // o título é uma linha inteira (com ou sem ":" no fim), e os títulos aparecem em ordem
        const linhas = output.split('\n').map((l) => l.trim().replace(/:$/, ''));
        let pos = -1;
        for (const t of titulos) {
          const i = linhas.indexOf(t, pos + 1);
          if (i < 0) return { pass: false, score: 0, reason: 'título ausente ou fora de ordem: ' + t };
          pos = i;
        }
        return true;
    # formato proibido pelo prompt
    - type: not-contains
      value: '```'
    - type: not-contains
      value: '*'
    # a janela de madrugada aparece ao longo do plano (pelo menos 2 vezes)
    - type: javascript
      value: (output.match(/madrugada/gi) || []).length >= 2
    # os três dependentes ganham tratamento próprio
    - type: javascript
      value: /Sentinel/.test(output) && /Cerebro/.test(output) && /billing/i.test(output)
    # cada fase tem um caminho de volta
    - type: regex
      value: 'reversão|reverter|voltar atrás|rollback'
    # custo (o provedor local devolve 0)
    - type: cost
      threshold: 0.01

tests:
  - description: cenário do Forge com o diagnóstico real do CP05 (qwen3:14b)
    vars:
      cenario: file://../../checkpoints/checkpoint-05/entradas/cenario-forge.txt
      diagnostico: file://../../checkpoints/checkpoint-10/entradas/diagnostico-qwen3-14b.txt
````

## migracao-forge-execucao

Arquivo: [`devops/migracao-forge-execucao/promptfooconfig.yaml`](../../devops/migracao-forge-execucao/promptfooconfig.yaml)

````yaml
# Teste do prompt migracao-forge-execucao (CP10).
# Saída aberta: o teste é determinístico só no que dá para verificar sem julgamento (títulos, ordem,
# formato proibido e fatos que a saída precisa conter). A qualidade do conteúdo não é avaliada aqui.
# Rodar a partir da raiz do repositório:
#   promptfoo eval -c devops/migracao-forge-execucao/promptfooconfig.yaml --no-cache -j 1
# Sem assert de latência: o modelo roda com raciocínio ligado (de 1 a 3 minutos por chamada); o limite
# de 5 s do enunciado vale para os prompts de saída estruturada (CP08).
description: migracao-forge-execucao — sete seções, go/no-go, rollback com gatilho e limite de tempo, janela de madrugada

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
  vars:
    prompt_dir: migracao-forge-execucao
  assert:
    # os títulos exigidos, todos presentes e na ordem do prompt
    - type: javascript
      value: |
        const titulos = ["Garantias do cenário", "Pré-requisitos globais", "Roteiro por fase", "Proteção dos dependentes", "Comunicação", "Riscos residuais", "Checklist final contra as garantias"];
        // o título é uma linha inteira (com ou sem ":" no fim), e os títulos aparecem em ordem
        const linhas = output.split('\n').map((l) => l.trim().replace(/:$/, ''));
        let pos = -1;
        for (const t of titulos) {
          const i = linhas.indexOf(t, pos + 1);
          if (i < 0) return { pass: false, score: 0, reason: 'título ausente ou fora de ordem: ' + t };
          pos = i;
        }
        return true;
    # formato proibido pelo prompt
    - type: not-contains
      value: '```'
    - type: not-contains
      value: '*'
    # a janela de madrugada vale para o roteiro
    - type: javascript
      value: (output.match(/madrugada/gi) || []).length >= 1
    # go/no-go, gatilho e limite de tempo do rollback
    - type: regex
      value: 'go/no-go'
    - type: javascript
      value: /gatilho/i.test(output)
    - type: javascript
      value: /limite de tempo/i.test(output)
    # custo (o provedor local devolve 0)
    - type: cost
      threshold: 0.01

tests:
  - description: cenário do Forge com o plano real do CP05 (qwen3:14b)
    vars:
      cenario: file://../../checkpoints/checkpoint-05/entradas/cenario-forge.txt
      plano: file://../../checkpoints/checkpoint-10/entradas/plano-qwen3-14b.txt
````
