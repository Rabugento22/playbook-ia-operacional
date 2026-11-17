# Contexto

## O problema

A Natasha Romanoff barrou um manifesto de NetworkPolicy que ia subir para o namespace do Sentinel: permissivo demais, e um erro ali expõe o produto core. Antes de virar item do playbook, um artefato crítico como esse precisa passar por verificação e refino, e não pode sair na primeira tentativa.

O manifesto barrado, em [`entradas/manifesto-permissivo.yaml`](entradas/manifesto-permissivo.yaml):

````yaml
# manifesto barrado pela revisão de segurança — permissivo demais
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: sentinel-allow
  namespace: sentinel-prod
spec:
  podSelector: {}          # aplica a todos os pods do namespace
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - {}                   # libera QUALQUER origem
  egress:
    - {}                   # libera QUALQUER destino
````

O `podSelector: {}` pega todos os pods do namespace, e as regras `- {}` liberam qualquer entrada e qualquer saída: é um allow-all disfarçado de política.

## O padrão da Aegis

Em [`entradas/padrao-aegis.txt`](entradas/padrao-aegis.txt):

````text
NetworkPolicy para o namespace "sentinel-prod":
- pods do Sentinel só aceitam tráfego de entrada do Relay (consumo de
  eventos) e do gateway de API da plataforma
- pods do Sentinel só fazem saída para: Forge (warehouse, porta 5432),
  Cerebro (busca, porta 9200) e DNS interno
- nada de "allow all" em ingress ou egress
- política default-deny explícita no namespace
- toda regra precisa de comentário dizendo qual fluxo legítimo ela libera
````

## O mapa de serviços

Para escrever os seletores sem inventar labels. Em [`entradas/mapa-de-servicos.txt`](entradas/mapa-de-servicos.txt):

````text
Sentinel     → namespace sentinel-prod, pods com label app=sentinel
Relay        → namespace relay-prod,    pods com label app=relay
API gateway  → namespace edge,          pods com label app=api-gateway
Forge        → namespace forge-prod,    pods com label app=forge,   porta 5432 (Postgres do warehouse)
Cerebro      → namespace cerebro-prod,  pods com label app=cerebro, porta 9200 (Elasticsearch)
DNS interno  → namespace kube-system,   pods com label k8s-app=kube-dns, porta 53
````

## O que o mapa e o padrão não dizem

Estes três pontos explicam a maior parte dos erros dos modelos:

- **Como o namespace é identificado.** O mapa diz o nome do namespace (`relay-prod`), não o label que o seleciona. Um `namespaceSelector` precisa de um label. Os modelos tendem a inventar `name: relay-prod`, que não existe por padrão. O Kubernetes aplica a todo namespace o label `kubernetes.io/metadata.name`, mas usá-lo é uma suposição que a política deve declarar.
- **A porta de entrada do Sentinel.** O mapa traz a porta de Forge, Cerebro e DNS, mas nenhuma porta para o tráfego que chega ao Sentinel. Uma regra de ingress sem `ports` libera todas as portas dessa origem. A política deve registrar essa lacuna, e não inventar uma porta.
- **O protocolo do DNS.** O mapa só diz "porta 53". O DNS usa UDP e cai para TCP em respostas grandes; liberar só UDP é um risco de falha em produção. O padrão não pede nada além do DNS interno, então liberar também TCP é uma decisão minha, registrada no prompt e tratada como item **recomendado** na verificação.

## O que o enunciado pede

Um prompt parametrizável que receba o manifesto permissivo, o padrão e o mapa, e devolva a política corrigida; criado por meta-prompting; e um processo de verificação e refino em que a IA critica a própria saída, levanta as perguntas que um revisor de segurança faria e melhora a versão a cada rodada. As iterações (v1, o que a verificação apontou, e como a v2 e a v3 responderam) fazem parte da entrega.

## Desenho do processo

1. O gerador produz a v1 a partir das três entradas.
2. O verificador (o mesmo modelo) critica a versão, levanta perguntas e emite defeitos e um parecer.
3. O refinador corrige a versão a partir dos defeitos.
4. Repete-se até a v3. Um validador determinístico meu confere cada versão contra o padrão e serve de contraprova para o que o modelo afirma.

Esse validador existe porque a verificação feita pela mesma IA que escreveu a política tende a aprová-la; a [curadoria](04-curadoria.md) mostra que isso aconteceu.

## Privacidade

O manifesto e o mapa são fictícios. Em um caso real, namespaces e nomes de serviços são informação interna: avalie o que mascarar antes de enviar a um modelo externo. As execuções foram locais.
