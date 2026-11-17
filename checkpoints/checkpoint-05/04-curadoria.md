# Curadoria

## Frameworks por elo

Cada elo tem uma natureza diferente, e por isso o framework muda:

| Elo | Framework | Por quê |
|-----|-----------|---------|
| 1. Diagnóstico | **R-I-S-E** (Role, Input, Steps, Expectation) | Análise de um estado existente, com entrada (o cenário), passos (as seções) e resultado esperado; é o framework do curso para operações e troubleshooting |
| 2. Plano | **B-A-B** (Before, After, Bridge) | Transformação e modernização: o diagnóstico é o *Before*, o modelo orientado a eventos é o *After*, e as fases reversíveis são a *Bridge* |
| 3. Roteiro | **R-T-F** (Role, Task, Format) | Artefato técnico estruturado: o formato por fase (pré-condições, passos, verificação, go/no-go, rollback) é o que importa |

Os três prompts são genéricos (não citam o Forge) e compartilham o mesmo bloco de regras globais, para que as garantias e a disciplina de fidelidade atravessem a cadeia.

## O que foi refinado

1. **Corpo gerado e parâmetros anexados:** o `qwen3:14b` apaga placeholders (CP03 e CP04), então ele gerou só o corpo de cada elo e eu anexei os blocos `<cenario>`, `<diagnostico>` e `<plano>`.
2. **Regras globais e fidelidade (v1 → v2):**
   - Os dois modelos nomearam tecnologias que o cenário não cita; o prompt passou a mandar registrar a escolha de ferramenta como decisão em aberto.
   - Os dois criaram uma garantia de "segurança" que o cenário não declara, induzidos por um exemplo no prompt do elo 1; o exemplo saiu e o elo 1 passou a copiar as garantias do cenário literalmente.
   - Foram atribuídas tolerâncias de 60 min aos dependentes sem base; o prompt passou a pedir "não declarado" e a tratar isso como lacuna.
   - Uma fase foi declarada irreversível; o prompt proíbe isso e manda dividir o passo até haver caminho de volta.
3. **Troca de fonte por dependente:** a v2 exige uma etapa própria para cada dependente, para que a troca de um não obrigue a dos outros.
4. **Janelas de consumo (v2 → v3):** na v2, nenhum plano nem roteiro, de nenhum modelo, mencionava a madrugada do billing, embora o elo 1 a registrasse. A causa estava no desenho da cadeia: o elo 1 guardava a janela só dentro de "Dependentes", e o elo 2 mandava apenas "considerar os momentos de consumo". A v3 acrescenta ao elo 1 a seção "Janelas de consumo", acrescenta ao elo 2 a regra de janela protegida (uma linha por fase e a seção de verificação) e acrescenta ao elo 3 a regra de que nenhum passo ou rollback muda o que o dependente usa dentro da janela dele. O texto da regra não cita o cenário do Forge.

A v2 e a v3 são refinos manuais meus sobre o texto gerado.

## Avaliação das duas cadeias (versão final, v3)

| Garantia do cenário | `qwen3:14b` | `gpt-oss:20b` |
|---------------------|-------------|---------------|
| 1. Consumo contínuo do Relay em pequenos blocos | Atendida: ingestão contínua, processamento contínuo e gravação em paralelo ao lote | Atendida: ingestão paralela do Relay, transformação incremental e destino paralelo |
| 2. Dependentes funcionando | Não atendida de forma verificável: o plano tem quatro fases e nenhuma troca a fonte dos dependentes; a fase 4 exige que todos já usem o novo pipeline e declara "nenhum dependente é afetado" | Atendida em boa parte: sete fases, com uma etapa de troca de fonte para cada um dos três dependentes (fases 4, 5 e 6), validação antes e fallback |
| 3. Sem virada única e com volta | Atendida: quatro fases, todas com "como voltar atrás" | Atendida: sete fases com rollback; o descomissionamento (última fase) é o mais frágil, porque restaurar o que foi removido depende de backup |

Pontos fortes da cadeia do `gpt-oss:20b`: a progressão retira um risco por fase; cada dependente tem a sua própria fase de troca; o elo 3 traz gatilho e limite de tempo para cada rollback e uma proteção por dependente. O elo 1 de ambos separa corretamente "declarado" de "não declarado".

### Janela de madrugada do billing (v2 → v3)

| Onde | v2 (os dois modelos) | v3 `qwen3:14b` | v3 `gpt-oss:20b` |
|------|----------------------|----------------|------------------|
| Elo 1 | Registrada só dentro de "Dependentes" | Seção "Janelas de consumo" com a madrugada do billing | Seção presente, mas a madrugada aparece como "suposição de madrugada" |
| Plano | Ausente | Citada nas 4 fases como "respeitada" | Citada na fase 6, a troca do billing: "troca fora da madrugada" |
| Roteiro | Ausente | Citada na proteção do billing: "Janela protegida: Madrugada" | Citada na proteção do billing: "suposta madrugada; troca deve ocorrer fora da madrugada" |

A janela deixou de se perder entre os elos, que era a falha da v2.

## Falhas que permanecem

- **O `gpt-oss:20b` rebaixa a madrugada do billing a "suposição".** O cenário a declara ("rodam de madrugada"); o modelo escreve "janela não declarada (suposição de madrugada)" e o rótulo chega ao plano e ao roteiro. A restrição é respeitada, mas com menos força do que o cenário dá.
- **O `qwen3:14b` justifica a janela com um raciocínio errado.** Escreve que a janela é "respeitada, pois os dados não são consumidos durante esse período", quando a madrugada é justamente o período em que o billing consome.
- **O roteiro cita a janela só na proteção dos dependentes.** Nenhum dos dois modelos indica a janela proibida e o momento permitido em cada passo de troca, como a regra do elo 3 pede.
- **Regressão do `qwen3:14b` na v3:** o plano passou de cinco para quatro fases e perdeu a fase de troca dos dependentes que existia na v2. A v3 não foi desenhada para isso; a causa não foi investigada. Uma execução por modelo não permite dizer se é variação ou efeito das regras novas.
- **Produtos citados como exemplo:** o `qwen3:14b` escreve "(ex: Apache Flink, Kafka Streams)" ao registrar a escolha de ferramenta como decisão em aberto, o que a regra de não presumir tecnologia proíbe.
- **O `qwen3:14b` ainda cria números:** o exemplo "99,9%" aparece cinco vezes no plano como limiar, mesmo com a regra de escrever "limiar a definir". O `gpt-oss:20b` não cria números.
- **Limites de tempo e papéis inventados no elo 3:** "30 minutos" e "2 horas" para decidir um rollback, "líder de SRE" e "time de arquitetura".
- **Negrito ainda aparece no `qwen3:14b`** (16, 72 e 81 linhas por elo na v3).
- **Erros se propagam:** o prompt não valida a saída do elo anterior; um erro no diagnóstico chega ao roteiro.

## Limitações conhecidas

- **Uma execução da cadeia por modelo**, com `temperature 0`; a variação entre execuções não foi medida.
- **A comparação entre versões é por contagem de padrões** (tecnologias, tabelas, asteriscos, percentuais), que mede a obediência às regras e não a qualidade técnica do plano.
- **Não se testou um prompt único** para o mesmo cenário, então o ganho da cadeia sobre o prompt único não está medido.
- Os planos não são validados por quem opera o Forge; são ponto de partida para a discussão do time.
