# Pipeline

Os arquivos abaixo são idênticos aos de `.github/`; o `validate.sh` confere.

## Como o pipeline funciona

1. **Dispara** em todo pull request e em todo push na `main` que mexe em `devops/`, `providers/`, `.github/` ou `validate.sh`, e à mão (`workflow_dispatch`).
2. **Confere a estrutura** com `./validate.sh` (frontmatter, índices, links, textos idênticos entre checkpoint e prompt).
3. **Escolhe o que testar** ([`selecionar.sh`](../../.github/scripts/selecionar.sh)): só os prompts cuja pasta mudou (com os elos seguintes da cadeia do Forge); se mudou o provedor, o carregador, o `validate.sh` ou o próprio pipeline, testa todos.
4. **Roda a suíte** ([`rodar-suite.sh`](../../.github/scripts/rodar-suite.sh)): aquece os modelos pequenos e roda `promptfoo eval` em cada prompt escolhido, um caso por vez, sem cache.
5. **Compara com a linha de base** ([`comparar.js`](../../.github/scripts/comparar.js)): o build **falha só quando um assert que passava na linha de base passa a falhar** (ou quando o juiz do `causa-raiz` aprovava e passa a reprovar). Defeitos que já existiam não bloqueiam; são listados no relatório.
6. **Reporta**: o resumo vai para a página do run e, no pull request, para um comentário atualizado a cada push; os resultados brutos do `promptfoo` ficam como artefato por 30 dias.

A linha de base está em [`.github/baseline/`](../../.github/baseline/): um resumo por prompt, gerado ([`resumir.js`](../../.github/scripts/resumir.js)) a partir das execuções reais dos checkpoints 08, 09 e 10. Depois de uma mudança aceita de propósito (por exemplo, um prompt melhorado), a linha de base é atualizada com `PROMPTS="..." .github/scripts/rodar-suite.sh --atualizar-baseline` e commitada.

## Por que não usei a action `promptfoo/promptfoo-action` pronta

O enunciado indica a action como ponto de partida, e a decisão de usá-la ou não é de desenho. A página oficial mostra uma action que avalia os arquivos de prompt que mudaram e comenta o resultado no PR, com um link para o visualizador na web. Para este repositório ela não serve como está:

- Ela recebe os arquivos de prompt por um glob e os avalia direto. Os `prompt.md` têm frontmatter, e o teste precisa passar pelo `providers/carregar-prompt.js` (que tira o frontmatter e troca os parâmetros), então o prompt avaliado não seria o que a biblioteca publica.
- O visualizador na web é um serviço externo; os dados dos cenários são fictícios, mas o princípio do projeto é nada sair da máquina.
- A página não lista como obter uma regra de gate própria (comparar com a linha de base, juiz com nova tentativa), que é o que este projeto precisa. Não consegui verificar mais do que a página de documentação (não executei a action).

A parte que foi aproveitada da ideia dela: comentar no PR e avaliar só o que mudou.

## Segurança do runner self-hosted

O runner roda nesta máquina. Em repositório público, um pull request de fork poderia executar código nele, então o job só roda quando o PR vem do próprio repositório (`if:` no job). Recomenda-se também, nas configurações do repositório, exigir aprovação para os workflows de colaboradores externos (Settings, Actions, General).

## Preparar o runner (feito pelo mantenedor, uma vez)

1. No GitHub: Settings, Actions, Runners, New self-hosted runner, Linux x64. Seguir os comandos mostrados (baixar, `./config.sh --url ... --token ... --labels ollama`).
2. Subir o Ollama com os quatro modelos (`llama3.2:3b`, `gemma3:4b`, `qwen3:14b`, `gpt-oss:20b`) e ter o `promptfoo` 0.125.1 e o Node.js 22 ou mais no `PATH` do usuário do runner.
3. Iniciar o runner à mão quando for rodar o pipeline: `./run.sh`. Fechado o runner, os runs ficam na fila.

## Segredos

O pipeline não usa nenhum: os modelos são locais e o `GITHUB_TOKEN` automático basta para comentar no PR. Se uma API gratuita for adicionada depois (decisão PR12), a chave vai em Settings, Secrets and variables, Actions, e entra no job por `env`, nunca no arquivo.

## Arquivos

### `.github/workflows/prompts.yml`

````yaml
# Suíte de avaliação dos prompts do playbook (CP10).
# Roda em todo pull request e push que mexe na biblioteca, no provedor ou no próprio pipeline, e falha o
# build quando um prompt REGRIDE em relação à linha de base (.github/baseline/). O desenho do gate está em
# checkpoints/checkpoint-10/04-curadoria.md.
#
# Roda num runner self-hosted nesta máquina (Ollama local, sem API paga, custo zero). O runner é iniciado
# à mão pelo mantenedor (./run.sh) e precisa ter o rótulo "ollama".
name: Suíte de prompts

on:
  pull_request:
    paths:
      - 'devops/**'
      - 'providers/**'
      - '.github/**'
      - 'validate.sh'
  push:
    branches: [main]
    paths:
      - 'devops/**'
      - 'providers/**'
      - '.github/**'
      - 'validate.sh'
  workflow_dispatch:
    inputs:
      escopo:
        description: 'todos ou uma lista de prompts separados por espaço'
        default: 'todos'

# um run por ramo; um novo push cancela o anterior (o runner é um só e cada suíte leva minutos)
concurrency:
  group: suite-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read
  pull-requests: write

jobs:
  suite:
    # O runner é self-hosted: um pull request de fork não pode executar código nele.
    if: github.event_name != 'pull_request' || github.event.pull_request.head.repo.full_name == github.repository
    runs-on: [self-hosted, ollama]
    timeout-minutes: 120
    steps:
      - name: Código
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Estrutura do repositório (validate.sh)
        run: ./validate.sh

      - name: Escolher os prompts a testar
        id: escopo
        # os valores do evento entram por variáveis de ambiente, e não dentro do script (evita injeção de comando)
        env:
          EVENTO: ${{ github.event_name }}
          ESCOPO: ${{ inputs.escopo }}
          BASE_PR: ${{ github.event.pull_request.base.sha }}
          HEAD_PR: ${{ github.event.pull_request.head.sha }}
          BASE_PUSH: ${{ github.event.before }}
          HEAD_PUSH: ${{ github.sha }}
        run: |
          set -euo pipefail
          if [ "$EVENTO" = "workflow_dispatch" ]; then
            if [ "$ESCOPO" = "todos" ]; then lista="$(.github/scripts/selecionar.sh todos)"; else lista="$ESCOPO"; fi
          elif [ "$EVENTO" = "pull_request" ]; then
            lista="$(.github/scripts/selecionar.sh "$BASE_PR" "$HEAD_PR")"
          else
            lista="$(.github/scripts/selecionar.sh "$BASE_PUSH" "$HEAD_PUSH")"
          fi
          lista="$(echo "$lista" | tr '\n' ' ' | xargs)"
          echo "prompts=$lista" >> "$GITHUB_OUTPUT"
          echo "Prompts a testar: ${lista:-nenhum}"

      - name: Rodar a suíte e comparar com a linha de base
        id: suite
        if: steps.escopo.outputs.prompts != ''
        env:
          PROMPTS: ${{ steps.escopo.outputs.prompts }}
          SAIDA: resultados
        run: .github/scripts/rodar-suite.sh

      - name: Resumo no run
        if: always() && steps.escopo.outputs.prompts != ''
        env:
          PROMPTS: ${{ steps.escopo.outputs.prompts }}
        run: |
          { echo "# Suíte de prompts"; echo; echo "Prompts testados: $PROMPTS"; echo;
            cat resultados/relatorio.md 2>/dev/null || echo "sem relatório"; } >> "$GITHUB_STEP_SUMMARY"

      - name: Comentar no pull request
        if: always() && github.event_name == 'pull_request' && steps.escopo.outputs.prompts != ''
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const corpo = fs.existsSync('resultados/relatorio.md') ? fs.readFileSync('resultados/relatorio.md', 'utf8') : 'sem relatório';
            const marca = '<!-- suite-de-prompts -->';
            const texto = `${marca}\n## Suíte de prompts\n\nPrompts testados: ${process.env.PROMPTS}\n\n${corpo}`;
            const { data: comentarios } = await github.rest.issues.listComments({ ...context.repo, issue_number: context.issue.number });
            const existente = comentarios.find((c) => c.body.startsWith(marca));
            if (existente) await github.rest.issues.updateComment({ ...context.repo, comment_id: existente.id, body: texto });
            else await github.rest.issues.createComment({ ...context.repo, issue_number: context.issue.number, body: texto });
        env:
          PROMPTS: ${{ steps.escopo.outputs.prompts }}

      - name: Guardar os resultados brutos
        if: always() && steps.escopo.outputs.prompts != ''
        uses: actions/upload-artifact@v4
        with:
          name: resultados-promptfoo
          path: resultados/
          retention-days: 30
````

### `.github/scripts/selecionar.sh`

````bash
#!/usr/bin/env bash
# selecionar.sh — decide quais prompts a suíte testa.
# Uso: selecionar.sh <sha-base> <sha-novo>   (ou "todos" no lugar do primeiro argumento)
# Imprime um nome de prompt por linha.
#   - mudou devops/<prompt>/            => só esse prompt (e os que dependem dele na cadeia do Forge)
#   - mudou providers/, .github/ ou validate.sh (infraestrutura da suíte) => todos
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
todos() { ls -d devops/*/ | xargs -n1 basename; }

base="${1:-todos}"; novo="${2:-HEAD}"
if [ "$base" = "todos" ] || [ "$base" = "0000000000000000000000000000000000000000" ] || ! git cat-file -e "$base" 2>/dev/null; then
  todos; exit 0
fi
mudou="$(git diff --name-only "$base" "$novo")"
if echo "$mudou" | grep -qE '^(providers/|\.github/(scripts|workflows)/|validate\.sh)'; then
  todos; exit 0
fi
{
  echo "$mudou" | grep -E '^devops/[^/]+/' | cut -d/ -f2
  # a cadeia do Forge: mudar um elo muda a entrada do seguinte, então testa-se o elo e os seguintes
  if echo "$mudou" | grep -q '^devops/migracao-forge-diagnostico/'; then echo migracao-forge-plano; echo migracao-forge-execucao; fi
  if echo "$mudou" | grep -q '^devops/migracao-forge-plano/'; then echo migracao-forge-execucao; fi
} | sort -u | while read -r p; do [ -f "devops/$p/promptfooconfig.yaml" ] && echo "$p"; done || true
````

### `.github/scripts/rodar-suite.sh`

````bash
#!/usr/bin/env bash
# rodar-suite.sh — roda o promptfoo nos prompts escolhidos e compara com a linha de base.
# Uso: PROMPTS="a b c" .github/scripts/rodar-suite.sh [--atualizar-baseline]
# Saídas: resultados/<prompt>.json (promptfoo), resultados/<prompt>.resumo.json, resultados/relatorio.md
# Código de saída: 0 sem regressão, 1 com regressão em algum prompt.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
atualizar=0; [ "${1:-}" = "--atualizar-baseline" ] && atualizar=1
out="${SAIDA:-resultados}"; mkdir -p "$out"
relatorio="$out/relatorio.md"; : > "$relatorio"
regrediu=0

command -v promptfoo >/dev/null || { echo "promptfoo não encontrado no PATH"; exit 2; }
curl -fsS "${OLLAMA_BASE_URL:-http://localhost:11434}/api/tags" >/dev/null || { echo "Ollama não responde"; exit 2; }

aquecer() { # o primeiro uso de um modelo frio inclui o carregamento e estoura a latência
  curl -s "${OLLAMA_BASE_URL:-http://localhost:11434}/api/generate" \
    -d "{\"model\":\"$1\",\"prompt\":\"oi\",\"stream\":false,\"keep_alive\":\"30m\",\"options\":{\"num_ctx\":8192,\"num_predict\":5}}" >/dev/null || true
}
for p in $PROMPTS; do
  case "$p" in nota-de-triagem|triagem-de-pods|networkpolicy-sentinel) aquecer llama3.2:3b; aquecer gemma3:4b; break;; esac
done

rodar() { # <prompt> <tentativa>
  promptfoo eval -c "devops/$1/promptfooconfig.yaml" --no-cache -j 1 --no-progress-bar -o "$out/$1.json" > "$out/$1.console.txt" 2>&1 || true
  node .github/scripts/resumir.js "$out/$1.json" > "$out/$1.resumo.json"
}

for p in $PROMPTS; do
  echo "== $p"
  if [ ! -f "devops/$p/promptfooconfig.yaml" ]; then echo "- \`$p\`: sem promptfooconfig.yaml" >> "$relatorio"; regrediu=1; continue; fi
  rodar "$p"
  if [ "$atualizar" = 1 ]; then cp "$out/$p.resumo.json" ".github/baseline/$p.json"; echo "linha de base de $p atualizada"; continue; fi
  if [ ! -f ".github/baseline/$p.json" ]; then
    echo "## $p" >> "$relatorio"; echo "### REGRESSÃO: prompt sem linha de base (.github/baseline/$p.json)" >> "$relatorio"; regrediu=1; continue
  fi
  cmp_out="$(node .github/scripts/comparar.js ".github/baseline/$p.json" "$out/$p.resumo.json")"; cod=$?
  # o juiz LLM varia entre execuções: uma reprovação isolada é refeita uma vez, e só barra se repetir
  if [ "$cod" = 1 ] && [ "$p" = "causa-raiz" ]; then
    echo "juiz reprovou; repetindo uma vez"
    rodar "$p"
    cmp_out="$(node .github/scripts/comparar.js ".github/baseline/$p.json" "$out/$p.resumo.json")"; cod=$?
  fi
  { echo "## $p"; echo "$cmp_out"; echo; } >> "$relatorio"
  [ "$cod" != 0 ] && regrediu=1
done
cat "$relatorio"
exit "$regrediu"
````

### `.github/scripts/resumir.js`

````javascript
#!/usr/bin/env node
// resumir.js — reduz o JSON do `promptfoo eval` a um resumo comparável.
// Uso: node .github/scripts/resumir.js <resultado.json> > resumo.json
// Cada resultado vira { caso, modelo, asserts: [{id, ok}] } (asserts comuns)
// ou { caso, modelo, notas: [c1, c2, c3, c4] } (juiz LLM: uma nota de 0 a 2 por critério).
const fs = require('fs');

const arquivo = process.argv[2];
if (!arquivo) {
  console.error('uso: resumir.js <resultado.json>');
  process.exit(2);
}
const dados = JSON.parse(fs.readFileSync(arquivo, 'utf-8'));
const rotulo = (a) => {
  const v = a.value === undefined ? a.threshold ?? '' : String(a.value).replace(/\s+/g, ' ').trim();
  return `${a.type}:${String(v).slice(0, 120)}`;
};
const resumo = dados.results.results.map((r) => {
  const comp = (r.gradingResult && r.gradingResult.componentResults) || [];
  const base = { caso: r.testCase.description, modelo: r.provider.label };
  if (comp.length && comp.every((c) => c.assertion && c.assertion.type === 'llm-rubric')) {
    return { ...base, notas: comp.map((c) => Math.round(c.score)) };
  }
  // failureReason: 0 = passou, 1 = assert falhou, 2 = erro de execução (modelo fora do ar, tempo esgotado)
  if (r.failureReason === 2) return { ...base, erro: String(r.error).slice(0, 200), asserts: [] };
  return { ...base, asserts: comp.map((c) => ({ id: rotulo(c.assertion), ok: !!c.pass })) };
});
console.log(JSON.stringify(resumo, null, 2));
````

### `.github/scripts/comparar.js`

````javascript
#!/usr/bin/env node
// comparar.js — o gate do pipeline: falha só quando um prompt REGRIDE em relação à linha de base.
// Uso: node .github/scripts/comparar.js <baseline.json> <resumo.json>
// Regras:
//   - assert que passava na linha de base e agora falha                      => regressão (bloqueia)
//   - assert que já falhava na linha de base e continua falhando             => defeito conhecido (não bloqueia)
//   - assert que não existe na linha de base                                  => novo (informa; bloqueia se falhar)
//   - caso com juiz LLM: aprovado na linha de base (soma >= 6, nenhuma nota 0) e reprovado agora => regressão
// Saída: Markdown no stdout. Código de saída 0 = sem regressão, 1 = regressão, 2 = erro de uso ou de dados.
const fs = require('fs');

const [, , arqBase, arqNovo] = process.argv;
if (!arqBase || !arqNovo) {
  console.error('uso: comparar.js <baseline.json> <resumo.json>');
  process.exit(2);
}
const base = JSON.parse(fs.readFileSync(arqBase, 'utf-8'));
const novo = JSON.parse(fs.readFileSync(arqNovo, 'utf-8'));
const chave = (r) => `${r.caso} | ${r.modelo}`;
const mapaBase = new Map(base.map((r) => [chave(r), r]));
const aprovado = (n) => n.length === 4 && n.reduce((a, b) => a + b, 0) >= 6 && !n.includes(0);

const regressoes = [];
const conhecidos = [];
const novos = [];
let comparados = 0;

for (const r of novo) {
  const b = mapaBase.get(chave(r));
  if (!b) {
    regressoes.push(`caso sem linha de base: ${chave(r)}`);
    continue;
  }
  if (r.erro) {
    regressoes.push(`${chave(r)}: erro na execução (${r.erro})`);
    continue;
  }
  if (r.notas) {
    comparados += 1;
    const antes = b.notas || [];
    if (aprovado(antes) && !aprovado(r.notas)) {
      regressoes.push(`${chave(r)}: o juiz aprovava (${antes.join(',')} = ${antes.reduce((a, c) => a + c, 0)}) e agora reprova (${r.notas.join(',')} = ${r.notas.reduce((a, c) => a + c, 0)})`);
    } else if (!aprovado(r.notas)) {
      conhecidos.push(`${chave(r)}: juiz reprovado (${r.notas.join(',')}), já era assim na linha de base`);
    }
    continue;
  }
  const antes = new Map((b.asserts || []).map((a) => [a.id, a.ok]));
  for (const a of r.asserts) {
    comparados += 1;
    if (!antes.has(a.id)) {
      (a.ok ? novos : regressoes).push(`${chave(r)}: assert novo ${a.ok ? 'passa' : 'FALHA'}: ${a.id}`);
    } else if (antes.get(a.id) && !a.ok) {
      regressoes.push(`${chave(r)}: ${a.id}`);
    } else if (!a.ok) {
      conhecidos.push(`${chave(r)}: ${a.id}`);
    }
  }
}

const bloco = (titulo, itens) =>
  itens.length ? `\n\n**${titulo} (${itens.length})**\n\n${itens.map((i) => `- ${i}`).join('\n')}\n` : '';
const veredito = regressoes.length ? 'REGRESSÃO: o build falha' : 'sem regressão em relação à linha de base';
console.log(`### ${veredito}\n\nAsserts comparados: ${comparados}.${bloco('Regressões', regressoes)}${bloco('Defeitos conhecidos, não bloqueiam', conhecidos)}${bloco('Asserts novos', novos)}`);
process.exit(regressoes.length ? 1 : 0);
````
