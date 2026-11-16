# Curadoria

## Decisão de método e framework

O enunciado diz que o padrão pode ser ensinado ao modelo de mais de uma forma e pede que a escolha seja justificada. Foram comparados dois frameworks do curso:

- **C-A-R-E** (Context, Action, Result, Example): ensina por exemplo; as três notas do time entram no prompt.
- **R-T-F** (Role, Task, Format): ensina por tarefa e formato, com regras de conteúdo por linha; sem papel explícito, porque o prompt não precisa de persona.

**Escolhido: R-T-F, sem exemplos.** Os dois métodos foram comparados com o restante do prompt idêntico (a variante de regras é a de exemplos sem a seção de exemplos), nos mesmos 3 alertas e nos mesmos 2 modelos:

| Medida (v5, 6 execuções por variante) | Regras | Exemplos |
|---------------------------------------|--------|----------|
| Notas 100% no padrão (5 linhas, ordem dos rótulos, handle, ≤ 8 linhas, sem tags, sistema no `ALERTA`, números do alerta, escalonamento com "se" e prazo) | 6 de 6 | 6 de 6 |
| Trechos de 4 palavras vindos dos exemplos que aparecem nas notas, por saída | 0, 2, 2, 0, 5, 2 (total 11) | 0, 20, 9, 1, 6, 13 (total 49) |
| Cópias de conteúdo confirmadas na leitura | nenhuma | 3 |

As cópias confirmadas na variante de exemplos: o `qwen3:14b` escreveu "deploy do Relay às 02:55 reduziu o buffer de ingestão" (a hipótese do exemplo com o horário trocado; o alerta só diz que o buffer saturou após o deploy) e "rollback do deploy em progresso" (ação que o alerta não menciona); o `gpt-oss:20b` escreveu "dashboards do Sentinel atrasados para todos os tenants" (impacto do exemplo; o alerta não diz isso). O total de 11 trechos na variante de regras é a linha de base de vocabulário comum do domínio, e não cópia.

**Por quê.** Os três exemplos do time são todos de Relay, Forge e Cerebro, e dois dos três alertas de teste são de Relay e Forge. Com exemplos, o modelo tende a reaproveitar causa, impacto e ação do exemplo vizinho. Já as regras por linha, derivadas dos exemplos, entregam o mesmo formato sem esse efeito. Nada disso diminui o valor dos exemplos: foi lendo as três notas do time que se chegou às regras (o sistema abre o `ALERTA`, o `IMPACTO` é efeito e não métrica, a hipótese é afirmação curta, o handle é do time dono).

**Quando os exemplos ajudaram.** Enquanto as regras eram fracas (v2), a variante de exemplos acertou o formato em 6 de 6 execuções e a de regras em 1 de 6. Parte da falha da variante de regras vinha da posição do alerta no meio de uma frase (os modelos devolviam as tags `<alerta>`), e não do método, e por isso a comparação final foi refeita com a estrutura idêntica.

## O que foi refinado

1. **Parâmetro e delimitadores:** uma versão não tinha `{{alerta_cru}}`, outra o colocava no meio de uma frase. O alerta passou para um bloco final com `<alerta>` e `</alerta>` em linhas próprias.
2. **Conteúdo de cada linha:** o `ALERTA` perdeu o sistema, o `IMPACTO` repetia métricas, a hipótese saía como "HIPÓTESE de ...", o handle era genérico. Cada linha ganhou uma regra.
3. **Handles:** os modelos inventavam handles. O prompt passou a ter uma tabela.
4. **Fidelidade:** os modelos inventaram "70 réplicas" e ferramentas (kubectl, Argo CD). A regra da ação passou a proibir números, ferramentas, comandos ou sistemas ausentes do alerta e a afirmar que algo já foi feito.

Nas rodadas 1, 2 e 3 o texto veio do `qwen3:14b` por meta-prompting. A rodada 3 não incorporou três dos cinco defeitos apontados, e a v4 foi um **refino manual dirigido por mim**, aplicado sobre o texto gerado.

## Limitações conhecidas

- **Handle do Sentinel é suposição.** Relay, Forge e Cerebro usam os handles dos exemplos do time (`@relay-core`, `@data-platform`, `@search-infra`). Para o Sentinel não havia exemplo, e o prompt usa `@sentinel-core`. Precisa de confirmação do time.
- **Prazos de escalonamento são sugestão do modelo** (5 ou 15 minutos nas seis notas finais); o alerta não os traz.
- **Ação imediata especulativa:** os modelos propõem reiniciar serviços ou escalar réplicas sem evidência de que resolva. Na nota do Alerta 1, o `gpt-oss:20b` sugeriu "reiniciar o autoscaler".
- **Mistura de idiomas:** como o prompt manda copiar termos do alerta, aparecem trechos em inglês (`ingest reject rate`, e no Alerta 3 do `gpt-oss:20b` "Sentinel ingestion lags").
- **O verificador usado na comparação é meu**, não o `promptfoo`; os asserts oficiais vêm no CP08. A contagem de trechos de 4 palavras mede sobreposição, e não prova cópia sozinha; por isso as três cópias foram confirmadas lendo as saídas.
- Uma execução por modelo e alerta, com `temperature 0`; não se mediu a variação entre execuções.
