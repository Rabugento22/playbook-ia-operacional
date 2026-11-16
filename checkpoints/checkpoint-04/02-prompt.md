# Prompt parametrizável

Parâmetro: `{{cenario}}` — o estado atual do sistema e as restrições do time, em um bloco no fim do prompt.

O texto abaixo é idêntico ao corpo de [`devops/decisao-backpressure/prompt.md`](../../devops/decisao-backpressure/prompt.md), que é o arquivo versionado da biblioteca; a conferência é feita pelo `validate.sh`.

## Versão final (v4)

````text
Você é um especialista em arquitetura de sistemas distribuídos e SRE. Sua tarefa é apoiar uma decisão de arquitetura cara e sem resposta única: como segurar o excesso de carga (backpressure) descrito no cenário fornecido ao final deste prompt, comparando caminhos antes de recomendar.

Siga estas etapas, nesta ordem:

1. Reformule o cenário. Separe os fatos, as restrições rígidas (violá-las causa dano contratual ou perda irreversível) e as restrições flexíveis (podem ser negociadas), justificando cada classificação. Não presuma nenhuma tecnologia, produto ou capacidade que o cenário não cite; se um caminho depender de algo assim, apresente isso como condição a verificar.

2. Faça as contas que os dados permitem (por exemplo, excedente de carga, duração, volume acumulado, tempo para recuperar o atraso e comparação com a retenção e com os SLAs), mostrando cada passo com as unidades (mensagens, segundos, minutos, horas) e conferindo a conversão entre elas. Distinga a carga observada (por exemplo, o throughput sustentado) da capacidade máxima do sistema: se a capacidade máxima não estiver nos dados, trate-a como incógnita, mostre a conta em função dela e não a substitua por um valor suposto sem declarar a suposição. Se faltar outro dado, diga qual.

3. Proponha pelo menos três caminhos com mecanismos realmente diferentes; combinações são aceitas. Se o cenário indicar consumidores ou clientes com criticidades diferentes, pelo menos um caminho deve tratar essa diferença.

4. Para cada caminho, descreva: como funciona; como se comporta diante de cada restrição rígida, com justificativa; prós; contras; riscos; custo e complexidade, em termos qualitativos; e o que precisa ser verdade para funcionar. Não diga que um caminho "garante" um SLA sem explicar o mecanismo. Um mecanismo que aumenta o atraso não pode ser apresentado como garantia de latência.

5. Monte uma tabela comparativa com colunas separadas por barras verticais: uma linha por restrição ou critério, uma coluna por caminho, com "atende", "parcial" ou "não atende" e uma justificativa curta em cada célula. Não use HTML.

6. Recomende um caminho ou uma combinação. Explique por que ele foi escolhido, por que os demais foram descartados, o que a recomendação sacrifica de forma consciente e como ela se comporta no pico descrito, usando os mesmos números e unidades da etapa 2. Antes de concluir, confira se a recomendação não contradiz as contas nem as restrições rígidas (por exemplo, um atraso calculado acima de um SLA não pode ser declarado dentro dele).

7. Declare os limites da análise: o que o cenário não informa e mudaria a decisão, quais afirmações suas são suposições, como validar a recomendação antes de adotá-la (teste, métrica ou experimento) e em que condições a decisão deve ser revista. Não invente dados, custos ou capacidades ausentes do cenário.

Formato de saída: use exatamente estes títulos, em texto simples. Não use asteriscos (*), negrito nem cercas de código em nenhum ponto da resposta: Reformulação do cenário; Contas; Caminhos propostos; Tabela comparativa; Recomendação; Limites e validação. Não escreva texto fora dessas seções.

<cenario>
{{cenario}}
</cenario>
````

## Evolução

Geração por meta-prompting; as versões 3 e 4 são refinos manuais dirigidos por mim.

| Versão | Origem | Defeitos observados |
|--------|--------|---------------------|
| v1 | `qwen3:14b`, pedindo o prompt completo com o placeholder em um bloco final | **Apagou o placeholder** (bloco `<cenario>` vazio); sem papel nem títulos fixos. Não foi executada. |
| v2 | `qwen3:14b`, pedindo só o corpo (o bloco `<cenario>{{cenario}}</cenario>` é anexado depois) | Estrutura boa e placeholder único. Na execução: os dois modelos **presumiram Kafka** (o cenário não cita tecnologia); ninguém calculou o excesso de carga (210 M de mensagens); "garante o SLA" sem mecanismo; custo "médio" declarado "dentro do orçamento" já estourado; pausar o consumidor apresentado como forma de não passar de 15 min; HTML dentro de tabelas. |
| v3 | Refino manual: não presumir tecnologia, fazer as contas, justificar cada restrição, um caminho que trate criticidades diferentes, tabela sem HTML | Tecnologia deixou de ser premissa e as contas apareceram, mas com erros: o `qwen3:14b` escreveu "210M / 180k ≈ 1.167 minutos (70 segundos)" (1.167 é em segundos, ≈ 19 min) e usou 70 s na recomendação; calculou a retenção como `180k * 4 * 60`; o `gpt-oss:20b` recomendou que o Forge processasse 199 M msgs "em até 15 min" a 180k/s (≈ 18 min). Os dois trataram o throughput sustentado como capacidade máxima. |
| v4 | Refino manual: conferir unidades e conversões, distinguir carga observada de capacidade máxima, conferir a recomendação contra as contas e os SLAs, proibir asteriscos | Erro de unidade do `qwen3:14b` corrigido e a capacidade máxima passa a ser declarada incógnita por ele; novos erros de raciocínio (ver [curadoria](04-curadoria.md)). Versão final. |
