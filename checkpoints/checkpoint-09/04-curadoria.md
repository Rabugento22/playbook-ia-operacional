# Curadoria

Dados em [`03-execucao.md`](03-execucao.md); notas de referência em [`calibracao/pontuacao-referencia.md`](calibracao/pontuacao-referencia.md).

## Resumo honesto

O gate funciona de ponta a ponta, reprova as análises ruins das amostras e aprovou a análise real que o prompt `causa-raiz` gerou (7 de 8). **A calibração que o enunciado pede não foi atingida por inteiro:** o enunciado quer o juiz a no máximo 1 ponto da referência em cada critério, e em cada execução do juiz final um dos 32 pares ficou a 2 pontos. Além disso, **a referência foi dada pelo Claude, e não pelo Rubens**, e o juiz **não é determinístico**: duas execuções do mesmo juiz deram notas diferentes em seis das oito amostras.

## Como o juiz foi calibrado

A primeira versão (v1) era um único prompt que pontuava os quatro critérios e somava. Contra a referência, 5 dos 32 pares ficaram a 2 pontos e a decisão (aprova ou reprova) coincidiu em 4 de 8 amostras. O que aprendi em cada rodada:

1. **O juiz é brando.** A v1 deu 8 de 8 a seis das oito amostras, entre elas as respostas de pedido solto que a referência reprova com 2 e 3. As regras de rigor da v2 ajudaram só em parte.
2. **O juiz erra a soma.** Na v1, a amostra C recebeu `C1=1; C2=1; C3=1; C4=2` e `total=6` (a soma é 5) e foi aprovada por causa disso. Por isso a soma e a regra de aprovação saíram do juiz e foram para o `gate.js`.
3. **O juiz copia a rubrica e os fatos como se fossem da análise.** Nas amostras E e G, que não têm nenhuma seção de limitações, o juiz deu 2 em honestidade epistêmica citando como prova a frase "os dados não dizem por que a reindexação andou devagar...", que era do **próprio texto do juiz** (os fatos do caso). Corrigi marcando os fatos como "não fazem parte da análise", tirando dali as frases que entregavam a resposta (v3 e v6) e exigindo uma citação literal da análise (v3).
4. **Uma chamada por critério.** Pedir os quatro critérios de uma vez fazia a nota de um contaminar a dos outros e o JSON de resposta quebrar quando a justificativa tinha aspas duplas. A v5 passou a fazer uma chamada por critério e foi a primeira a ficar com 6 de 8 decisões iguais.
5. **O raciocínio ligado não ajudou** o `qwen3:14b`: notas ainda longe da referência, e uma avaliação (amostra E) estourou o limite de 300 s do `fetch` do Node e falhou.
6. **Troquei o juiz para o `gpt-oss:20b`** (raciocínio `low`): com os mesmos textos, ficou mais perto da referência (de 6 para 7 a 8 de 8 decisões iguais, de 2 para 1 par a 2 pontos) e leva cerca de 5 minutos nas oito amostras (cada amostra: 4 chamadas). É um desvio da D14, que previa o `qwen3:14b` como juiz; o gerador do gate passou a ser o `qwen3:14b`.
7. **Uma regra a mais piorou:** a v10 mandava olhar o título da seção para decidir se algo é causa ou efeito; a decisão igual caiu de 7 ou 8 para 6 de 8, e foi descartada. Mais regras não são melhores.

Versão final (v9): `juiz.txt` com os fatos do caso, quatro arquivos de critério e o `gate.js`.

## O que o gate acerta e erra

- **Acerta** o que as amostras têm de mais claro: a D (a pior, sem causa-raiz) é reprovada nas duas execuções, e a B e a H (as melhores da referência, com 7) são aprovadas nas duas.
- **Erra a favor** nas amostras do meio: a F, que a referência reprova com 5 por um ponto, foi aprovada com 7 na execução 2; a C teve C1=0 nas duas execuções, onde a referência dá 1.
- **Varia entre execuções.** O mesmo juiz, o mesmo texto e `temperature 0` deram notas diferentes em seis das oito amostras (a amostra A variou de 2 para 0 no C3). Não investiguei a causa; a variação aparece com `temperature 0` e com o cache do `promptfoo` desligado.

## Limitações

- **A referência não é humana.** O enunciado pede a pontuação do aluno. As notas são do Claude, a pedido do Rubens, e não foram cegas ao juiz (o Claude tinha visto os totais da primeira rodada). A calibração mede o quanto o juiz se parece com o Claude. Se o Rubens revisar as notas, a conta muda; as mais discutíveis estão listadas no arquivo da pontuação.
- **Oito amostras, um caso.** O juiz foi ajustado com as mesmas oito amostras em que foi medido, e os fatos da degradação do Cerebro estão dentro do texto dele. Não há garantia de que valha para outro incidente, nem de que o ajuste não tenha se encaixado nessas amostras. Um conjunto separado de amostras confirmaria.
- **Ruído do juiz.** Com notas que variam até 2 pontos entre execuções, um build pode ser reprovado ou aprovado por flutuação, especialmente perto do corte (F, 5 a 7 pontos). É a preocupação que o próprio enunciado do CP10 levanta.
- **Um juiz de família diferente do gerador reduz o favorecimento do próprio texto, mas não o elimina:** o juiz continua lendo os fatos e a rubrica, que descrevem a resposta certa.
- **A análise do gate não é um teste de regressão ainda.** Aqui o gate mostrou que reprova texto ruim; reprovar uma regressão do prompt na hora de uma mudança fica para o CP10.

## Para o CP10

- Rodar o gate duas vezes e exigir que as duas aprovem (ou usar a pior nota) reduz aprovação por sorte, ao custo de mais tempo; rodar uma vez e aceitar só reprovações claras (total ≤ 4) reduz reprovação por sorte. A escolha é do gate do pipeline e está na T055.
- O juiz usa o `gpt-oss:20b` e o gerador usa o `qwen3:14b`: o runner precisa dos dois modelos e de memória para alternar entre eles (cerca de 5 minutos por execução do gate).
- O custo em dinheiro é zero; o custo em tempo é o que pesa.
