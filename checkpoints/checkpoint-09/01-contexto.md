# Contexto

## O que o enunciado pede

O CP08 cobriu o que se verifica sem opinião (formato, latência, custo). A análise de causa-raiz do CP03 não tem resposta única verificável por regex, então o CP09 acrescenta um **gate de qualidade** para ela, com um **LLM-as-judge**:

1. Uma rubrica de quatro critérios (causa-raiz correta; correlação × causa; ação proporcional; honestidade epistêmica), cada um de 0 a 2, total de 0 a 8. Aprova com **total ≥ 6 e nenhum critério zerado**. A rubrica está em [`02-rubrica.md`](02-rubrica.md).
2. Um `promptfooconfig.yaml` em `devops/causa-raiz/` com um juiz (`llm-rubric`) que aplica essa rubrica e reprova abaixo do corte.
3. **Calibração**: pontuar algumas saídas à mão e ajustar o prompt do juiz até a nota dele ficar a no máximo 1 ponto da nota humana em cada critério.
4. O gate roda a cada alteração do prompt de causa-raiz; a execução automática vem no CP10.

## Decisões

- **Juiz:** `qwen3:14b` (Alibaba), via Ollama (D14). O modelo é o mesmo que gera a análise em alguns testes; isso favorece o juiz (um modelo tende a gostar do texto que ele mesmo escreveria) e é uma limitação registrada na curadoria.
- **Quem pontua à mão:** o Rubens. A calibração só vale se as notas de referência forem humanas; as minhas não entram como referência.
- **Amostras para calibrar:** saídas reais, sem edição, do prompt de causa-raiz e de variações dele, com modelos de qualidades diferentes, para que a rubrica seja exercitada em notas altas e baixas. Cada amostra recebe um código neutro; o Rubens pontua sem ver a nota do juiz.
- **Cálculo do total fora do juiz:** o juiz devolve as quatro notas; a aprovação é calculada pela regra da rubrica (ver [`02-rubrica.md`](02-rubrica.md)).
