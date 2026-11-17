# Checkpoint 09 — Gate de qualidade com LLM-as-judge

## Objetivo

Acrescentar ao prompt `causa-raiz` (saída aberta, sem regex possível) um gate de qualidade com LLM-as-judge: uma rubrica de quatro critérios (0 a 2, corte em 6, nenhum critério zerado), um juiz configurado no `promptfoo` e a calibração do juiz contra uma pontuação de referência.

## Onde está o gate

Em `devops/causa-raiz/`: [`promptfooconfig.yaml`](../../devops/causa-raiz/promptfooconfig.yaml), [`juiz.txt`](../../devops/causa-raiz/juiz.txt), `criterio-1.txt` a `criterio-4.txt` e [`gate.js`](../../devops/causa-raiz/gate.js). Esta pasta guarda o caminho percorrido.

## Arquivos

| Arquivo | Conteúdo |
|---------|----------|
| [`01-contexto.md`](01-contexto.md) | O que o enunciado pede e as decisões |
| [`02-rubrica.md`](02-rubrica.md) | A rubrica, o desenho do juiz e os arquivos do gate, idênticos aos de `devops/causa-raiz/` |
| [`03-execucao.md`](03-execucao.md) | Modelos, amostras, as versões do juiz, a variação entre execuções e a execução do gate |
| [`04-curadoria.md`](04-curadoria.md) | Como o juiz foi calibrado, o que ajustei, o que o gate acerta e erra, e as limitações |
| [`amostras/`](amostras/) | Oito saídas reais para a calibração, com códigos neutros (a chave em `CHAVE.md`) |
| [`calibracao/`](calibracao/) | Pontuação de referência, configuração da calibração, textos de cada versão do juiz e resultados brutos |

## Resumo do resultado

O gate roda e aprovou a análise real do `causa-raiz` (7 de 8), e reprova as amostras ruins. A calibração ficou **parcial**: o juiz final (`gpt-oss:20b`, uma chamada por critério) ficou a no máximo 1 ponto da referência em 31 dos 32 pares em cada execução, e em um par a 2 pontos. As notas de referência foram dadas pelo Claude, a pedido do Rubens, e não pelo Rubens; e o juiz varia entre execuções (seis de oito amostras tiveram nota diferente em duas execuções iguais). Troquei o juiz previsto (`qwen3:14b`) pelo `gpt-oss:20b`, que ficou mais perto da referência.
