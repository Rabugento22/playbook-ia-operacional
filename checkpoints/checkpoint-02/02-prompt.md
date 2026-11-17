# Prompt parametrizável

Parâmetro: `{{alerta_cru}}` — o texto do alerta como disparado pelo Sentinel.

O texto abaixo é idêntico ao corpo de [`devops/nota-de-triagem/prompt.md`](../../devops/nota-de-triagem/prompt.md), que é o arquivo versionado da biblioteca; a conferência é feita pelo `validate.sh`.

## Versão final (v5)

````text
Transforme o alerta cru em uma nota de triagem padronizada com cinco linhas, seguindo o formato abaixo. Use apenas as informações fornecidas no alerta, sem suposições ou dados não mencionados. O conteúdo deve respeitar as regras de cada linha.

Formato (cinco linhas consecutivas, nesta ordem; cada rótulo é seguido do texto na mesma linha):
ALERTA: <sistema> - <condição do alerta>
IMPACTO: <efeito para clientes ou produto>
HIPÓTESE INICIAL: <causa provável>
AÇÃO IMEDIATA: <ação do plantão>
ESCALAR PARA: <handle> se <condição com tempo>

Regras de conteúdo:
1. ALERTA: comece com o nome do sistema (Sentinel, Relay, Forge, Cerebro), seguido de hífen e de uma frase curta com a condição do alerta. Inclua o tenant se mencionado.
2. IMPACTO: descreva o efeito para clientes ou produto (o que deixa de funcionar ou fica lento e para quem), apenas o que o alerta sustenta, sem repetir métricas do alerta.
3. HIPÓTESE INICIAL: afirmação direta e curta da causa provável, baseada em evidência do próprio alerta, sem usar a palavra "hipótese".
4. AÇÃO IMEDIATA: ação específica do plantão, coerente com a hipótese; evite "revisar" ou "monitorar" genéricos. Não cite números, ferramentas, comandos ou sistemas que o alerta não mencione, e não diga que uma ação já foi feita.
5. ESCALAR PARA: handle do time dono do sistema que você escreveu em ALERTA:, conforme a tabela abaixo, seguido de "se" e de uma condição com tempo. Os handles são: Relay → @relay-core; Forge → @data-platform; Cerebro → @search-infra; Sentinel → @sentinel-core.
6. Copie números, tenants, horários e nomes de serviços exatamente como estão no alerta. Não invente nenhum dado ausente do alerta.
7. Escreva em português correto, sem markdown e sem linhas em branco.

Tabela de handles (use o handle da linha cujo sistema aparece em ALERTA:, sem trocar por outro):
Relay → @relay-core
Forge → @data-platform
Cerebro → @search-infra
Sentinel → @sentinel-core

Responda somente com as cinco linhas da nota, sem as tags <alerta> e sem texto antes ou depois.

Alerta a ser analisado:
<alerta>
{{alerta_cru}}
</alerta>
````

## Método: duas variantes comparadas

O enunciado pede que se escolha, e se justifique, como ensinar o padrão. Foram construídas duas variantes pelo mesmo caminho (meta-prompting com o `qwen3:14b` via Ollama) e executadas nos 3 alertas com `qwen3:14b` e `gpt-oss:20b`:

| Variante | Framework do curso | Como ensina o padrão |
|----------|--------------------|----------------------|
| Exemplos (few-shot) | C-A-R-E (Context, Action, Result, **Example**) | As três notas do time coladas no prompt |
| Regras | R-T-F (Role, Task, **Format**), sem papel explícito | Formato e regras de conteúdo por linha, sem nenhuma nota pronta |

Os três exemplos do time **não** são os alertas de teste, então não há contaminação do teste.

## Evolução

| Versão | O que mudou | O que a execução mostrou |
|--------|-------------|--------------------------|
| v1 (regras) | 1ª rodada de meta-prompting | Cumpriu a estrutura, mas o `ALERTA` perdeu o nome do sistema, o `IMPACTO` repetia métricas, a hipótese saiu como "HIPÓTESE de ...", e o handle foi o genérico `@ops`. |
| v1 (exemplos) | 1ª rodada de meta-prompting | Saiu **sem o parâmetro** `{{alerta_cru}}`: impossível executar. |
| v2 (as duas) | 2ª rodada, com esses defeitos como feedback | Regras: o alerta ficou no meio de uma frase, os modelos devolveram as tags `<alerta>`, e uma saída teve as cinco linhas coladas em uma só (1 de 6 no padrão). Exemplos: 6 de 6 no padrão, mas com cópia de conteúdo dos exemplos. |
| v3 (exemplos) | 3ª rodada, pedindo tabela de handles, fidelidade e bloco final | Só incorporou a tabela de handles; não resolveu a cópia dos exemplos nem a posição do alerta. |
| v4 (as duas) | Refino manual dirigido: alerta em bloco final, regra de fidelidade, tabela de handles; a variante de regras é a mesma sem a seção de exemplos | Estrutura em 6 de 6 nas duas. Os modelos inventaram detalhes na ação (ex.: "70 réplicas"). |
| v5 (as duas) | Regra da ação: não citar números, ferramentas ou comandos ausentes do alerta, nem dizer que algo já foi feito | Detalhes inventados deixaram de aparecer. **Regras escolhida** (ver [curadoria](04-curadoria.md)). |
