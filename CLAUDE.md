# CLAUDE.md

Orientações para o Claude Code (claude.ai/code) neste repositório.

## Propósito

Playbook de IA Operacional: biblioteca de prompts parametrizáveis da Aegis (empresa fictícia), versionada, testada com `promptfoo` e protegida por pipeline no GitHub Actions. É o repositório de entrega de um desafio da pós-graduação em AIOps e IA com Engenharia Cloud. A organização do repositório é avaliada.

Não há aplicação a executar. O repositório contém documentação Markdown, prompts, configurações do `promptfoo`, um provedor em JavaScript e o workflow do GitHub Actions.

## Estrutura

A organização segue o repositório `frameworks-prompt-engineering` (pasta por etapa, arquivos numerados, documentação na raiz). Cada etapa é um `checkpoints/checkpoint-XX/`:

```text
checkpoints/checkpoint-XX/
  README.md            # mesmo frontmatter do prompt.md + documentação (CP01–06)
  prompt.md            # frontmatter + texto do prompt, com {{placeholders}}
  promptfooconfig.yaml # teste do prompt (a partir do CP08)
  01-contexto.md  02-prompt.md  03-execucao.md  04-curadoria.md
  entradas/            # dados do enunciado, transcritos
```

Na raiz: `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `LICENSE`, `validate.sh`, `providers/`. O `NAVIGATION.md`, o `SUMMARY.md`, `assets/` (Mermaid), `references.md` e `lessons-learned.md` entram no fechamento do projeto. Não existem as categorias do template `prompt-registry` (`devops/` etc.).

## Regras

- **Frontmatter** idêntico em `prompt.md` e `README.md` do checkpoint: `nome`, `descricao`, `versao` (semver, inicial `1.0.0`), `tags` (2 a 5) e `inputs` (um item por placeholder `{{...}}`, com `nome` e `descricao`; `inputs: []` se não houver).
- **`prompt.md`** tem só o frontmatter e o texto do prompt. O texto é autocontido e não cita outros arquivos do repositório.
- **`02-prompt.md`** traz o prompt final com texto idêntico ao corpo do `prompt.md`; o `validate.sh` confere.
- **Idioma:** pt-BR em prompts e documentação.
- **Nada fabricado:** output de modelo, resultado de teste e execução de pipeline só entram no repositório se foram realmente obtidos. Registrar sempre o modelo e o fornecedor usados.
- **Execuções** via Ollama, sem API paga. O provedor `providers/ollama-local.js` devolve `cost: 0` para o assert `cost` do `promptfoo`.
- Antes de concluir uma mudança, rodar `./validate.sh`.

## Git

- Commit semântico, mensagem de uma linha, com a etapa como escopo (ex.: `docs(checkpoint-01): adiciona prompt de triagem de pods`).
- O push é feito pelo mantenedor.
- Documentos de acompanhamento locais ficam fora do repositório (`.gitignore`).
