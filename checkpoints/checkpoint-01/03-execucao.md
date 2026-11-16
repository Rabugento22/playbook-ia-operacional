# Execução

## Modelos usados (todos via Ollama, local)

| Modelo | Fornecedor | Parâmetros | Motivo |
|---|---|---|---|
| `qwen3:14b` | Alibaba | `temperature 0`, `num_ctx 8192`, raciocínio desligado | Melhor qualidade que cabe na GPU local; custo zero de API; nada sai da máquina. Foi também o modelo do meta-prompting. |
| `gpt-oss:20b` | OpenAI | `temperature 0`, `num_ctx 8192`, raciocínio `low` | Segunda família de modelo, para comparar a robustez do prompt entre fornecedores. Aceita o raciocínio `low`, e não o desligamento total. |

Critérios de escolha: **custo** (zero de API nos dois; o custo real é energia e hardware), **latência** (sem limite neste checkpoint; o limite de 5 s só vale a partir do CP08, onde serão usados modelos menores), **qualidade** (os dois são os mais capazes disponíveis localmente) e **privacidade** (execução local; nenhum dado enviado a terceiros).

Hardware: RTX 3060 de 12 GB. Tempos abaixo são de parede e incluem a geração inteira.

## Execução da versão final (v3)

### Entrada 1 — pod reiniciando

**`qwen3:14b` (8,4 s)**

````text
Pods problemáticos: 1  
- NOME: sentinel-api-7d9c8b6f4-h4m2t  
- STATUS: CrashLoopBackOff | READY: 0/1 | RESTARTS: 14 (90s ago)  
- CAUSA: O pod está sendo reiniciado repetidamente devido a falhas por falta de memória (OOMKilled), provavelmente devido a limites de memória insuficientes para o workload.  
- EVIDÊNCIA: "OOMKilled" no estado do container + "high GC pressure, heap 498Mi/512Mi" nos logs  
- AÇÃO: P1 - Ajustar os limites de memória no deployment do sentinel-api para evitar OOMKilled, por exemplo, aumentar o limite de memória para 1Gi ou mais.  

**Próxima ação do plantão:**  
- P1 > (nenhuma outra ação prioritária)
````

**`gpt-oss:20b` (13,0 s)**

````text
Pods problemáticos: 1  

- NOME: sentinel-api-7d9c8b6f4-h4m2t  
- STATUS: CrashLoopBackOff | READY: 0/1 | RESTARTS: 14 (90s ago)  
- CAUSA: OOMKilled devido ao limite de memória de 512Mi excedido pelo consumo de heap (~498Mi) durante a execução.  
- EVIDÊNCIA:  
  - "Reason: OOMKilled" (describe)  
  - "heap 498Mi/512Mi" (logs)  
- AÇÃO:  
  - P1: Aumentar o limite de memória para 1Gi ou ajustar o consumo de heap do aplicativo.  
  - P2: Se o aumento não for viável, revisar o código para reduzir uso de memória ou habilitar GC mais agressivo.  

**Próxima ação do plantão:**  
- P1 > P2  
````

### Entrada 2 — pods que não sobem

**`qwen3:14b` (15,6 s)**

````text
Pods problemáticos: 2  
- NOME: sentinel-api-7d9c8b6f4-zzp10  
  STATUS: ImagePullBackOff | READY: 0/1 | RESTARTS: 0  
  CAUSA: A imagem especificada ("registry.aegis.io/sentinel-api:2.9.2") não está disponível no registry, provavelmente devido a uma tag incorreta ou ausência da imagem.  
  EVIDÊNCIA: "Failed to pull image "registry.aegis.io/sentinel-api:2.9.2": manifest unknown" + "Error: ErrImagePull"  
  AÇÃO: P1 - Verificar a existência da imagem no registry e corrigir a tag ou imagem no Deployment  

- NOME: sentinel-ingest-8f7a9c5b-4dkqm  
  STATUS: Pending | READY: 0/1 | RESTARTS: 0  
  CAUSA: O pod não pode ser agendado devido à falta de recursos (CPU), pois nenhum nó tem capacidade suficiente para atender à requisição de 2 CPUs.  
  EVIDÊNCIA: "0/6 nodes are available: 6 Insufficient cpu" + "Requests: cpu: 2"  
  AÇÃO: P2 - Aumentar a capacidade de CPU dos nós ou reduzir a requisição de CPU no pod  

**Próxima ação do plantão:**  
- P1 > P2
````

**`gpt-oss:20b` (18,6 s)**

````text
Pods problemáticos: 2  

- **NOME:** sentinel-api-7d9c8b6f4-zzp10  
  - **STATUS:** ImagePullBackOff | **READY:** 0/1 | **RESTARTS:** 0  
  - **CAUSA:** A imagem `registry.aegis.io/sentinel-api:2.9.2` não existe no registry (manifest desconhecido).  
  - **EVIDÊNCIA:**  
    - `"Failed to pull image \"registry.aegis.io/sentinel-api:2.9.2\": manifest unknown"` (Event)  
    - `"Error: ErrImagePull"` (Event)  
  - **AÇÃO:** P1 – Verificar se a tag `2.9.2` foi publicada no registry; se não, publicar a imagem correta ou atualizar o Deployment para uma tag existente.  

- **NOME:** sentinel-ingest-8f7a9c5b-4dkqm  
  - **STATUS:** Pending | **READY:** 0/1 | **RESTARTS:** 0  
  - **CAUSA:** Falta de CPU nos nós; o pod solicita 2 CPUs, mas nenhum nó tem capacidade suficiente.  
  - **EVIDÊNCIA:**  
    - `"0/6 nodes are available: 6 Insufficient cpu"` (Event)  
    - `Requests: cpu: 2` (Describe)  
  - **AÇÃO:** P2 – Avaliar se a requisição de CPU pode ser reduzida ou se é necessário adicionar nós com mais recursos; alternativamente, ajustar o scheduler ou usar tolerâncias/affinity para alocar em nós com CPU livre.  

**Próxima ação do plantão:**  
1. P1 – Corrigir a imagem do `sentinel-api`.  
2. P2 – Resolver a falta de CPU para `sentinel-ingest`.
````

### Entrada 3 — tudo saudável

**`qwen3:14b` (6,9 s)**

````text
Pods problemáticos: 0  
**Observações (sem ação imediata):**  
- Todos os pods estão em estado `Running` com `READY` completo  
- Não há reinícios recentes ou crescentes  
- Logs dos pods indicam operação normal e sem erros reportados
````

**`gpt-oss:20b` (10,8 s)**

````text
Pods problemáticos: 0  

**Observações (sem ação imediata):**  
- Todos os pods listados estão em estado `Running` com `READY` completo e sem reinicializações recentes.  
- Logs do pod `sentinel-api-7d9c8b6f4-2xk9p` mostram operações normais e sem erros.  

**Próxima ação do plantão:**  
- Monitorar continuamente o cluster; nenhuma intervenção imediata necessária.
````

## Execuções das versões anteriores (resumo)

Só o `qwen3:14b`, mesmos parâmetros. Saída real da v1 na Entrada 3, que mostrou o falso positivo:

````text
Pods problemáticos: 1  
- **sentinel-worker-5b8f9c8d-jq7rs**  
  - **STATUS**: Running  
  - **READY**: 1/1  
  - **RESTARTS**: 1 (3d ago)  
  - **Causa provável**: O pod teve um reinício no passado, mas está atualmente em estado estável. Não há evidências de falhas recentes.  
  - **Evidência**: "1 (3d ago)" indica um reinício antigo, mas sem novos eventos ou logs de erro recentes.  
  - **Ação recomendada**: Monitorar o pod para garantir que não haja recorrências de falhas. Se o reinício for isolado e sem impacto, não há ação imediata necessária.  

Observações informativas de baixo risco:  
- Os demais pods estão em estado `Running` com `READY` completo e sem reinícios recentes.  
- Não há evidências de falhas críticas no cluster no momento.
````

Saída real da v2 na Entrada 2 (causa ainda repetindo o status):

````text
Pods problemáticos: 2  
- NOME: sentinel-api-7d9c8b6f4-zzp10  
  STATUS: ImagePullBackOff | READY: 0/1 | RESTARTS: 0  
  CAUSA: Falha ao puxar a imagem do repositório  
  EVIDÊNCIA: "Failed to pull image \"registry.aegis.io/sentinel-api:2.9.2\": manifest unknown"  
  AÇÃO: P1 - Verificar se a imagem existe no repositório e se as credenciais de pull estão configuradas corretamente  

- NOME: sentinel-ingest-8f7a9c5b-4dkqm  
  STATUS: Pending | READY: 0/1 | RESTARTS: 0  
  CAUSA: Falta de recursos (CPU) no cluster para agendar o pod  
  EVIDÊNCIA: "0/6 nodes are available: 6 Insufficient cpu"  
  AÇÃO: P1 - Revisar limites de recursos ou escalar o cluster para acomodar o pod
````
