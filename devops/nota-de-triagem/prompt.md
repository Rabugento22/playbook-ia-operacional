---
nome: Nota de triagem de alerta
descricao: Transforma um alerta cru do Sentinel em uma nota de triagem padronizada de cinco rótulos para o plantonista do turno seguinte.
versao: 1.0.1
tags: [alertas, triagem, plantao, sentinel]
inputs:
  - nome: alerta_cru
    descricao: Texto do alerta como disparado pelo Sentinel, sem edição
---

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
