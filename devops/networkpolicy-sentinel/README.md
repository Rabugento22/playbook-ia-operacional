---
nome: Endurecimento de NetworkPolicy
descricao: Recebe um manifesto de NetworkPolicy permissivo, o padrão de segurança e o mapa de serviços, e devolve a política corrigida com default-deny explícito, seletores só do mapa e comentário em cada regra.
versao: 1.0.1
tags: [kubernetes, seguranca, networkpolicy, endurecimento]
inputs:
  - nome: manifesto
    descricao: Manifesto de NetworkPolicy permissivo que foi barrado pela revisão de segurança
  - nome: padrao
    descricao: Regras de segurança da empresa que a política corrigida precisa seguir
  - nome: mapa
    descricao: Como cada serviço é identificado no cluster (namespace, label de pod e porta)
---

# Endurecimento de NetworkPolicy

## Objetivo

Transformar uma NetworkPolicy permissiva (um allow-all disfarçado) em uma política endurecida que segue o padrão de segurança da empresa. O prompt recebe o manifesto em `{{manifesto}}`, o padrão em `{{padrao}}` e o mapa de serviços em `{{mapa}}`, e devolve o YAML corrigido com default-deny explícito, seletores que vêm só do mapa e comentário em cada regra, além das limitações e das suposições feitas.

## Quando usar

- Antes de subir uma NetworkPolicy para um namespace de produto crítico.
- Quando existe um padrão escrito de rede e um mapa de como cada serviço é identificado no cluster.
- **Sempre seguido de verificação:** a saída é um ponto de partida, não um artefato aprovado.

## Como usar

1. Cole o manifesto a corrigir, as regras do padrão e o mapa de serviços (namespace, label e porta de cada serviço).
2. Copie o texto de [`prompt.md`](prompt.md) (depois do frontmatter) e troque `{{manifesto}}`, `{{padrao}}` e `{{mapa}}`.
3. **Valide o YAML antes de aplicar:** confira a indentação de `ports`, `from` e `to`, o default-deny e as suposições declaradas. Nos testes, os dois modelos erraram a posição de `ports` e a verificação feita pelo próprio modelo não percebeu. Use uma checagem determinística (por exemplo, `kubectl apply --dry-run=server` e os asserts do CP08) e, se possível, um cluster de teste.

## Exemplo

Entradas: [`manifesto-permissivo.yaml`](../../checkpoints/checkpoint-06/entradas/manifesto-permissivo.yaml), [`padrao-aegis.txt`](../../checkpoints/checkpoint-06/entradas/padrao-aegis.txt) e [`mapa-de-servicos.txt`](../../checkpoints/checkpoint-06/entradas/mapa-de-servicos.txt). Trecho da versão final (v4) do `gpt-oss:20b` (via Ollama), depois do ciclo de verificação e refino:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: sentinel-default-deny
  namespace: sentinel-prod
spec:
  podSelector: {}          # seleciona todos os pods do namespace
  policyTypes:
    - Ingress
    - Egress
# default-deny explícita no namespace


  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: forge-prod
          podSelector:
            matchLabels:
              app: forge
      ports:
        - protocol: TCP
          port: 5432
      # libera saída do Sentinel para Forge
```

As iterações completas (v1 até v4) dos dois modelos estão em [`03-execucao.md`](../../checkpoints/checkpoint-06/03-execucao.md).

## Limitações

- **A primeira saída tem defeitos.** Nos dois modelos, a v1 saiu com `ports` fora do lugar (o kube-apiserver rejeita esse manifesto) e o `qwen3:14b` ainda gerou um item `- ports:` solto.
- **Verificação pelo mesmo modelo não basta.** Os modelos aprovaram políticas defeituosas e apontaram defeitos que não existiam; a correção veio de um validador determinístico.
- O mapa não informa o label do namespace nem a porta de entrada; o prompt `1.0.1` manda declarar as duas lacunas. O `gpt-oss:20b` declarou na primeira execução; o `qwen3:14b` só depois de refino dirigido.
- As versões finais foram aplicadas em um cluster `kind` (8 fluxos testados, em `checkpoints/checkpoint-06/teste-cluster/`); isso não substitui um teste no seu CNI.
- Uma execução por modelo; a variação entre execuções não foi medida.
- **Teste com modelos pequenos (CP08):** `llama3.2:3b` e `gemma3:4b` não produzem uma política utilizável (o primeiro inventa o esquema do YAML; o segundo omite os comentários) e levam de 5,8 a 9,2 s. O `qwen3:14b` passa nos asserts de conteúdo, em 38 s. Use um modelo de 14 bilhões de parâmetros ou mais e valide o YAML antes de aplicar. Detalhes em [`checkpoint-08`](../../checkpoints/checkpoint-08/).

## Documentação do caminho

Contexto, evolução do prompt, execuções e curadoria estão em [`checkpoints/checkpoint-06/`](../../checkpoints/checkpoint-06/).
