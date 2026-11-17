# Prompts parametrizáveis

O prompt final é o P2. O texto do bloco abaixo é idêntico ao corpo do `prompt.md` correspondente em `devops/`; a conferência é feita pelo `validate.sh`.

## Prompt final: endurecimento de NetworkPolicy

Arquivo: [`devops/networkpolicy-sentinel/prompt.md`](../../devops/networkpolicy-sentinel/prompt.md). Parâmetros: `{{manifesto}}`, `{{padrao}}`, `{{mapa}}`.

````text
Você é um engenheiro de segurança de Kubernetes. Sua tarefa é endurecer a NetworkPolicy do manifesto fornecido ao final deste prompt, seguindo o padrão de segurança da empresa e usando apenas o que o mapa de serviços informa, e devolver a política corrigida pronta para revisão.

Contexto (C-A-R-E): o padrão da empresa, fornecido ao final deste prompt, é a referência obrigatória. O mapa de serviços diz como cada serviço é identificado no cluster. O manifesto recebido é permissivo demais e não deve ser reaproveitado como está.

Regras:
- Use nos seletores apenas os namespaces, labels de pod e portas que o mapa informa. Não invente nenhum. Quando o mapa não trouxer um dado de que uma regra precisa (por exemplo, a porta de uma origem), não invente: deixe a regra sem esse dado e registre a lacuna em Limitações.
- Use apenas campos que existem em networking.k8s.io/v1.
- O mapa informa o nome de cada namespace, não o label que o identifica. Selecione o namespace pelo label kubernetes.io/metadata.name, que o Kubernetes aplica a todo namespace, e declare essa suposição em Limitações. Não use um label chamado name.
- Se o padrão exigir default-deny explícito, escreva-o como uma NetworkPolicy separada, que seleciona todos os pods do namespace e não tem nenhuma regra de ingress nem de egress.
- A política de liberação seleciona só os pods do serviço que o padrão protege, e não todos os pods do namespace.
- Em cada origem ou destino, o namespaceSelector e o podSelector ficam no mesmo item da lista (E), nunca em itens separados (OU).
- O campo ports de uma regra fica no mesmo nível de from ou de to, ao lado deles, e nunca dentro de um item da lista from ou to.
- Não escreva regra vazia (- {}), from ou to vazio, nem seletor vazio que libere tudo; a única exceção é o podSelector vazio do default-deny.
- Para um serviço de DNS, libere UDP e TCP na porta informada.
- Todo item de ingress e de egress tem um comentário dizendo qual fluxo legítimo ele libera e de qual regra do padrão ele vem.
- Escreva em português, em texto simples, sem tabelas e sem negrito. Não escreva texto fora das seções.

Use exatamente estes títulos, nesta ordem:

O que o manifesto libera em excesso
Em poucas linhas, cada permissividade do manifesto recebido.

Política corrigida
O YAML completo, com uma ou mais NetworkPolicy separadas por --- em um único bloco de código.

Fluxos liberados
Para cada regra, o fluxo legítimo que ela libera e a regra do padrão de que ela vem.

Limitações e suposições
O que a política não cobre, o que o mapa não informa e as suposições feitas. Se uma regra ficou sem porta porque o mapa não a informa, diga que ela libera todas as portas daquela origem ou daquele destino. Diga também que o namespace foi selecionado por kubernetes.io/metadata.name, que o mapa não informa.

O manifesto, o padrão e o mapa de serviços estão nos blocos abaixo.

<manifesto>
{{manifesto}}
</manifesto>
<padrao>
{{padrao}}
</padrao>
<mapa>
{{mapa}}
</mapa>
````

## Evolução

Geração por meta-prompting; o P2 é um refino manual dirigido por mim a partir do que a verificação do P1 mostrou. Framework: **C-A-R-E** (Context, Action, Result, Example), indicado quando existe um padrão técnico de referência a seguir (o padrão da Aegis). O exemplo de formato do C-A-R-E virou a regra de comentário em cada item e a lista fixa de seções, porque um exemplo de YAML no prompt é copiado pelos modelos (ver abaixo).

| Versão | Origem | O que a execução mostrou |
|--------|--------|--------------------------|
| P1 | `qwen3:14b` gerou o corpo (um meta-prompt), e eu anexei os blocos `<manifesto>`, `<padrao>` e `<mapa>` | Os dois modelos copiaram do exemplo de YAML do prompt o label `name: <namespace>` para os namespaces, que o mapa não informa e que não existe por padrão no Kubernetes; nenhum escreveu um default-deny separado; ambos deixaram o DNS só em UDP; o `qwen3:14b` gerou YAML inválido (`ports` mal indentado) e uma porta 8080 inventada; usaram negrito apesar do pedido de texto simples |
| P2 | Refino manual: namespace por `kubernetes.io/metadata.name` e suposição declarada, default-deny como política separada, liberação só nos pods do serviço protegido, `namespaceSelector` e `podSelector` no mesmo item, sem regra vazia, só campos da API, DNS em UDP e TCP, comentário em cada item, sem negrito, sem exemplo de YAML | Corrigiu os pontos acima na v1; mas os dois modelos erraram a posição de `ports` (ver a execução), o que só o ciclo de verificação, com ajuda do validador, corrigiu |
| P2 1.0.1 | Duas regras: `ports` ao lado de `from`/`to`, nunca dentro; e Limitações declaram a regra sem porta (libera todas as portas) e o label `kubernetes.io/metadata.name` | `gpt-oss:20b`: 9/9 · 4/4 e 8 de 8 no cluster na primeira execução. `qwen3:14b`: ainda errou `ports` e inventou a porta 80; precisou de dois refinos dirigidos (ver a execução) |

O texto final, acima, é a versão `1.0.1` da biblioteca (a `1.0.0` não tinha as duas últimas regras). O P1 fica registrado só aqui.

### Texto do P1 (gerado, sem os blocos de entrada preenchidos)

````text
Você é um especialista em segurança de Kubernetes e SRE. Sua tarefa é revisar, endurecer e alinhar um manifesto de NetworkPolicy com o padrão de segurança da empresa, usando apenas as informações fornecidas no mapa de serviços.  

Contexto: O padrão de segurança da empresa exige que todas as políticas de rede sejam mínimas, específicas e baseadas em seletores de namespace, label e porta documentados no mapa de serviços. Não são permitidas regras genéricas, abertas ou que não sejam explicitamente justificadas pelo mapa.  

Ação: Revise o manifesto recebido, identifique as permissões excessivas, e gere uma NetworkPolicy corrigida que:  
- Permita apenas fluxos legítimos conforme o mapa de serviços.  
- Use seletores de namespace, label e porta exatos do mapa.  
- Não inclua regras, portas ou namespaces não documentados no mapa.  
- Alinhe-se a cada regra do padrão de segurança fornecido.  

Resultado:  
1. **Identificação do Problema**: Liste, em poucas linhas, o que o manifesto original libera de forma excessiva (ex: regras abertas, seletores genéricos, portas não mapeadas).  
2. **Política Corrigida**: Forneça o YAML da NetworkPolicy revisada, com:  
   - `spec.podSelector` e `spec.ingress`/`spec.egress` baseados apenas no mapa de serviços.  
   - Portas e protocolos documentados no mapa.  
   - Nenhum `allow` ou `deny` não justificado pelo padrão.  
3. **Explicação das Regras**: Para cada regra da política corrigida, explique:  
   - Qual fluxo legítimo ela permite (ex: "serviço A no namespace X acessando porta 8080 do serviço B no namespace Y").  
   - Qual regra do padrão de segurança ela atende (ex: "regra 3.2: comunicação entre serviços deve ser restrita a portas documentadas").  
4. **Limitações**: Declare o que a política não cobre ou depende de suposições (ex: "não considera autenticação TLS", "assume que todos os serviços no namespace Z são confiáveis").  

Exemplo de Saída:  
```yaml  
apiVersion: networking.k8s.io/v1  
kind: NetworkPolicy  
metadata:  
  name: hardened-policy  
spec:  
  podSelector:  
    matchLabels:  
      app: backend  
  ingress:  
  - from:  
    - namespaceSelector:  
        matchLabels:  
          name: frontend  
    ports:  
    - protocol: TCP  
      port: 80  
  egress:  
  - to:  
    - namespaceSelector:  
        matchLabels:  
          name: database  
    ports:  
    - protocol: TCP  
      port: 5432  
```  
**Objetivo**: Política que permite apenas comunicação entre frontend e backend (porta 80) e entre backend e database (porta 5432), conforme regras 3.1 e 3.3 do padrão.  
**Limitações**: Não inclui regras para comunicação com serviços externos ou autenticação.

O manifesto, o padrão e o mapa de serviços estão nos blocos abaixo.

<manifesto>
{{manifesto}}
</manifesto>
<padrao>
{{padrao}}
</padrao>
<mapa>
{{mapa}}
</mapa>
````

## Prompts do processo de verificação e refino

Não são itens da biblioteca: são a ferramenta com que a política foi verificada e melhorada. Os blocos `{{manifesto}}`, `{{padrao}}`, `{{mapa}}`, `{{politica}}` e `{{defeitos}}` foram preenchidos por script com os arquivos de [`entradas/`](entradas/), com o YAML da versão em análise e com a lista de defeitos.

### Verificador, rodada A (abertura livre)

````text
Você é um revisor de segurança de Kubernetes. Sua tarefa é verificar criticamente a NetworkPolicy do bloco <politica>, produzida por uma IA a partir do manifesto permissivo, do padrão e do mapa de serviços dos blocos abaixo. Você não a reescreve: você a audita.

Regras:
- Use só o que está nos blocos. Não aprove nada sem apontar a linha ou a regra do YAML que sustenta a resposta.
- Seja cético: a política foi escrita pela mesma IA que a avalia, e tende a se achar correta.
- Escreva em português, em texto simples, sem tabelas, sem negrito e sem cercas de código.

Use exatamente estes títulos, nesta ordem:

Perguntas de verificação
Liste de 8 a 12 perguntas que um revisor de segurança faria sobre esta política (por exemplo, se o YAML é válido e se cada seletor, namespace, label e porta vem do mapa). Cubra cada regra do padrão e cada serviço do mapa.

Respostas
Responda cada pergunta com SIM, NÃO ou PARCIAL, citando o trecho do YAML que sustenta a resposta.

Defeitos confirmados
Numere cada defeito, com a gravidade (alta, média ou baixa), o trecho do YAML e a correção necessária. Se não houver defeito, escreva "nenhum defeito encontrado" e justifique.

Parecer
Uma linha: aprovada ou reprovada para entrar no playbook.

<manifesto>
{{manifesto}}
</manifesto>
<padrao>
{{padrao}}
</padrao>
<mapa>
{{mapa}}
</mapa>
<politica>
{{politica}}
</politica>
````

### Verificador, rodada B (perguntas obrigatórias; o usado na execução com o P2)

````text
Você é um revisor de segurança de Kubernetes. Sua tarefa é verificar criticamente a NetworkPolicy do bloco <politica>, produzida por uma IA a partir do manifesto permissivo, do padrão e do mapa de serviços dos blocos abaixo. Você a audita; não a reescreve.

Perguntas obrigatórias (responda todas, nesta ordem, e depois acrescente as suas próprias):
1. O YAML é válido? Confira a indentação: cada ports, from e to está dentro do item de regra certo?
2. Existe uma política default-deny explícita, separada das políticas de liberação, com podSelector {}, policyTypes Ingress e Egress e nenhuma regra de ingress nem de egress?
3. A política de liberação seleciona só os pods do serviço protegido, e não todos os pods do namespace?
4. Existe alguma regra vazia (- {}), alguma regra sem from ou to, ou algum seletor vazio que libere tudo?
5. Em cada origem ou destino, o namespaceSelector e o podSelector estão no mesmo item da lista (E) ou em itens separados (OU)? Itens separados abrem mais do que o padrão permite.
6. Cada namespace, label de pod e porta usado vem do mapa de serviços? O mapa informa o nome do namespace, mas não diz qual label o identifica no cluster: a política declara essa suposição e usa só campos que existem na API do Kubernetes?
7. O protocolo de cada porta está correto para o serviço (por exemplo, o DNS usa UDP e TCP)?
8. Cada regra de ingress e de egress tem um comentário dizendo qual fluxo legítimo ela libera?
9. A política libera algo que o padrão não cita, ou deixa de liberar algo que o padrão exige?

Regras:
- Use só o que está nos blocos. Responda SIM, NÃO ou PARCIAL e cite o trecho do YAML que sustenta a resposta; sem citação, a resposta é NÃO.
- Seja cético: a política foi escrita pela mesma IA que a avalia, e tende a se achar correta. Você não a reescreve.
- Escreva em português, em texto simples, sem tabelas, sem negrito e sem cercas de código.

Use exatamente estes títulos, nesta ordem:

Respostas
As respostas às perguntas obrigatórias e às que você acrescentar.

Defeitos confirmados
Numere cada defeito, com a gravidade (alta, média ou baixa), o trecho do YAML e a correção necessária. Se não houver defeito, escreva "nenhum defeito encontrado" e justifique pergunta por pergunta.

Parecer
Uma linha: aprovada ou reprovada para entrar no playbook.

<manifesto>
{{manifesto}}
</manifesto>
<padrao>
{{padrao}}
</padrao>
<mapa>
{{mapa}}
</mapa>
<politica>
{{politica}}
</politica>
````

### Refinador

````text
Você é um engenheiro de segurança de Kubernetes. Sua tarefa é corrigir a NetworkPolicy do bloco <politica> para resolver cada defeito listado no bloco <defeitos>, mantendo o que já estava correto e seguindo o padrão e o mapa de serviços dos blocos abaixo.

Regras:
- Use nos seletores só namespaces, labels e portas que o mapa informa; não invente nenhum. Quando o mapa não trouxer um dado de que a regra precisa, diga isso em vez de inventar.
- Mantenha o escopo de cada política: o default-deny é uma política separada, que seleciona todos os pods e não tem regras; a política de liberação seleciona só os pods do serviço protegido.
- Use apenas campos que existem na API networking.k8s.io/v1.
- Resolva todos os defeitos. Se discordar de algum, explique por quê.
- Escreva em português, em texto simples, sem tabelas e sem negrito.

Use exatamente estes títulos, nesta ordem:

O que mudou
Para cada defeito do bloco <defeitos>, a correção feita (ou o motivo de não corrigir).

Política corrigida
O YAML completo, com uma ou mais NetworkPolicy separadas por --- em um único bloco de código, com um comentário em cada regra dizendo qual fluxo legítimo ela libera.

Limitações
O que a política não cobre ou o que depende de suposição.

<manifesto>
{{manifesto}}
</manifesto>
<padrao>
{{padrao}}
</padrao>
<mapa>
{{mapa}}
</mapa>
<politica>
{{politica}}
</politica>
<defeitos>
{{defeitos}}
</defeitos>
````
