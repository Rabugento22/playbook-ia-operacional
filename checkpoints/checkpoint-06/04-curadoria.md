# Curadoria

## Framework

**C-A-R-E** (Context, Action, Result, Example). O material de frameworks do curso indica o C-A-R-E quando existe um padrão técnico ou arquitetura de referência que deve ser seguido, e é o caso: o padrão da Aegis é a régua. O contexto é o padrão e o mapa, a ação é endurecer o manifesto, o resultado é um YAML com as seções fixas, e o exemplo de formato foi substituído por regras explícitas, porque o exemplo de YAML do P1 foi copiado pelos modelos (inclusive o label `name:` inventado). O R-T-F também serviria (a saída é um artefato técnico estruturado), mas não carrega a ideia de seguir um padrão.

## O que foi refinado

1. **Corpo gerado e parâmetros anexados:** o `qwen3:14b` gera só o corpo do prompt e eu anexo os blocos de entrada, porque ele apaga placeholders (CP03 e CP04).
2. **P1 → P2 (o prompt):** as regras do P2 respondem aos defeitos que o P1 produziu nos dois modelos: label `name:` inventado, ausência de default-deny separado, DNS só em UDP, porta 8080 inventada, YAML inválido, negrito. A tabela de evolução está em [`02-prompt.md`](02-prompt.md).
3. **O verificador (o processo):** a rodada A, com perguntas livres, aprovou políticas erradas; a rodada B passou a exigir nove perguntas minhas, com resposta citando o YAML.
4. **O validador determinístico:** entrou porque os verificadores continuaram errando a estrutura. O resultado dele é que levou à v4.

A rodada A, a B e o P2 foram executados nos dois modelos; as saídas completas estão em [`03-execucao.md`](03-execucao.md).

## Iterações do P2: o que a verificação apontou e como cada versão respondeu

### `gpt-oss:20b`

| Versão | O que a verificação apontou | Como a versão seguinte respondeu |
|--------|-----------------------------|----------------------------------|
| v1 (8/9 · 1/2) | O modelo **aprovou**: "nenhum defeito encontrado", e disse que a indentação estava correta. Erro dele: `ports` está dentro do item `to` nas três regras de egress (o kube-apiserver rejeita esse YAML) | v2: "nenhuma mudança foi necessária" |
| v2 (8/9 · 1/2) | O modelo aprovou de novo (mesmo erro) | v3: "nenhuma alteração" |
| v3 (8/9 · 1/2) | O modelo aprovou de novo (mesmo erro) | O validador acusou os três `ports` fora do lugar; v4 os moveu para o nível da regra |
| v4 (9/9 · 2/2) | Validador: nenhum item reprovado | Versão final |

### `qwen3:14b`

| Versão | O que a verificação apontou | Como a versão seguinte respondeu |
|--------|-----------------------------|----------------------------------|
| v1 (7/9 · 1/2) | Citou o trecho com o `- ports:` solto, mas o diagnosticou como `namespaceSelector` e `podSelector` "em itens separados" (OU), o que não era verdade: já estavam juntos. O erro real, `ports` fora do lugar, ficou sem nome | v2: "uniu" seletores que já estavam unidos; acrescentou comentários |
| v2 (7/9 · 1/2) | O mesmo falso positivo e um segundo: disse que `kubernetes.io/metadata.name` "não é comum" e sugeriu `kubernetes.io/namespace`, label que não existe | v3: repetiu a "correção" sem efeito e manteve o label correto |
| v3 (7/9 · 1/2) | O modelo citou o trecho com o `- ports:` solto, mas o diagnosticou como seletores em itens separados | O validador acusou os três `ports` fora do lugar; v4 os moveu para o nível da regra |
| v4 (9/9 · 2/2) | Validador: nenhum item reprovado | Versão final |

Nos dois modelos, **a v2 e a v3 não mudaram a política em nada que importasse**: o verificador ou aprovou, ou apontou um defeito que não existia. O ganho veio da v4, com o validador.

## Iterações do P1

Os verificadores também falharam no P1 (placar em [`03-execucao.md`](03-execucao.md)):

- **Rodada A (verificação aberta).** `qwen3:14b`: apontou o default-deny e a porta 8080 na v1, mas não o YAML inválido nem o `name:`. As versões seguintes acabaram **aprovadas com 7/9**. `gpt-oss:20b`: apontou o `name:` na v1 (acertou), mas sugeriu como correção `namespaceSelector: {}` (abre para todos os namespaces) e, na v2, o campo `matchNames`, que **não existe** na API do Kubernetes; a v3 foi **aprovada com 5/9**.
- **Rodada B (perguntas obrigatórias).** `gpt-oss:20b`: apontou o default-deny e `kubernetes.io/metadata.name` na v1 (os dois certos), a v2 chegou a 9/9 e foi corretamente aprovada, e a v3 apontou o DNS sem TCP (recomendação válida). `qwen3:14b`: repetiu o falso positivo de OU/E nas três versões (na v1 junto com dois defeitos reais, a porta 8080 e o default-deny), e a política já estava correta (9/9) desde a v2.

## O que o ciclo ensinou

- **A verificação feita pela IA que escreveu a política é útil e não é confiável.** Acertou o que é semântico (default-deny ausente, label do namespace, porta inventada) e errou o que é estrutural (posição de `ports`, indentação), aprovando políticas com defeito e reprovando políticas corretas.
- **Perguntas obrigatórias melhoraram a verificação** (rodada A → B), mas não a tornaram suficiente: o `gpt-oss:20b` respondeu "SIM, a indentação está correta" sobre um YAML que não estava.
- **Um validador determinístico é a contraprova que faltava.** Ele acusou o que os dois modelos não viram. É a justificativa para o CP08 (asserts do `promptfoo` sobre o YAML) e para o CP10 (portão no pipeline): artefato crítico passa por checagem que não depende do mesmo modelo que o escreveu.
- **Os erros do P1 vieram do prompt.** O exemplo de YAML que o gerador pôs no P1 foi copiado pelos dois modelos, como o exemplo de "segurança" no CP05.

## Avaliação da versão final

Placar do validador: os dois modelos terminam em 9/9 itens do padrão e 2/2 recomendados.

| Requisito do padrão e do enunciado | `qwen3:14b` v4 | `gpt-oss:20b` v4 |
|---|---|---|
| Default-deny explícito | Atendido, política separada (`ingress: []` e `egress: []`, equivalente a sem regras) | Atendido, política separada |
| Ingress só do Relay (`app=relay`, `relay-prod`) e do API gateway (`app=api-gateway`, `edge`) | Atendido | Atendido |
| Egress só para Forge 5432, Cerebro 9200 e DNS (`kube-system`, `k8s-app=kube-dns`, 53) | Atendido | Atendido |
| Sem `- {}` e sem allow-all | Atendido | Atendido |
| Comentário em cada regra | Atendido (conferido à mão) | Atendido (conferido à mão) |
| Só namespaces, labels e portas do mapa | Atendido; o namespace é selecionado por `kubernetes.io/metadata.name`, que o mapa não informa | Atendido, com a mesma suposição |

A versão que recomendo para o playbook é a do `gpt-oss:20b` (uma política de liberação com ingress e egress juntos, mais a de default-deny), por ser a mais enxuta de revisar. A do `qwen3:14b` também passa em tudo, dividida em três políticas.

## Correções feitas depois (prompt 1.0.1 e teste em cluster)

Cinco falhas ficaram registradas na primeira entrega. O que foi feito, com os resultados em [`03-execucao.md`](03-execucao.md):

- **A lacuna da porta de entrada e o label do namespace não eram declarados.** O prompt `1.0.1` passou a exigir as duas declarações em Limitações. Resultado: o `gpt-oss:20b` declarou as duas na primeira execução; o `qwen3:14b` só declarou depois de um segundo refino dirigido por mim.
- **Nenhuma política tinha sido aplicada em um cluster.** Foi feito um teste em `kind` (Kubernetes v1.37.0). O manifesto permissivo não bloqueia nada; a v4 de cada modelo passa em 8 de 8 fluxos; a v3 nem chega a ser aplicada, porque o apiserver rejeita `ports` dentro de `to`. Isso também **corrigiu um erro meu**: eu havia escrito que esse defeito deixava a regra sem restringir a porta, e o servidor mostrou que ele a recusa.
- **O validador era só meu.** O `kubectl apply --dry-run=server` virou o item 13: uma checagem que não depende do meu julgamento nem dos modelos. As escolhas que continuam minhas (DNS em TCP, a ausência de porta de entrada) seguem marcadas como recomendadas.
- **O teste em cluster achou o que o validador não via.** A política do `qwen3:14b` com porta de entrada 80 inventada passava 9 de 9 no validador original e bloqueava o Relay e o gateway no cluster. Isso virou o item 14.
- **Ainda sem tratamento:** o `qwen3:14b` só roda com `think` desligado; o tamanho da saída (900 a 2.600 tokens) continua em tensão com o limite de 5 s do CP08.

## Falhas que permanecem

- **O `qwen3:14b` não segue sozinho as regras novas.** Com o prompt `1.0.1`, a primeira saída ainda trouxe `ports` dentro do item `to` e uma porta de entrada inventada. Foram necessários dois refinos dirigidos por defeitos para chegar a 9/9 · 5/5 e 8 de 8 no cluster. O `gpt-oss:20b` acertou tudo na primeira execução, mas foi uma execução só.
- **O teste em cluster é pequeno.** 8 fluxos, pods `busybox`, portas escolhidas por mim, um cluster de um nó com kindnet. Não cobre DNS em TCP, outros CNIs, nem o comportamento de um serviço real.
- **As Limitações do `qwen3:14b` encolhem no refino.** O primeiro refino perdeu as suposições que a primeira saída tinha declarado; o segundo as recuperou porque pedi explicitamente.
- **O `qwen3:14b` só roda sem raciocínio neste prompt:** com `think` ligado, duas chamadas não terminaram.
- **Tamanho da saída.** As respostas têm de 900 a 2.600 tokens. O CP08 exige no máximo 5 s com modelos pequenos (`llama3.2:3b`, `gemma3:4b`); a T004 já mostrou que o `qwen3:14b` e o `gpt-oss:20b` não cumprem esse limite. O ajuste, se for preciso, fica para o CP08.

## Limitações conhecidas

- Uma execução por modelo e por etapa, com `temperature 0`; a variação entre execuções não foi medida.
- O placar do validador mede conformidade estrutural com o padrão, não qualidade de segurança; o teste em cluster cobre 8 fluxos.
- A rodada A e a B foram feitas com o P1; o P2 só passou pelo ciclo de verificação da rodada B, mais a v4 dirigida pelo validador.
- O manifesto e o mapa são fictícios e pequenos; um caso real pede mais regras e mais serviços.
