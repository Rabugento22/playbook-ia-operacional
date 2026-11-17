# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).

## [Não lançado]

### Adicionado

- Pipeline `.github/workflows/prompts.yml` com os scripts de seleção, execução, resumo e comparação com a linha de base (`.github/baseline/`), e o checkpoint 10 (testes dos prompts de saída aberta e documentação do pipeline).
- Checkpoint 09: rubrica, juiz LLM como gate em `devops/causa-raiz/` (`promptfooconfig.yaml`, `juiz.txt`, `criterio-1..4.txt`, `gate.js`), amostras, calibração e curadoria.
- Checkpoint 08: `promptfooconfig.yaml` de `nota-de-triagem`, `triagem-de-pods` e `networkpolicy-sentinel`, com `providers/carregar-prompt.js`, execuções reais, comparativo com o `qwen3:14b` e curadoria.
- Checkpoint 07: nota de mapeamento do playbook nas convenções do template `prompt-registry`.
- Estrutura do repositório: `devops/` (biblioteca), `checkpoints/checkpoint-XX/` (caminho) e documentação na raiz.
- Provedor `providers/ollama-local.js` para o `promptfoo` com o Ollama local.
- Entradas dos checkpoints 01 a 06, transcritas do enunciado.
- Prompt `devops/triagem-de-pods` (`1.0.0`).
- Prompts `devops/migracao-forge-diagnostico`, `-plano` e `-execucao` (`1.0.0`), a cadeia do CP05, com janelas de consumo protegidas ao longo dos três elos.
- Checkpoint 05: contexto, evolução v1 a v3 com medições, duas cadeias completas (um modelo cada) e curadoria.
- Prompt `devops/decisao-backpressure` (`1.0.0`).
- Checkpoint 04: contexto do cenário, evolução do prompt (v1 a v4), execução nos dois modelos e curadoria.
- Prompt `devops/networkpolicy-sentinel` (`1.0.1`), com teste das políticas em um cluster `kind`.
- Checkpoint 06: contexto, evolução do prompt (P1 → P2 → 1.0.1), prompts de verificação e refino, iterações v1 a v4 nos dois modelos, scripts e resultados do teste em cluster e curadoria.
- Prompt `devops/causa-raiz` (`1.0.0`).
- Checkpoint 03: contexto com decisão de sanitização, evolução do prompt, execução nos dois modelos e com dados mascarados, e curadoria.
- Prompt `devops/nota-de-triagem` (`1.0.0`).
- Checkpoint 02: contexto, comparação entre ensinar o padrão por regras ou por exemplos, execução nos dois modelos e curadoria.
- Checkpoint 01: contexto, evolução do prompt, execução nos dois modelos e curadoria.

### Alterado

- `devops/nota-de-triagem` `1.0.1`: o formato mostra cada linha preenchível e o handle é o do sistema escrito em `ALERTA:`, para os modelos pequenos do CP08 seguirem o formato.
