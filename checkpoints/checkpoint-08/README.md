# Checkpoint 08 — Testes determinísticos com promptfoo

## Objetivo

Escrever um `promptfooconfig.yaml` para cada prompt de saída estruturada (`nota-de-triagem`, `triagem-de-pods` e `networkpolicy-sentinel`), com os asserts que o enunciado pede e os limites de 5 s e US$ 0,01, rodar `promptfoo eval` de verdade e registrar o que passou e o que falhou.

## Onde estão os testes

Cada teste fica ao lado do seu prompt, em `devops/<prompt>/promptfooconfig.yaml`:

- [`devops/nota-de-triagem/promptfooconfig.yaml`](../../devops/nota-de-triagem/promptfooconfig.yaml)
- [`devops/triagem-de-pods/promptfooconfig.yaml`](../../devops/triagem-de-pods/promptfooconfig.yaml)
- [`devops/networkpolicy-sentinel/promptfooconfig.yaml`](../../devops/networkpolicy-sentinel/promptfooconfig.yaml)

Esta pasta guarda o caminho percorrido.

## Arquivos

| Arquivo | Conteúdo |
|---------|----------|
| [`01-contexto.md`](01-contexto.md) | O que o enunciado pede, o que dá para testar sem julgamento e como rodar |
| [`02-testes.md`](02-testes.md) | Os três arquivos de configuração, assert por assert, e as mudanças de prompt feitas por causa dos testes |
| [`03-execucao.md`](03-execucao.md) | Modelos, motivo, a saída real de cada execução com pass/fail, a primeira rodada e o comparativo |
| [`04-curadoria.md`](04-curadoria.md) | O que passou, o que falhou, o que foi ajustado e o trade-off entre latência e qualidade |
| [`resultados/`](resultados/) | Os arquivos brutos do `promptfoo` (JSON e tabela do terminal) |

## Como reproduzir

```bash
# 1. aquecer os modelos (a primeira chamada de um modelo frio estoura a latência)
for m in llama3.2:3b gemma3:4b; do
  curl -s localhost:11434/api/generate -d "{\"model\":\"$m\",\"prompt\":\"oi\",\"stream\":false,\"keep_alive\":\"30m\",\"options\":{\"num_ctx\":8192,\"num_predict\":5}}" > /dev/null
done
# 2. rodar um teste, a partir da raiz do repositório
promptfoo eval -c devops/nota-de-triagem/promptfooconfig.yaml --no-cache -j 1
```

## Resumo do resultado

Com `llama3.2:3b` (Meta) e `gemma3:4b` (Google), via Ollama: `nota-de-triagem` passa em 5 de 6 execuções, `triagem-de-pods` em 3 de 6 e `networkpolicy-sentinel` em 0 de 2. O `nota-de-triagem` só chegou lá depois de mudar o formato do prompt (versão `1.0.1`). O `triagem-de-pods` reprova no caso saudável nos dois modelos, que inventam pods problemáticos, e o `networkpolicy-sentinel` reprova na latência (5,8 e 9,2 s) e nos comentários. Um comparativo com o `qwen3:14b` mostra que a causa é o trade-off do enunciado: ele passa quase todos os asserts de conteúdo, mas leva de 3 a 38 s.
