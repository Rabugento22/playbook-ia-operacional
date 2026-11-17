# Contexto

## O que o enunciado pede

O CP08 cobriu o que se verifica sem opinião (formato, latência, custo). A análise de causa-raiz do CP03 não tem resposta única verificável por regex, então o CP09 acrescenta um **gate de qualidade** para ela, com um **LLM-as-judge**:

1. Uma rubrica de quatro critérios (causa-raiz correta; correlação × causa; ação proporcional; honestidade epistêmica), cada um de 0 a 2, total de 0 a 8. Aprova com **total ≥ 6 e nenhum critério zerado**. A rubrica está em [`02-rubrica.md`](02-rubrica.md).
2. Um `promptfooconfig.yaml` em `devops/causa-raiz/` com um juiz (`llm-rubric`) que aplica essa rubrica e reprova abaixo do corte.
3. **Calibração**: pontuar algumas saídas à mão e ajustar o prompt do juiz até a nota dele ficar a no máximo 1 ponto da nota humana em cada critério.
4. O gate roda a cada alteração do prompt de causa-raiz; a execução automática vem no CP10.

## Decisões

- **Juiz:** começou como `qwen3:14b` (Alibaba), via Ollama, como previsto na D14. Terminou como **`gpt-oss:20b`** (OpenAI), porque, na calibração, o `qwen3:14b` se afastou mais das notas de referência (ver [`04-curadoria.md`](04-curadoria.md)). O gerador do gate passou a ser o `qwen3:14b`; assim juiz e gerador são de famílias diferentes, para reduzir o favorecimento do próprio texto.
- **Quem pontua à mão:** o enunciado pede que o próprio aluno pontue. O Rubens delegou a pontuação ao Claude, então **as notas de referência são do Claude, e não de um humano**. Isso está dito no arquivo das notas e na curadoria, e o Rubens pode revisá-las.
- **Amostras para calibrar:** saídas reais, sem edição, do prompt de causa-raiz e de variações dele, com modelos de qualidades diferentes, para que a rubrica seja exercitada em notas altas e baixas. Cada amostra recebe um código neutro. A pontuação de referência não foi cega: o Claude já tinha visto os totais da primeira rodada do juiz.
- **Cálculo do total fora do juiz:** o juiz devolve as notas, e a aprovação sai de um `gate.js` (ver [`02-rubrica.md`](02-rubrica.md)).
