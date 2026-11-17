# Checkpoint 07 — A biblioteca vira código

## Objetivo

Organizar os prompts dos checkpoints 01 a 06 como uma biblioteca versionada, nas convenções do template [`prompt-registry`](https://github.com/fabricioveronez/prompt-registry), e registrar como o playbook foi mapeado nelas.

## O que foi entregue

| Item do enunciado | Onde está |
|-------------------|-----------|
| Repositório baseado no template | Este repositório. O link público entra aqui quando o repositório for publicado (T023). |
| Um prompt completo como exemplo dos demais | [`devops/triagem-de-pods/`](../../devops/triagem-de-pods/): [`prompt.md`](../../devops/triagem-de-pods/prompt.md) (frontmatter e texto com `{{snapshot}}`) e [`README.md`](../../devops/triagem-de-pods/README.md) (o mesmo frontmatter, objetivo, quando usar, exemplo e limitações) |
| Nota de mapeamento | A seção abaixo |

Os oito prompts da biblioteca estão em [`devops/`](../../devops/), listados no [`README.md`](../../devops/README.md) da categoria.

## Nota de mapeamento do playbook nas convenções do template

O ponto de partida foram os arquivos de um fork do `prompt-registry` (copiados, sem o histórico do template). O que veio do template, e o que mudou:

| Convenção do template | Como o playbook a aplica |
|-----------------------|--------------------------|
| Categoria como pasta na raiz, em kebab-case, sem aninhar | Só `devops/`, porque os seis checkpoints são de operação de plataforma. As categorias de exemplo do template (`desenvolvimento/`, `financas/`, `produtividade/`, `criacao-conteudo/`) e o comando `catalogar` foram removidos para não deixar categorias vazias nem resíduos |
| Uma pasta por prompt, nomeada pelo resultado | `triagem-de-pods`, `nota-de-triagem`, `causa-raiz`, `decisao-backpressure`, `networkpolicy-sentinel`. O CP05, que é uma cadeia de três prompts encadeados, virou três pastas: `migracao-forge-diagnostico`, `migracao-forge-plano` e `migracao-forge-execucao`. São 8 prompts para 6 checkpoints |
| `prompt.md`: frontmatter e texto, com `{{variavel}}` | Idêntico à convenção. O texto é autocontido e não cita outros arquivos do repositório |
| `README.md`: o mesmo frontmatter e a documentação | O frontmatter é idêntico ao do `prompt.md`; a documentação traz objetivo, quando usar, como usar, exemplo (com saída real de modelo) e limitações. A cadeia do Forge acrescenta a seção "Posição na cadeia" |
| Frontmatter: `nome`, `descricao`, `versao`, `tags`, `inputs` | `inputs` lista exatamente os placeholders do `prompt.md`, com `nome` e `descricao`; tags de 2 a 5 |
| `versao` em semver, inicial `1.0.0` | Todos nasceram em `1.0.0`. O `networkpolicy-sentinel` está em `1.0.1`, porque mudou depois do primeiro commit (duas regras novas e o teste em cluster) |
| Commits semânticos com escopo na categoria | `feat(devops): adiciona prompt de ...` para cada prompt; `fix(devops)` para a correção do `networkpolicy-sentinel` |
| Índices nos READMEs atualizados | `devops/README.md` (um item por prompt) e o `README.md` da raiz (checkpoints e prompts) |

Foi acrescentado ao template o que o enunciado pede nos checkpoints seguintes e o que o projeto precisa para ser auditável:

- **`checkpoints/checkpoint-XX/`:** o caminho de cada prompt (contexto, evolução, execuções reais e curadoria). O `02-prompt.md` repete o texto final do prompt, e o `validate.sh` confere que é idêntico ao `prompt.md`.
- **`promptfooconfig.yaml` dentro de cada pasta de prompt**, a partir do CP08, como o enunciado indica.
- **`validate.sh`:** confere frontmatter idêntico, `inputs` iguais aos placeholders, índices, `02-prompt.md` e links.
- **`providers/ollama-local.js`:** provedor do `promptfoo` para os modelos locais, com custo zero.

## O que ainda falta neste checkpoint

- O link do repositório público (depende da publicação, T023).
