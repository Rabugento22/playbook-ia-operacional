# Testes

Os três arquivos abaixo são idênticos aos de `devops/<prompt>/promptfooconfig.yaml`; o `validate.sh` confere.

## nota-de-triagem

Arquivo: [`devops/nota-de-triagem/promptfooconfig.yaml`](../../devops/nota-de-triagem/promptfooconfig.yaml)

````yaml
# Teste determinístico do prompt nota-de-triagem (CP08).
# Rodar a partir da raiz do repositório:
#   promptfoo eval -c devops/nota-de-triagem/promptfooconfig.yaml --no-cache -j 1
# Antes, aqueça os modelos (ver checkpoints/checkpoint-08/README.md): a primeira
# chamada de um modelo frio inclui o carregamento e estoura o limite de latência.
description: nota-de-triagem — cinco rótulos, handle @palavra, no máximo 8 linhas, latência e custo

prompts:
  - file://../../providers/carregar-prompt.js

providers:
  - id: file://../../providers/ollama-local.js
    label: llama3.2:3b (Meta, via Ollama)
    config:
      model: llama3.2:3b
      temperature: 0
      num_ctx: 8192
  - id: file://../../providers/ollama-local.js
    label: gemma3:4b (Google, via Ollama)
    config:
      model: gemma3:4b
      temperature: 0
      num_ctx: 8192

defaultTest:
  vars:
    prompt_dir: nota-de-triagem
  assert:
    # os cinco rótulos
    - type: contains
      value: 'ALERTA:'
    - type: contains
      value: 'IMPACTO:'
    - type: contains
      value: 'HIPÓTESE INICIAL:'
    - type: contains
      value: 'AÇÃO IMEDIATA:'
    - type: contains
      value: 'ESCALAR PARA:'
    # handle no formato @palavra no campo de escalonamento
    - type: regex
      value: 'ESCALAR PARA:.*@\w+'
    # concisão: no máximo 8 linhas
    - type: javascript
      value: output.trim().split('\n').length <= 8
    # limites operacionais
    - type: latency
      threshold: 5000
    - type: cost
      threshold: 0.01

tests:
  - description: alerta 1 — Sentinel
    vars:
      alerta_cru: file://../../checkpoints/checkpoint-02/entradas/alerta-1-sentinel.txt
    assert:
      # extra, além do PDF: o handle do time dono do sistema, conforme a tabela do prompt
      - type: contains
        value: '@sentinel-core'
  - description: alerta 2 — Relay
    vars:
      alerta_cru: file://../../checkpoints/checkpoint-02/entradas/alerta-2-relay.txt
    assert:
      # extra, além do PDF: o handle do time dono do sistema, conforme a tabela do prompt
      - type: contains
        value: '@relay-core'
  - description: alerta 3 — Forge
    vars:
      alerta_cru: file://../../checkpoints/checkpoint-02/entradas/alerta-3-forge.txt
    assert:
      # extra, além do PDF: o handle do time dono do sistema, conforme a tabela do prompt
      - type: contains
        value: '@data-platform'
````

## triagem-de-pods

Arquivo: [`devops/triagem-de-pods/promptfooconfig.yaml`](../../devops/triagem-de-pods/promptfooconfig.yaml)

````yaml
# Teste determinístico do prompt triagem-de-pods (CP08).
# Rodar a partir da raiz do repositório (aqueça os modelos antes; ver checkpoints/checkpoint-08/README.md):
#   promptfoo eval -c devops/triagem-de-pods/promptfooconfig.yaml --no-cache -j 1
description: triagem-de-pods — pods citados com a causa, entrada saudável sem pod em falha, latência e custo

prompts:
  - file://../../providers/carregar-prompt.js

providers:
  - id: file://../../providers/ollama-local.js
    label: llama3.2:3b (Meta, via Ollama)
    config:
      model: llama3.2:3b
      temperature: 0
      num_ctx: 8192
  - id: file://../../providers/ollama-local.js
    label: gemma3:4b (Google, via Ollama)
    config:
      model: gemma3:4b
      temperature: 0
      num_ctx: 8192

defaultTest:
  vars:
    prompt_dir: triagem-de-pods
  assert:
    # limites operacionais
    - type: latency
      threshold: 5000
    - type: cost
      threshold: 0.01

tests:
  - description: entrada 1 — pod reiniciando (OOMKilled)
    vars:
      snapshot: file://../../checkpoints/checkpoint-01/entradas/entrada-1-pod-reiniciando.txt
    assert:
      - type: contains
        value: sentinel-api-7d9c8b6f4-h4m2t
      - type: icontains-any
        value: [OOMKilled, memória, memoria]
  - description: entrada 2 — dois pods que não sobem (imagem e CPU)
    vars:
      snapshot: file://../../checkpoints/checkpoint-01/entradas/entrada-2-pods-nao-sobem.txt
    assert:
      - type: contains
        value: sentinel-api-7d9c8b6f4-zzp10
      - type: contains
        value: sentinel-ingest-8f7a9c5b-4dkqm
      - type: icontains-any
        value: ['2.9.2', ImagePullBackOff]
      - type: icontains-any
        value: [Insufficient, cpu]
  - description: entrada 3 — tudo saudável (nenhum pod problemático)
    vars:
      snapshot: file://../../checkpoints/checkpoint-01/entradas/entrada-3-tudo-saudavel.txt
    assert:
      # o prompt manda abrir com "Pods problemáticos: N"; N deve ser 0
      - type: regex
        value: 'Pods problemáticos:\**\s*0'
      # nenhum pod listado como problemático e nenhum status de falha atribuído a um pod
      - type: not-contains
        value: 'NOME:'
      - type: not-icontains-any
        value: [CrashLoopBackOff, ImagePullBackOff, OOMKilled, Pending, 'Pods problemáticos: 1', 'Pods problemáticos: 2']
````

## networkpolicy-sentinel

Arquivo: [`devops/networkpolicy-sentinel/promptfooconfig.yaml`](../../devops/networkpolicy-sentinel/promptfooconfig.yaml)

````yaml
# Teste determinístico do prompt networkpolicy-sentinel (CP08).
# Rodar a partir da raiz do repositório (aqueça os modelos antes; ver checkpoints/checkpoint-08/README.md):
#   promptfoo eval -c devops/networkpolicy-sentinel/promptfooconfig.yaml --no-cache -j 1
description: networkpolicy-sentinel — NetworkPolicy válida, sem allow-all, portas do Forge e Cerebro, ingress do Relay, comentário em cada regra, latência e custo

prompts:
  - file://../../providers/carregar-prompt.js

providers:
  - id: file://../../providers/ollama-local.js
    label: llama3.2:3b (Meta, via Ollama)
    config:
      model: llama3.2:3b
      temperature: 0
      num_ctx: 8192
  - id: file://../../providers/ollama-local.js
    label: gemma3:4b (Google, via Ollama)
    config:
      model: gemma3:4b
      temperature: 0
      num_ctx: 8192

defaultTest:
  vars:
    prompt_dir: networkpolicy-sentinel
    manifesto: file://../../checkpoints/checkpoint-06/entradas/manifesto-permissivo.yaml
    padrao: file://../../checkpoints/checkpoint-06/entradas/padrao-aegis.txt
    mapa: file://../../checkpoints/checkpoint-06/entradas/mapa-de-servicos.txt
  assert:
    # YAML com kind NetworkPolicy
    - type: contains
      value: 'kind: NetworkPolicy'
    # policyTypes contendo Ingress e Egress (policyTypes em lista ou em linha)
    - type: javascript
      value: |
        const blocos = [...output.matchAll(/policyTypes:([^\n]*(?:\n\s*-[^\n]*)*)/g)].map(m => m[1]).join(' ');
        return /Ingress/.test(blocos) && /Egress/.test(blocos);
    # sem regra allow-all
    - type: not-contains
      value: '- {}'
    # egress libera Forge (5432) e Cerebro (9200); ingress libera o Relay (app: relay)
    - type: contains
      value: '5432'
    - type: contains
      value: '9200'
    - type: regex
      value: 'app:\s*"?relay"?'
    # toda regra tem comentário: pelo menos um # por regra de ingress ou egress
    - type: javascript
      value: |
        const regras = (output.match(/^\s*-\s*(from|to):/gm) || []).length;
        const comentarios = (output.match(/#/g) || []).length;
        return regras > 0 && comentarios >= regras;
    # limites operacionais
    - type: latency
      threshold: 5000
    - type: cost
      threshold: 0.01

tests:
  - description: manifesto permissivo + padrão Aegis + mapa de serviços
````

## Carregador do prompt

Arquivo: [`providers/carregar-prompt.js`](../../providers/carregar-prompt.js)

````javascript
// carregar-prompt.js — carrega devops/<prompt>/prompt.md para o promptfoo.
// Tira o frontmatter e troca cada {{parametro}} pelo valor do caso de teste,
// de modo que o teste exercite o texto exato do prompt da biblioteca.
// O caso de teste informa a pasta do prompt na variável `prompt_dir`.
const fs = require('fs');
const path = require('path');

module.exports = function carregarPrompt({ vars }) {
  const pasta = vars.prompt_dir;
  if (!pasta) throw new Error('defina a variável prompt_dir (nome da pasta em devops/)');
  const arquivo = path.join(__dirname, '..', 'devops', pasta, 'prompt.md');
  const texto = fs.readFileSync(arquivo, 'utf-8');
  const corpo = texto.replace(/^---\n[\s\S]*?\n---\n/, '').replace(/^\n+/, '');
  return corpo.replace(/\{\{(\w+)\}\}/g, (marca, nome) =>
    nome in vars ? String(vars[nome]) : marca,
  );
};
````

## Mudanças de prompt feitas por causa dos testes

Uma foi mantida e duas foram tentadas e desfeitas. Os resultados de cada uma estão em [`03-execucao.md`](03-execucao.md) e a discussão em [`04-curadoria.md`](04-curadoria.md).

| Prompt | Mudança | Resultado | Situação |
|--------|---------|-----------|----------|
| `nota-de-triagem` | O formato deixa de listar os rótulos sozinhos e passa a mostrar cada linha preenchível (`ALERTA: <sistema> - <condição>`, e assim por diante); a regra 5 diz que o handle é o do sistema escrito em `ALERTA:`; a tabela de handles ganhou a instrução de usar a linha do sistema do alerta, e os quatro handles também aparecem na regra 5 | `llama3.2:3b` passou de 0 de 3 para 3 de 3 nos asserts do enunciado; `gemma3:4b` ficou em 3 de 3 nos asserts do enunciado e acertou o handle em 2 de 3 (o mesmo que com o prompt original) | **Mantida**, versão `1.0.1` |
| `triagem-de-pods` | Regra nova: pod `Running` com READY completo não é problemático, mesmo com restarts antigos; se todos forem assim, "Pods problemáticos: 0" e nenhum `NOME:` | Os dois modelos continuaram inventando pods problemáticos na entrada 3 | **Desfeita**: sem efeito mensurável, o texto voltou ao da versão `1.0.0` |
| `networkpolicy-sentinel` | Limitar as seções de explicação a poucas linhas, para encurtar a resposta | A saída seguiu em 719 a 793 tokens e a latência em 6,8 e 8,2 s | **Desfeita**: sem efeito mensurável, o texto voltou ao da versão `1.0.1` |
