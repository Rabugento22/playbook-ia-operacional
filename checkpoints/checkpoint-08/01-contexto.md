# Contexto

## O que o enunciado pede

"Prompt na biblioteca sem teste é prompt em que ninguém confia." O CP08 pede um `promptfooconfig.yaml` ao lado do `prompt.md` de cada prompt de **saída estruturada**, rodado de verdade com `promptfoo eval`. Os prompts de saída aberta (causa-raiz, decisão de backpressure e migração) ficam para a avaliação por julgamento do CP09 e do CP10.

| Prompt | Entradas | Asserts exigidos |
|--------|----------|------------------|
| `nota-de-triagem` | 3 alertas crus do CP02 | os cinco rótulos; handle `@palavra` (regex `ESCALAR PARA:.*@\w+`); no máximo 8 linhas |
| `triagem-de-pods` | 3 snapshots do CP01 | entrada 1: o pod `sentinel-api-7d9c8b6f4-h4m2t` e `OOMKilled` ou memória; entrada 2: os dois pods e as causas (tag `2.9.2`/`ImagePullBackOff` e `Insufficient`/cpu); entrada 3: nenhum pod problemático |
| `networkpolicy-sentinel` | manifesto, padrão e mapa do CP06 | YAML com `kind: NetworkPolicy` e `policyTypes` com Ingress e Egress; sem `- {}`; egress para Forge (5432) e Cerebro (9200); ingress do Relay (`app: relay`); comentário em toda regra |

Em todos: **latência de no máximo 5 s** por chamada (`latency`) e **custo de no máximo US$ 0,01** (`cost`).

## Decisões

- **Modelos:** `llama3.2:3b` (Meta) e `gemma3:4b` (Google), via Ollama. São os únicos que chegam perto de 5 s na máquina (RTX 3060 de 12 GB); a T004 mediu 17 s no `qwen3:14b` e de 79 a 158 s no `gpt-oss:20b` no prompt de NetworkPolicy. Isso também cumpre o requisito de pelo menos dois provedores da lista do enunciado (Meta e Google).
- **Custo:** o provedor local devolve `cost: 0`, então o assert `cost` passa por construção. Ele está nos arquivos porque o enunciado manda e para o dia em que o provedor trocar.
- **O prompt testado é o da biblioteca.** O `promptfoo` lê o `prompt.md` por meio de [`providers/carregar-prompt.js`](../../providers/carregar-prompt.js), que tira o frontmatter e troca os `{{parâmetros}}` pelos valores do caso de teste. Assim o teste cobre o texto exato que a biblioteca publica, e não uma cópia.
- **Entradas:** os arquivos dos checkpoints 01, 02 e 06 (`file://`), sem copiar nada.
- **Aquecimento:** a primeira chamada de um modelo frio inclui o carregamento e estoura 5 s (medido na T004). Cada `eval` é precedido de uma chamada curta de aquecimento.
- **Um caso por vez** (`-j 1`) e sem cache, para que a latência seja a da chamada real.

## O que o enunciado deixa em aberto e como foi decidido

- **"Nenhum pod problemático" (entrada 3).** O prompt abre com `Pods problemáticos: N`. O teste exige `N = 0`, a ausência de `NOME:` (nenhum pod listado) e a ausência de status de falha atribuído a pods (`CrashLoopBackOff`, `ImagePullBackOff`, `OOMKilled`, `Pending`).
- **"Toda regra tem comentário".** O `promptfoo` não entende YAML nesse nível; o assert conta as regras (`- from:` e `- to:`) e exige pelo menos um `#` por regra. É uma aproximação: não prova que o comentário está na regra certa.
- **`policyTypes` com Ingress e Egress.** Também por texto, aceitando lista (`- Ingress`) ou em linha (`[Ingress, Egress]`). Não valida o YAML inteiro.
- **Um assert a mais além do enunciado, em `nota-de-triagem`:** o handle precisa ser o do sistema do alerta (`@sentinel-core`, `@relay-core` ou `@data-platform`). O enunciado só pede o formato `@palavra`, mas um handle de outro time é uma nota errada, e é o tipo de erro que a regex do enunciado não vê.
