---
nome: Nota de triagem de alerta
descricao: Transforma um alerta cru do Sentinel em uma nota de triagem padronizada de cinco rótulos para o plantonista do turno seguinte.
versao: 1.0.1
tags: [alertas, triagem, plantao, sentinel]
inputs:
  - nome: alerta_cru
    descricao: Texto do alerta como disparado pelo Sentinel, sem edição
---

# Nota de triagem de alerta

## Objetivo

Padronizar a nota que o plantonista abre a cada alerta do Sentinel. O prompt recebe o alerta cru em `{{alerta_cru}}` e devolve uma nota de exatamente cinco linhas (`ALERTA:`, `IMPACTO:`, `HIPÓTESE INICIAL:`, `AÇÃO IMEDIATA:`, `ESCALAR PARA:`), com um handle `@time` e uma condição de escalonamento com prazo.

## Quando usar

- Ao receber um alerta e abrir a nota de triagem.
- Para que o plantão seguinte leia notas no mesmo formato, independentemente de quem as escreveu.
- Os alertas devem ser colados sem edição; o prompt não busca dados em nenhuma fonte.

## Como usar

1. Copie o texto de [`prompt.md`](prompt.md) (depois do frontmatter).
2. Troque `{{alerta_cru}}` pelo texto do alerta.
3. Execute em um modelo e cole a nota no registro do incidente.

## Exemplo

Entrada ([`alerta-2-relay.txt`](../../checkpoints/checkpoint-02/entradas/alerta-2-relay.txt)):

```text
2026-05-13 03:11:00 UTC [Relay] ingest reject rate 6% for 8min, tenant wakanda-systems,
buffer saturated after deploy 02:55
```

Saída real do `qwen3:14b` (via Ollama):

```text
ALERTA: Relay - ingest reject rate 6% para tenant wakanda-systems  
IMPACTO: Ingestão de dados para o tenant wakanda-systems está lenta ou falhando, afetando processamento de novos dados  
HIPÓTESE INICIAL: Buffer de ingestão está saturado devido à implantação realizada às 02:55  
AÇÃO IMEDIATA: Reverter ou ajustar a implantação que causou a saturação do buffer  
ESCALAR PARA: @relay-core se não houver melhora em 15 minutos
```

As seis execuções da versão final estão em [`03-execucao.md`](../../checkpoints/checkpoint-02/03-execucao.md).

## Limitações

- **Os handles são os do próprio prompt.** A tabela cobre Relay, Forge e Cerebro (os handles dos exemplos do time) e usa `@sentinel-core` para o Sentinel, que não tinha exemplo: esse último é uma suposição a confirmar com o time.
- **Os prazos de escalonamento são sugestões do modelo** (5 ou 15 minutos); o alerta não os traz. O plantonista deve ajustá-los à política do time.
- A ação imediata é uma hipótese de trabalho, e não um procedimento validado; os modelos às vezes sugerem reiniciar serviços sem evidência de que isso resolva.
- Termos do alerta em inglês podem aparecer na nota (ex.: `ingest reject rate`), porque o prompt manda copiá-los fielmente.
- Uma execução por modelo e alerta; não se mediu a variação entre execuções.
- **Teste com modelos pequenos (CP08):** com `llama3.2:3b` e `gemma3:4b` o formato e a concisão passam nos 3 alertas; o `gemma3:4b` escolheu o handle de outro time em 1 dos 3. A versão `1.0.1` mudou o formato para linhas preenchíveis porque o `llama3.2:3b` tratava os rótulos como títulos. Detalhes em [`checkpoint-08`](../../checkpoints/checkpoint-08/).

## Documentação do caminho

O contexto, a comparação entre ensinar o padrão por regras ou por exemplos, as execuções e a curadoria estão em [`checkpoints/checkpoint-02/`](../../checkpoints/checkpoint-02/).
