# Execução

Todas as execuções usam o `promptfoo` 0.125.1 com o provedor local [`providers/ollama-local.js`](../../providers/ollama-local.js) (Ollama, `cost: 0`), `temperature 0`, `num_ctx 8192`, `--no-cache -j 1`. O prompt de cada teste é o `prompt.md` da biblioteca, carregado por [`providers/carregar-prompt.js`](../../providers/carregar-prompt.js), que tira o frontmatter e troca os `{{parâmetros}}`.

## Modelos

| Modelo | Fornecedor | Uso | Motivo |
|--------|-----------|-----|--------|
| `llama3.2:3b` | Meta (via Ollama) | Os três testes | Único modelo local que fica perto do limite de 5 s (T004: 3,2 a 4,0 s no prompt de NetworkPolicy) |
| `gemma3:4b` | Google (via Ollama) | Os três testes | Segundo fornecedor da lista do enunciado; cumpre 5 s na maioria dos casos curtos. **Aquecido antes do `eval`**, porque a primeira chamada de um modelo frio inclui o carregamento (T004: 8,2 s contra 3,7 s) |
| `qwen3:14b` | Alibaba (via Ollama) | Só como comparativo, depois da rodada final | Mede o que a escolha dos modelos pequenos custa em qualidade |

Critérios de escolha: **custo** (zero de API; o assert `cost` passa por construção), **latência** (é o critério que decide aqui: só modelos de 3 a 4 bilhões de parâmetros têm chance de cumprir 5 s), **qualidade** (menor que a dos modelos de 14 e 20 bilhões; este checkpoint mede quanto) e **privacidade** (execução local, dados fictícios).

Aquecimento, antes de cada `eval`: uma chamada curta a `/api/generate` com `keep_alive` de 30 minutos e o mesmo `num_ctx`.

Comando de cada teste, a partir da raiz do repositório:

```bash
promptfoo eval -c devops/<prompt>/promptfooconfig.yaml --no-cache -j 1 -o checkpoints/checkpoint-08/resultados/<prompt>.json
```

Os arquivos brutos estão em [`resultados/`](resultados/): `<prompt>.json` (resultado completo do `promptfoo`) e `<prompt>.console.txt` (a tabela impressa no terminal). Os caminhos absolutos da máquina foram trocados por `<repo>`; nada mais foi alterado. `resultados/rodada-1/` guarda a primeira rodada (antes de mudar o prompt `nota-de-triagem`), e `resultados/comparativo-qwen3-14b/` guarda o comparativo.

## Resultado da rodada final

### `nota-de-triagem`: 5 de 6 execuções passaram

| Caso | Modelo | Resultado | Asserts | Latência | Tokens de saída |
|---|---|---|---|---|---|
| alerta 1 — Sentinel | gemma3:4b | PASSOU | 10 de 10 | 1865 ms | 153 |
| alerta 1 — Sentinel | llama3.2:3b | PASSOU | 10 de 10 | 1247 ms | 132 |
| alerta 2 — Relay | gemma3:4b | REPROVOU | 9 de 10 | 1369 ms | 111 |
| alerta 2 — Relay | llama3.2:3b | PASSOU | 10 de 10 | 1528 ms | 186 |
| alerta 3 — Forge | gemma3:4b | PASSOU | 10 de 10 | 1333 ms | 107 |
| alerta 3 — Forge | llama3.2:3b | PASSOU | 10 de 10 | 1230 ms | 149 |

Asserts que reprovaram:

- alerta 2 — Relay, gemma3:4b: `contains` `@relay-core`. Expected output to contain "@relay-core"

Saídas completas, na ordem da tabela acima:

#### alerta 1 — Sentinel — gemma3:4b (Google, via Ollama) (1865 ms)

````text
ALERTA: Sentinel - autoscaler atingiu o máximo de réplicas (60/60) na sentinel-api
IMPACTO: A sentinel-api está com o autoscaler atingindo o máximo de réplicas, e a profundidade da fila no Relay está crescendo em 2k/min com CPU média de 88%, para o tenant stark-industries.
HIPÓTESE INICIAL: O autoscaler da sentinel-api está sendo acionado devido ao aumento da carga.
AÇÃO IMEDIATA: O plantão deve investigar o aumento da carga na sentinel-api.
ESCALAR PARA: @sentinel-core se a carga persistir por mais de 15 minutos.
````

#### alerta 1 — Sentinel — llama3.2:3b (Meta, via Ollama) (1247 ms)

````text
ALERTA: Sentinel - autoscaler hit max replicas (60/60) on sentinel-api,
IMPACTO: O sistema Sentinel está alcançando o limite máximo de réplicas e não pode ser escalado, afetando a capacidade de processamento da API.
HIPÓTESE INICIAL: A causa provável é que o volume de dados está aumentando rapidamente após a onboarding de uma nova região.
AÇÃO IMEDIATA: Desligar o sistema Sentinel para evitar sobrecarga e garantir a estabilidade do sistema.
ESCALAR PARA: @sentinel-core se CPU avg > 90%
````

#### alerta 2 — Relay — gemma3:4b (Google, via Ollama) (1369 ms)

````text
ALERTA: Relay - Ingest reject rate 6% por 8 minutos, tenant wakanda-systems
IMPACTO: A ingestão de dados está sendo rejeitada para o tenant wakanda-systems.
HIPÓTESE INICIAL: O buffer está saturado após o deploy 02:55.
AÇÃO IMEDIATA: Liberar espaço no buffer do tenant wakanda-systems.
ESCALAR PARA: @data-platform se a saturação persistir por mais 15 minutos.
````

#### alerta 2 — Relay — llama3.2:3b (Meta, via Ollama) (1528 ms)

````text
ALERTA: Relay - ingest reject rate 6% for 8min, tenant wakanda-systems, buffer saturated after deploy 02:55
IMPACTO: O serviço de ingestão está funcionando com uma taxa de rejeição de 6% por 8 minutos, afetando o tenant wakanda-systems, com o buffer saturado após a deploy do horário 02:55.
HIPÓTESE INICIAL: A causa provável é que o buffer de ingestão esteja saturado após a deploy do serviço no horário 02:55.
AÇÃO IMEDIATA: Desligar o serviço de ingestão para evitar o aumento da taxa de rejeição e evitar a saturação do buffer.
ESCALAR PARA: @relay-core se a taxa de rejeição persistir acima de 6% por mais de 15 minutos.
````

#### alerta 3 — Forge — gemma3:4b (Google, via Ollama) (1333 ms)

````text
ALERTA: Forge - Consumer lag de 9 minutos e em ascensão, batch forge-batch-ingest
IMPACTO: Processamento de batch do Forge está atrasado, causando atraso em downstream Sentinel
HIPÓTESE INICIAL: Falha no job anterior do batch forge-batch-ingest
AÇÃO IMEDIATA: Reiniciar o consumer do batch forge-batch-ingest
ESCALAR PARA: @data-platform se o lag persistir por mais 15 minutos
````

#### alerta 3 — Forge — llama3.2:3b (Meta, via Ollama) (1230 ms)

````text
ALERTA: Forge - consumer lag 9min e atraindo, após falha anterior, downstream Sentinel começando a atrasar
IMPACTO: O serviço de ingestão de batch do Forge está atrasando, afetando a capacidade de processamento dos clientes.
HIPÓTESE INICIAL: A falha anterior no processo de ingestão de batch do Forge pode ter causado um atraso no sistema, levando a uma sobrecarga no Sentinel.
AÇÃO IMEDIATA: Desligar o serviço de ingestão de batch do Forge e verificar se há algum problema no sistema.
ESCALAR PARA: @data-platform se o atraso persistir após 30 minutos.
````

### `triagem-de-pods`: 3 de 6 execuções passaram

| Caso | Modelo | Resultado | Asserts | Latência | Tokens de saída |
|---|---|---|---|---|---|
| entrada 1 — pod reiniciando (OOMKilled) | gemma3:4b | REPROVOU | 3 de 4 | 5671 ms | 471 |
| entrada 1 — pod reiniciando (OOMKilled) | llama3.2:3b | PASSOU | 4 de 4 | 2338 ms | 239 |
| entrada 2 — dois pods que não sobem (imagem e CPU) | gemma3:4b | PASSOU | 6 de 6 | 4306 ms | 351 |
| entrada 2 — dois pods que não sobem (imagem e CPU) | llama3.2:3b | PASSOU | 6 de 6 | 2838 ms | 328 |
| entrada 3 — tudo saudável (nenhum pod problemático) | gemma3:4b | REPROVOU | 1 de 5 | 5370 ms | 462 |
| entrada 3 — tudo saudável (nenhum pod problemático) | llama3.2:3b | REPROVOU | 2 de 5 | 3220 ms | 379 |

Asserts que reprovaram:

- entrada 1 — pod reiniciando (OOMKilled), gemma3:4b: `latency` `5000`. Latency 5671ms is greater than threshold 5000ms
- entrada 3 — tudo saudável (nenhum pod problemático), gemma3:4b: `latency` `5000`. Latency 5370ms is greater than threshold 5000ms
- entrada 3 — tudo saudável (nenhum pod problemático), gemma3:4b: `regex` `Pods problemáticos:\**\s*0`. Expected output to match regex "Pods problemáticos:\**\s*0"
- entrada 3 — tudo saudável (nenhum pod problemático), gemma3:4b: `not-contains` `NOME:`. Expected output to not contain "NOME:"
- entrada 3 — tudo saudável (nenhum pod problemático), gemma3:4b: `not-icontains-any` `['CrashLoopBackOff', 'ImagePullBackOff', 'OOMKilled', 'Pendi`. Expected output to not contain one of "CrashLoopBackOff, ImagePullBackOff, OOMKilled, Pending, Pods problemáti
- entrada 3 — tudo saudável (nenhum pod problemático), llama3.2:3b: `regex` `Pods problemáticos:\**\s*0`. Expected output to match regex "Pods problemáticos:\**\s*0"
- entrada 3 — tudo saudável (nenhum pod problemático), llama3.2:3b: `not-contains` `NOME:`. Expected output to not contain "NOME:"
- entrada 3 — tudo saudável (nenhum pod problemático), llama3.2:3b: `not-icontains-any` `['CrashLoopBackOff', 'ImagePullBackOff', 'OOMKilled', 'Pendi`. Expected output to not contain one of "CrashLoopBackOff, ImagePullBackOff, OOMKilled, Pending, Pods problemáti

Saídas completas, na ordem da tabela acima:

#### entrada 1 — pod reiniciando (OOMKilled) — gemma3:4b (Google, via Ollama) (5671 ms)

````text
Pods problemáticos: 1
- NOME: sentinel-api-7d9c8b6f4-h4m2t
- STATUS: Waiting | READY: 0/1 | RESTARTS: 14 (90s ago)
- CAUSA: Falta de memória (OOMKilled) devido a pressão de garbage collection e consumo excessivo de heap.
- EVIDÊNCIA: "Back-off restarting failed container api" (evento) + "out of memory, shutting down process" (log)
- AÇÃO: P1 - Investigar o consumo de memória do pod e ajustar os limites de recursos (memory: 512Mi) ou otimizar o código para reduzir o uso de memória.

- NOME: sentinel-api-7d9c8b6f4-2xk9p
- STATUS: Running | READY: 1/1 | RESTARTS: 0
- CAUSA: Não identificada
- EVIDÊNCIA: Nenhuma evidência de problema.
- AÇÃO: P2 - Monitorar o pod para garantir que ele permaneça em estado Running e Ready.

- NOME: sentinel-worker-5b8f9c8d-jq7rs
- STATUS: Running | READY: 1/1 | RESTARTS: 0
- CAUSA: Não identificada
- EVIDÊNCIA: Nenhuma evidência de problema.
- AÇÃO: P2 - Monitorar o pod para garantir que ele permaneça em estado Running e Ready.

- NOME: sentinel-scheduler-6c4d7f-nn8vx
- STATUS: Running | READY: 1/1 | RESTARTS: 0
- CAUSA: Não identificada
- EVIDÊNCIA: Nenhuma evidência de problema.
- AÇÃO: P2 - Monitorar o pod para garantir que ele permaneça em estado Running e Ready.

**Observações (sem ação imediata):**
- O pod `sentinel-api-7d9c8b6f4-h4m2t` está em estado de CrashLoopBackOff devido a OOMKilled.
````

#### entrada 1 — pod reiniciando (OOMKilled) — llama3.2:3b (Meta, via Ollama) (2338 ms)

````text
Pods problemáticos: 1

[Sentinel-api-7d9c8b6f4-h4m2t]

- NOME: sentinel-api-7d9c8b6f4-h4m2t
- STATUS: CrashLoopBackOff | READY: 0/1 | RESTARTS: 14 (90s ago)
- CAUSA: Falha de memória, causa pelo uso excessivo de memória pelo cache de alertas, que não foi liberado após a saída do processo.
- EVIDÊNCIA: "high GC pressure, heap 498Mi/512Mi" + "out of memory, shutting down process" (log do processo)
- AÇÃO: Reiniciar pod (P1)

[Observações (sem ação imediata):]
- Verificar configurações de cache e alertas para evitar uso excessivo de memória.
- Ajustar limites de memória para o pod.

Próxima ação do plantão:
- Reiniciar pod sentinel-api-7d9c8b6f4-h4m2t (P1)
````

#### entrada 2 — dois pods que não sobem (imagem e CPU) — gemma3:4b (Google, via Ollama) (4306 ms)

````text
Pods problemáticos: 2

- NOME: sentinel-api-7d9c8b6f4-zzp10
  STATUS: Waiting | READY: 0/1 | RESTARTS: 0
  CAUSA: Falha na extração da imagem devido à tag inexistente no registry.
  EVIDÊNCIA: "Failed to pull image \"registry.aegis.io/sentinel-api:2.9.2\": manifest unknown" + "Error: ErrImagePull"
  AÇÃO: P1 - Verificar se a tag da imagem "registry.aegis.io/sentinel-api:2.9.2" existe no registry Aegis.

- NOME: sentinel-ingest-8f7a9c5b-4dkqm
  STATUS: Waiting | READY: 0/1 | RESTARTS: 0
  CAUSA: Falha no agendamento devido à falta de recursos (CPU) nos nós do cluster.
  EVIDÊNCIA: "0/6 nodes are available: 6 Insufficient cpu" + "FailedScheduling"
  AÇÃO: P1 - Analisar a demanda por CPU e ajustar os limites de recursos do pod ou adicionar mais nós ao cluster.

**Observações (sem ação imediata):**
- O pod sentinel-api-7d9c8b6f4-zzp10 está em estado de espera devido à falha na extração da imagem.
- O pod sentinel-ingest-8f7a9c5b-4dkqm está em estado de espera devido à falta de recursos.
````

#### entrada 2 — dois pods que não sobem (imagem e CPU) — llama3.2:3b (Meta, via Ollama) (2838 ms)

````text
Pods problemáticos: 2

1. sentinel-api-7d9c8b6f4-zzp10
   - NOME: sentinel-api-7d9c8b6f4-zzp10
   - STATUS: ImagePullBackOff | READY: 0/1 | RESTARTS: 0
   - CAUSA: tag da imagem não encontrada no registry
   - EVIDÊNCIA: "Failed to pull image 'registry.aegis.io/sentinel-api:2.9.2': manifest unknown" + "Error: ErrImagePull"
   - AÇÃO: Reiniciar pod (P1)

2. sentinel-ingest-8f7a9c5b-4dkqm
   - NOME: sentinel-ingest-8f7a9c5b-4dkqm
   - STATUS: Pending | READY: 0/1 | RESTARTS: 0
   - CAUSA: Insufficient cpu nos nós disponíveis
   - EVIDÊNCIA: "0/6 nodes are available: 6 Insufficient cpu"
   - AÇÃO: Ajustar limites de recursos (P2)

Observações (sem ação imediata):
- Verificar a disponibilidade dos nós e ajustar as configurações de recursos se necessário.

Próxima ação do plantão:
- Reiniciar pod sentinel-api-7d9c8b6f4-zzp10 > Reiniciar pod sentinel-ingest-8f7a9c5b-4dkqm
````

#### entrada 3 — tudo saudável (nenhum pod problemático) — gemma3:4b (Google, via Ollama) (5370 ms)

````text
Pods problemáticos: 1

- NOME: sentinel-worker-5b8f9c8d-jq7rs
  - STATUS: Running | READY: 1/1 | RESTARTS: 1 (3d ago)
  - CAUSA: Restarts frequentes devido a um problema de processamento de alertas.
  - EVIDÊNCIA: "[1 (3d ago)]" (evento de restart) + "[2026-05-13 11:02:31 [INFO] [api] processed 4.2k alerts/min, p99 latency 120ms]" (indicando possível sobrecarga).
  - AÇÃO: P1 - Investigar a causa da alta latência do p99 e da sobrecarga de alertas no sentinel-worker.  Analisar logs do worker para identificar gargalos.

- NOME: sentinel-api-7d9c8b6f4-2xk9p | NOME: sentinel-api-7d9c8b6f4-h4m2t
  - STATUS: Running | READY: 1/1 | RESTARTS: 0
  - CAUSA: Não confirmada
  - EVIDÊNCIA: "[2026-05-13 11:02:31 [INFO] [api] health check OK, 0 errors in the last 5min]" + "[2026-05-13 11:03:31 [INFO] [api] processed 4.2k alerts/min, p99 latency 120ms]"
  - AÇÃO: P2 - Monitorar a saúde e o desempenho desses pods, observando a latência e a carga de alertas.
 
**Observações (sem ação imediata):**
- Os pods sentinel-api-7d9c8b6f4-2xk9p e sentinel-api-7d9c8b6f4-h4m2t estão em estado normal, com health checks OK e latência aceitável.
````

#### entrada 3 — tudo saudável (nenhum pod problemático) — llama3.2:3b (Meta, via Ollama) (3220 ms)

````text
Pods problemáticos: 2

**1. sentinel-api-7d9c8b6f4-h4m2t**

- NOME: sentinel-api-7d9c8b6f4-h4m2t
- STATUS: ImagePullBackOff | READY: 1/1 | RESTARTS: 1 (3d ago)
- CAUSA: tag da imagem não encontrada no registry
- EVIDÊNCIA: [evento de erro] + [linha do log] "2026-05-13 11:03:31 [INFO] [api] health check OK, 0 errors in the last 5min"
- AÇÃO: Reiniciar pod (P1)

**2. sentinel-worker-5b8f9c8d-jq7rs**

- NOME: sentinel-worker-5b8f9c8d-jq7rs
- STATUS: Running | READY: 0/1 | RESTARTS: 1 (3d ago)
- CAUSA: falha no inicialização do worker
- EVIDÊNCIA: [evento de erro] + [linha do log] "2026-05-13 11:02:31 [INFO] [api] health check OK, 0 errors in the last 5min"
- AÇÃO: Investigar recursos e ajustar configurações (P2)

Observações (sem ação imediata):
- Verificar se o problema é específico do worker ou do cluster.

Próxima ação do plantão:
- Reiniciar sentinel-api-7d9c8b6f4-h4m2t > Reiniciar sentinel-worker-5b8f9c8d-jq7rs > Investigar recursos e ajustar configurações.
````

### `networkpolicy-sentinel`: 0 de 2 execuções passaram

| Caso | Modelo | Resultado | Asserts | Latência | Tokens de saída |
|---|---|---|---|---|---|
| manifesto permissivo + padrão Aegis + mapa de serviços | gemma3:4b | REPROVOU | 7 de 9 | 9202 ms | 792 |
| manifesto permissivo + padrão Aegis + mapa de serviços | llama3.2:3b | REPROVOU | 4 de 9 | 5799 ms | 658 |

Asserts que reprovaram:

- manifesto permissivo + padrão Aegis + mapa de serviços, gemma3:4b: `javascript` `const regras = (output.match(/^\s*-\s*(from|to):/gm) || []).`. Custom function returned false
- manifesto permissivo + padrão Aegis + mapa de serviços, gemma3:4b: `latency` `5000`. Latency 9202ms is greater than threshold 5000ms
- manifesto permissivo + padrão Aegis + mapa de serviços, llama3.2:3b: `contains` `kind: NetworkPolicy`. Expected output to contain "kind: NetworkPolicy"
- manifesto permissivo + padrão Aegis + mapa de serviços, llama3.2:3b: `javascript` `const blocos = [...output.matchAll(/policyTypes:([^\n]*(?:\n`. Custom function returned false
- manifesto permissivo + padrão Aegis + mapa de serviços, llama3.2:3b: `not-contains` `- {}`. Expected output to not contain "- {}"
- manifesto permissivo + padrão Aegis + mapa de serviços, llama3.2:3b: `javascript` `const regras = (output.match(/^\s*-\s*(from|to):/gm) || []).`. Custom function returned false
- manifesto permissivo + padrão Aegis + mapa de serviços, llama3.2:3b: `latency` `5000`. Latency 5799ms is greater than threshold 5000ms

Saídas completas, na ordem da tabela acima:

#### manifesto permissivo + padrão Aegis + mapa de serviços — gemma3:4b (Google, via Ollama) (9202 ms)

````text
O que o manifesto libera em excesso
O manifesto atual permite todo o tráfego de entrada e saída para pods no namespace "sentinel-prod" sem restrições. Isso é excessivo, pois não especifica quais serviços externos o Sentinel deve se comunicar, nem impõe um padrão de "default-deny".

Política corrigida
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: sentinel-allow
  namespace: sentinel-prod
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          app: sentinel
    ports:
    - protocol: TCP
      port: 80
  - from:
    - namespaceSelector:
        matchLabels:
          app: relay
    ports:
    - protocol: UDP
      port: 53
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          app: forge
    ports:
    - protocol: TCP
      port: 5432
  - to:
    - namespaceSelector:
        matchLabels:
          app: cerebro
    ports:
    - protocol: TCP
      port: 9200
  - to:
    - namespaceSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
  policyTypes:
  - Ingress
  - Egress
  default-deny:
    namespaceSelector:
      matchLabels:
        app: sentinel
```

Fluxos liberados
- Regra de ingress: Permite tráfego de entrada do namespace "relay-prod" para pods com label "app=sentinel" na porta 80. Vem do padrão "pods do Sentinel só aceitam tráfego de entrada do Relay (consumo de eventos)".
- Regra de ingress: Permite tráfego de entrada do namespace "relay-prod" para pods com label "app=sentinel" na porta 53 (DNS interno). Vem do padrão "pods do Sentinel só aceitam tráfego de entrada do Relay (consumo de eventos)".
- Regra de egress: Permite tráfego de saída para pods com label "app=forge" na porta 5432 (Forge). Vem do padrão "pods do Sentinel só fazem saída para: Forge (warehouse, porta 5432)".
- Regra de egress: Permite tráfego de saída para pods com label "app=cerebro" na porta 9200 (Cerebro). Vem do padrão "pods do Sentinel só fazem saída para: Cerebro (busca, porta 9200)".
- Regra de egress: Permite tráfego de saída para pods com label "k8s-app=kube-dns" na porta 53 (DNS interno). Vem do padrão "pods do Sentinel só fazem saída para: DNS interno".

Limitações e suposições
A política não cobre o tráfego de saída para outros serviços além de Forge, Cerebro e DNS interno. O mapa não especifica quais outros serviços o Sentinel pode acessar, então a política libera todas as portas de saída para qualquer destino. A política não cobre o tráfego de entrada de outros namespaces além de "relay-prod". A política foi criada para o namespace "sentinel-prod", que foi selecionado por kubernetes.io/metadata.name, que não está presente no mapa de serviços.
````

#### manifesto permissivo + padrão Aegis + mapa de serviços — llama3.2:3b (Meta, via Ollama) (5799 ms)

````text
**O que o manifesto libera em excesso**

O manifesto atual permite tráfego de entrada e saída para todos os pods do namespace "sentinel-prod", independentemente do serviço ou porta utilizada. Além disso, não há regras específicas para permitir ou negar tráfego para os serviços específicos do namespace.

**Política corrigida**

```yml
---
networkPolicy:
  - name: sentinel-allow
    namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: sentinel-prod
    ingress:
      - from:
          - podSelector:
              matchLabels:
                app: sentinel
            ports:
              - 0
          - podSelector:
              matchLabels:
                app: relay
            ports:
              - 0
          - podSelector:
              matchLabels:
                app: api-gateway
            ports:
              - 0
      - to:
          - podSelector:
              matchLabels:
                app: forge
            ports:
              - 5432
          - podSelector:
              matchLabels:
                app: cerebro
            ports:
              - 9200
          - podSelector:
              matchLabels:
                k8s-app: kube-dns
            ports:
              - 53
    egress:
      - to:
          - podSelector:
              matchLabels:
                app: sentinel
            ports:
              - 0
          - podSelector:
              matchLabels:
                app: relay
            ports:
              - 0
          - podSelector:
              matchLabels:
                app: api-gateway
            ports:
              - 0
      - to:
          - podSelector:
              matchLabels:
                app: forge
            ports:
              - 5432
          - podSelector:
              matchLabels:
                app: cerebro
            ports:
              - 9200
          - podSelector:
              matchLabels:
                k8s-app: kube-dns
            ports:
              - 53
    defaultAllow: false
```

**Fluxos liberados**

*   Ingress: fluxo legítimo de consumo de eventos e fluxo legítimo de fluxo de API da plataforma.
*   Egress: fluxo legítimo de saída para os serviços Sentinel, Relay, API gateway, Forge, Cerebro e DNS interno.

**Limitações e suposições**

*   O namespace foi selecionado por kubernetes.io/metadata.name, que o mapa não informa.
*   Não há regras específicas para permitir ou negar tráfego para os serviços específicos do namespace.
*   A política default-deny explícita no namespace não é necessária, pois a regra de ingress e egress já seleciona apenas os pods do serviço específico.
*   O campo ports de uma regra fica no mesmo nível de from ou de to, ao lado deles, e nunca dentro de um item da lista from ou to.
*   Não há regra vazia (- {}), from ou to vazio, nem seletor vazio que libere tudo.
````

## Primeira rodada (antes de ajustar o prompt `nota-de-triagem`)

Só o `nota-de-triagem` mudou entre a primeira rodada e a final; os outros dois prompts tiveram o mesmo texto nas duas. Os resultados completos estão em [`resultados/rodada-1/`](resultados/rodada-1/).

| Caso | Modelo | Resultado | Asserts | Latência |
|---|---|---|---|---|
| alerta 1 — Sentinel | gemma3:4b | PASSOU | 10 de 10 | 1531 ms |
| alerta 1 — Sentinel | llama3.2:3b | REPROVOU | 4 de 10 | 1104 ms |
| alerta 2 — Relay | gemma3:4b | REPROVOU | 9 de 10 | 1256 ms |
| alerta 2 — Relay | llama3.2:3b | REPROVOU | 5 de 10 | 985 ms |
| alerta 3 — Forge | gemma3:4b | PASSOU | 10 de 10 | 1212 ms |
| alerta 3 — Forge | llama3.2:3b | REPROVOU | 9 de 10 | 1089 ms |

O `llama3.2:3b` tratou os rótulos do formato como títulos de seção: nos alertas 1 e 2 devolveu o rótulo `ALERTA:` sozinho e as outras linhas sem rótulo, e no alerta 3 usou linhas em branco entre os campos (estourou as 8 linhas). Exemplo da saída do alerta 1:

````text
ALERTA:
Sentinel está atingindo o limite máximo de réplicas (60/60) no serviço sentinel-api.
O sistema Relay está experimentando uma aumento significativo na profundidade da fila (2k/min), além de um uso médio de CPU de 88%.
A causa provável é que o sistema esteja enviando 4 vezes o volume de baseline após a inclusão de uma nova região.
Ação imediata: Desligar o autoscaler no Sentinel e monitorar o sistema Relay para evitar sobrecarga.
Escalar para: @relay-core se o problema persistir após 15 minutos.
````

## Comparativo com o `qwen3:14b` (Alibaba, via Ollama)

Executado depois da rodada final, com os mesmos testes e o provedor trocado, em arquivos de configuração temporários (apagados em seguida). Resultados em [`resultados/comparativo-qwen3-14b/`](resultados/comparativo-qwen3-14b/).

| Prompt | Caso | Resultado | Asserts | Latência |
|---|---|---|---|---|
| nota-de-triagem | alerta 1 — Sentinel | REPROVOU | 9 de 10 | 5128 ms |
| nota-de-triagem | alerta 2 — Relay | PASSOU | 10 de 10 | 4381 ms |
| nota-de-triagem | alerta 3 — Forge | PASSOU | 10 de 10 | 4678 ms |
| triagem-de-pods | entrada 1 — pod reiniciando (OOMKilled) | REPROVOU | 3 de 4 | 9292 ms |
| triagem-de-pods | entrada 2 — dois pods que não sobem (imagem e CPU) | REPROVOU | 5 de 6 | 12896 ms |
| triagem-de-pods | entrada 3 — tudo saudável (nenhum pod problemático) | PASSOU | 5 de 5 | 3379 ms |
| networkpolicy-sentinel | manifesto permissivo + padrão Aegis + mapa de serviços | REPROVOU | 8 de 9 | 38031 ms |
