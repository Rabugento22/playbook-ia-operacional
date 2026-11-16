# Contribuindo

Este repositório trata os prompts como código: toda mudança tem versão, commit semântico e teste.

## Estrutura de um checkpoint

Veja a árvore no [`README.md`](README.md). O prompt vive em `devops/<nome-do-prompt>/` (`prompt.md`, `README.md` e, a partir do CP08, `promptfooconfig.yaml`). O caminho percorrido vive em `checkpoints/checkpoint-XX/` (`README.md` e quatro arquivos numerados), e o `02-prompt.md` repete o texto final do prompt, idêntico ao `prompt.md`.

Um prompt novo entra com `versao: 1.0.0`, é listado no `README.md` de `devops/` e no índice da raiz.

## Frontmatter

```yaml
---
nome: Nome humano do prompt
descricao: Uma linha descrevendo o objetivo
versao: 1.0.0
tags: [tag1, tag2]
inputs:
  - nome: variavel
    descricao: O que a variável representa
---
```

- O bloco é idêntico em `prompt.md` e `README.md`.
- Cada placeholder `{{variavel}}` do prompt aparece em `inputs`, e só ele.
- `versao` segue semver: mudança de saída ou de parâmetros incompatível é MAJOR; melhoria compatível é MINOR; ajuste de redação é PATCH.

## Commits

Formato `tipo(escopo): descrição`, uma linha. Tipos usados: `feat`, `fix`, `docs`, `test`, `ci`, `chore`. O escopo é a categoria do prompt ou a área: `feat(devops): adiciona prompt de triagem de pods`, `docs(checkpoint-01): ...`, `ci: ...`.

## Validação

```bash
./validate.sh
```

Confere os arquivos obrigatórios, a estrutura dos checkpoints, o frontmatter, os placeholders e os links relativos.

## Registro de execuções

Toda execução registra o modelo, o fornecedor, os parâmetros e o output real, sem edição. Se um teste falhar, o registro mostra a falha e o que foi ajustado.
