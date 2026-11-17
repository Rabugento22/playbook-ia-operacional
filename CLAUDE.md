# CLAUDE.md

Orientações para o Claude Code (claude.ai/code) neste repositório.

## Propósito

Playbook de IA Operacional: biblioteca de prompts parametrizáveis da Aegis (empresa fictícia), versionada, testada com `promptfoo` e protegida por pipeline no GitHub Actions. É o repositório de entrega de um desafio da pós-graduação em AIOps e IA com Engenharia Cloud. A organização do repositório é avaliada.

Não há aplicação a executar. O repositório contém documentação Markdown, prompts, configurações do `promptfoo`, um provedor em JavaScript e o workflow do GitHub Actions.

## Estrutura

Os caminhos seguem o enunciado do desafio (`devops/<prompt>/promptfooconfig.yaml`) e as convenções do template `prompt-registry`. A documentação por etapa segue o padrão do repositório `frameworks-prompt-engineering`.

```text
devops/
  README.md                    # escopo da categoria + índice dos prompts
  <nome-do-prompt>/            # nomeado pelo resultado, em kebab-case
    prompt.md                  # frontmatter + texto do prompt, com {{placeholders}}
    README.md                  # mesmo frontmatter + documentação humana
    promptfooconfig.yaml       # teste do prompt (a partir do CP08)
checkpoints/checkpoint-XX/     # o caminho de cada checkpoint
  README.md  01-contexto.md  02-prompt.md  03-execucao.md  04-curadoria.md
  entradas/                    # dados do enunciado, transcritos
providers/ollama-local.js  carregar-prompt.js
.github/
  workflows/prompts.yml        # suíte de prompts em PR e push (runner self-hosted)
  scripts/  baseline/          # gate: compara com a linha de base e falha só em regressão
```

Na raiz: `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `LICENSE`, `validate.sh`. O `NAVIGATION.md`, o `SUMMARY.md`, `assets/` (Mermaid), `references.md` e `lessons-learned.md` entram no fechamento do projeto. A única categoria é `devops/`; não se criam categorias vazias.

## Regras

- **Frontmatter** idêntico em `prompt.md` e `README.md` do checkpoint: `nome`, `descricao`, `versao` (semver, inicial `1.0.0`), `tags` (2 a 5) e `inputs` (um item por placeholder `{{...}}`, com `nome` e `descricao`; `inputs: []` se não houver).
- **`prompt.md`** tem só o frontmatter e o texto do prompt. O texto é autocontido e não cita outros arquivos do repositório.
- **`checkpoints/checkpoint-XX/02-prompt.md`** traz o prompt final com texto idêntico ao corpo de `devops/<prompt>/prompt.md` e aponta para ele; o `validate.sh` confere.
- **Prioridade:** o enunciado do PDF tem precedência sobre qualquer outra convenção; havendo conflito, vale o PDF.
- **Versão do prompt:** nasce em `1.0.0`; qualquer mudança no texto sobe a `versao` no `prompt.md` e no `README.md` (iguais) e vai em commit semântico.
- **Idioma:** pt-BR em prompts e documentação.
- **Nada fabricado:** output de modelo, resultado de teste e execução de pipeline só entram no repositório se foram realmente obtidos. Registrar sempre o modelo e o fornecedor usados.
- **Execuções** via Ollama, sem API paga. O provedor `providers/ollama-local.js` devolve `cost: 0` para o assert `cost` do `promptfoo`.
- Antes de concluir uma mudança, rodar `./validate.sh`.

## Git

- Commit semântico, mensagem de uma linha, com a etapa como escopo (ex.: `feat(devops): adiciona prompt de triagem de pods`; para documentação do caminho, `docs(checkpoint-01): ...`).
- O push é feito pelo mantenedor.
- Documentos de acompanhamento locais ficam fora do repositório (`.gitignore`).
