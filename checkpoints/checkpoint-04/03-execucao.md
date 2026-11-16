# Execução

## Modelos usados (todos via Ollama, local)

| Modelo | Fornecedor | Parâmetros | Motivo |
|---|---|---|---|
| `qwen3:14b` | Alibaba | `temperature 0`, `num_ctx 12288`, raciocínio ligado | Modelo mais capaz que cabe na GPU; o raciocínio ligado ajuda numa comparação com trade-offs; custo zero de API; nenhum dado sai da máquina. Foi também o modelo do meta-prompting |
| `gpt-oss:20b` | OpenAI | `temperature 0`, `num_ctx 12288`, raciocínio `medium` | Segunda família de modelo, com raciocínio próprio, para comparar a análise entre fornecedores |

Critérios de escolha: **custo** (zero de API nos dois; o custo real é energia e hardware), **latência** (sem limite neste checkpoint; a análise levou cerca de 2 minutos), **qualidade** (os dois mais capazes disponíveis localmente) e **privacidade** (execução local; o cenário é fictício).

Entrada: [`entradas/cenario-relay.txt`](entradas/cenario-relay.txt), colado em `{{cenario}}`. Saídas copiadas dos arquivos de execução, sem edição.

## Execução da versão final (v4)

### `qwen3:14b` (123 s, 2.482 tokens de saída)

````text
Reformulação do cenário  
**Fatos**:  
- Relay (barramento de eventos) tem throughput sustentado de 180k msgs/s e pico observado de 320k msgs/s por 25 minutos.  
- Retenção atual é de 4h.  
- Consumidores são Forge (ingestão) e Sentinel (alerting em tempo real).  

**Restrições rígidas**:  
- Alerting do Sentinel não pode atrasar mais que 60s (SLA com cliente).  
- Perda de mensagens (telemetry) é inaceitável (viola SLA de observabilidade).  

**Restrições flexíveis**:  
- Ingestão do Forge pode atrasar até 15min sem violar SLA.  
- Orçamento de infra do trimestre está 8% acima do previsto.  

**Condições a verificar**:  
- Capacidade máxima do sistema (não informada no cenário).  
- Possibilidade de escalar recursos (servidores, armazenamento, etc.) sem exceder orçamento.  

---

Contas  
1. **Volume de carga no pico**:  
   320k msgs/s × 25 min × 60 s/min = **480.000.000 mensagens**.  

2. **Carga observada vs. capacidade**:  
   - Throughput sustentado: 180k msgs/s.  
   - Capacidade máxima do sistema: **incógnita** (não informada).  
   - Suposição: Se a capacidade for menor que 320k msgs/s, o sistema não pode processar o pico sem backlog ou perda.  

3. **Atraso acumulado**:  
   - Se o sistema processar 180k msgs/s durante o pico, o tempo para processar 480M mensagens seria:  
     480.000.000 / 180.000 = **2.666,67 segundos** ≈ **44,44 minutos**.  
   - Isso excede o SLA de Sentinel (60s) e o tolerável para Forge (15min).  

4. **Retenção atual (4h)**:  
   - Capacidade de armazenamento não informada.  
   - Se a retenção for insuficiente para armazenar o backlog, mensagens podem ser perdidas.  

---

Caminhos propostos  
**Caminho 1: Rate limiting com priorização de mensagens**  
- **Como funciona**:  
  - Limitar a taxa de entrada para 180k msgs/s, priorizando mensagens do Sentinel.  
  - Mensagens do Forge são enfileiradas ou descartadas se o sistema estiver sobrecarregado.  
- **Comportamento diante de restrições rígidas**:  
  - **Sentinel**: Atende SLA (prioridade garantida).  
  - **Perda de mensagens**: Não atende (mensagens do Forge podem ser descartadas).  
- **Prós**:  
  - Garante SLA para Sentinel.  
  - Simples de implementar.  
- **Contras**:  
  - Risco de perda de mensagens (viola restrição rígida).  
  - Não resolve o problema de capacidade.  
- **Riscos**:  
  - Perda de telemetry (viola SLA de observabilidade).  
- **Custo e complexidade**:  
  - Baixo custo (não requer infra adicional).  
- **Condições para funcionar**:  
  - Capacidade do sistema ≥ 180k msgs/s.  

**Caminho 2: Escalamento horizontal com buffer de retenção aumentada**  
- **Como funciona**:  
  - Escalar recursos (servidores, armazenamento) para aumentar a capacidade do sistema.  
  - Aumentar a retenção para 4h + tempo de processamento do backlog.  
- **Comportamento diante de restrições rígidas**:  
  - **Sentinel**: Atende SLA (capacidade aumentada).  
  - **Perda de mensagens**: Atende (retenção maior evita perda).  
- **Prós**:  
  - Resolve capacidade e retenção.  
  - Garante SLA para Sentinel.  
- **Contras**:  
  - Alto custo (orçamento já excedido).  
  - Complexidade de escalar recursos.  
- **Riscos**:  
  - Orçamento excedido (8% acima do previsto).  
- **Custo e complexidade**:  
  - Alto custo e complexidade.  
- **Condições para funcionar**:  
  - Orçamento disponível para escalar recursos.  

**Caminho 3: Buffer de filas com backpressure dinâmico**  
- **Como funciona**:  
  - Usar filas com capacidade limitada para cada consumidor.  
  - Quando o buffer estiver cheio, o Relay interrompe a produção de mensagens (backpressure).  
- **Comportamento diante de restrições rígidas**:  
  - **Sentinel**: Atende SLA (buffer prioritário).  
  - **Perda de mensagens**: Atende (backpressure evita sobrecarga).  
- **Prós**:  
  - Evita perda de mensagens.  
  - Não exige escala de recursos.  
- **Contras**:  
  - Atraso potencial para Forge (até 15min tolerável).  
  - Complexidade de implementar backpressure.  
- **Riscos**:  
  - Atraso para Forge pode atingir limite tolerável.  
- **Custo e complexidade**:  
  - Médio (requer ajustes no sistema).  
- **Condições para funcionar**:  
  - Capacidade do sistema ≥ 180k msgs/s.  

---

Tabela comparativa  
| Critério | Caminho 1 | Caminho 2 | Caminho 3 |  
|--------|----------|----------|----------|  
| SLA Sentinel | atende | atende | atende |  
| Perda de mensagens | não atende | atende | atende |  
| Orçamento | atende | não atende | atende |  
| Atraso para Forge | parcial (descartado) | atende | parcial (até 15min) |  
| Complexidade | baixa | alta | média |  
| Custo | baixo | alto | médio |  
| Risco de perda | alto | baixo | baixo |  

---

Recomendação  
**Caminho 3 (buffer de filas com backpressure dinâmico)** é recomendado, combinado com **Caminho 1 (rate limiting com priorização)** para garantir SLA do Sentinel.  

**Justificativa**:  
- **Caminho 3** evita perda de mensagens (violação rígida) e não exige escala de recursos (orçamento).  
- **Caminho 1** prioriza Sentinel, garantindo SLA mesmo com backpressure.  
- **Caminho 2** é descartado devido ao orçamento excedido.  

**Sacrifícios conscientes**:  
- Atraso potencial para Forge (até 15min tolerável).  
- Complexidade de implementar backpressure.  

**Comportamento no pico**:  
- O buffer de filas interrompe a produção de mensagens, evitando sobrecarga.  
- Sentinel processa mensagens com prioridade, mantendo atraso ≤ 60s.  
- Forge pode ter atraso de até 15min, dentro do tolerável.  

---

Limites e validação  
**Limites da análise**:  
- Capacidade máxima do sistema não informada (necessário validar com testes de carga).  
- Orçamento excedido (8%) não permite escala (Caminho 2).  
- Suposição de que backpressure dinâmico não exige escala de recursos (validar com testes).  

**Validação**:  
- **Teste de carga**: Simular pico de 320k msgs/s por 25min para verificar atraso e perda.  
- **Métricas**: Monitorar atraso de Sentinel (≤60s) e Forge (≤15min).  
- **Experimento**: Implementar backpressure e rate limiting, medindo impacto no SLA.  

**Condições para revisão**:  
- Se a capacidade do sistema for menor que 180k msgs/s (Caminho 3 falha).  
- Se o orçamento permitir escala (Caminho 2 torna-se viável).  
- Se a perda de mensagens for detectada (Caminho 3 falha).
````

### `gpt-oss:20b` (97 s, 4.232 tokens de saída)

````text
Reformulação do cenário  
Fatos:  
- Barramento de eventos (Relay) tem throughput sustentado de 180 000 msgs/s.  
- Pico observado: 320 000 msgs/s durante 25 min (1 500 s).  
- Retenção atual: 4 h (14 400 s).  
- Consumidores: Forge (ingestão) e Sentinel (alerting em tempo real).  
- SLA: Sentinel não pode atrasar mais que 60 s; Forge pode atrasar até 15 min.  
- Orçamento de infra do trimestre já 8 % acima do previsto.  
- Perda de mensagens sob pico é inaceitável (Steve Rogers).  

Restrições rígidas (violá‑las causa dano contratual ou perda irreversível):  
1. Não pode haver perda de mensagens.  
2. SLA do Sentinel (≤ 60 s de atraso).  
3. SLA do Forge (≤ 15 min de atraso).  
4. Orçamento não pode exceder 8 % acima do previsto.  

Restrições flexíveis (podem ser negociadas ou ajustadas):  
1. Retenção de 4 h (pode ser aumentada se necessário).  
2. Capacidade máxima do barramento (não fornecida; pode ser aumentada).  

Contas  
Excesso de carga: 320 000 – 180 000 = 140 000 msgs/s.  
Duração do pico: 25 min = 1 500 s.  
Volume acumulado no pico: 140 000 msgs/s × 1 500 s = 210 000 000 msgs (210 M).  

Tempo necessário para recuperar atraso (supondo processamento contínuo a 180 000 msgs/s):  
210 M / 180 000 ≈ 1 166,7 s ≈ 19,4 min.  

Para atender o SLA do Sentinel (≤ 60 s) a taxa de processamento deve ser:  
210 M / 60 s = 3 500 000 msgs/s (3,5 M).  

Para atender o SLA do Forge (≤ 15 min) a taxa de processamento deve ser:  
210 M / 900 s = 233 333 msgs/s (≈ 233 k).  

Comparação com a capacidade atual (180 k msgs/s):  
- Forge: necessidade de +53 k msgs/s (≈ 29 % aumento).  
- Sentinel: necessidade de +3 320 k msgs/s (≈ 1 844 % aumento).  

Caminhos propostos  
1. **Escalonamento horizontal do barramento (adicionar nós de broker)**  
   - Como funciona: aumenta a capacidade total do Relay, permitindo maior throughput.  
   - Rígidas: não causa perda de mensagens; SLA do Forge pode ser atendido se a capacidade for aumentada para ≥ 233 k; SLA do Sentinel não atendido a menos que a capacidade seja aumentada para ≥ 3,5 M, o que pode exceder orçamento.  
   - Prós: simples de implementar em infra já existente; escalabilidade linear.  
   - Contras: custo de hardware/serviço; pode não atingir SLA do Sentinel sem investimento muito alto.  
   - Riscos: aumento de latência de rede entre nós; complexidade de balanceamento.  
   - Custo/complexidade: qualitativamente alto; requer nova infra.  
   - Necessita: capacidade de adicionar nós; orçamento disponível.  

2. **Backpressure nos produtores (pausar ou throttling)**  
   - Como funciona: produtores detectam alta carga no Relay e reduzem a taxa de envio (ou pausam) para manter o throughput em torno de 180 k msgs/s.  
   - Rígidas: não causa perda de mensagens (produtores mantêm buffer local); SLA do Sentinel e Forge atendidos pois backlog não se forma.  
   - Prós: evita necessidade de aumentar infra; mantém SLA.  
   - Contras: requer suporte de backpressure nos clientes; pode aumentar latência de produção; complexidade de coordenação.  
   - Riscos: produtores podem não suportar pausa; risco de deadlock se não houver mecanismo de retomada.  
   - Custo/complexidade: moderado; depende da implementação de backpressure nos produtores.  
   - Necessita: produtores com API de pause/throttle; monitoramento de carga.  

3. **Isolamento de tráfego crítico (topic/queue dedicado para Sentinel)**  
   - Como funciona: eventos de alerta são enviados a um tópico separado com recursos dedicados (partições, brokers). Sentinel consome desse tópico com prioridade alta. Forge consome do tópico principal.  
   - Rígidas: não causa perda de mensagens (mensagens duplicadas ou roteadas); SLA do Sentinel atendido se a capacidade dedicada for ≥ 3,5 M; SLA do Forge atendido se a capacidade principal for ≥ 233 k.  
   - Prós: garante SLA do Sentinel independentemente do tráfego de Forge; flexibilidade de alocação de recursos.  
   - Contras: aumento de complexidade de roteamento; custo adicional de infra dedicada; risco de inconsistência se roteamento falhar.  
   - Riscos: falha no roteador pode causar perda de mensagens; necessidade de manter idempotência.  
   - Custo/complexidade: alto; requer nova infra e lógica de roteamento.  
   - Necessita: capacidade de criar tópicos/partições adicionais; lógica de roteamento.  

4. **Compressão e batch de mensagens**  
   - Como funciona: agrupa mensagens em lotes e comprime antes de enviar ao Relay, reduzindo taxa de bytes.  
   - Rígidas: não causa perda de mensagens; SLA pode ser atendido se a taxa de bytes for reduzida o suficiente.  
   - Prós: reduz uso de banda; pode melhorar throughput.  
   - Contras: aumenta CPU e latência de processamento; complexidade de descompressão nos consumidores.  
   - Riscos: aumento de latência pode violar SLA do Sentinel.  
   - Custo/complexidade: moderado; depende de capacidade de CPU.  
   - Necessita: suporte de compressão nos produtores e consumidores.  

Tabela comparativa  
| Critério | Caminho 1 (Escalonamento) | Caminho 2 (Backpressure) | Caminho 3 (Isolamento) | Caminho 4 (Compressão) |
|---|---|---|---|---|
| Não perda de mensagens | atende | atende | atende | atende |
| SLA Sentinel (≤ 60 s) | parcial (exige 3,5 M) | atende | atende | parcial (latência) |
| SLA Forge (≤ 15 min) | atende (≥ 233 k) | atende | atende | atende |
| Orçamento 8 % acima | não atende (alto custo) | atende | parcial (custo extra) | atende |
| Retenção 4 h | atende | atende | atende | atende |
| Complexidade de infra | alta | moderada | alta | moderada |
| Risco de falha | moderado | moderado | alto | moderado |

Recomendação  
Recomendo a combinação **Backpressure nos produtores (Caminho 2) + Isolamento de tráfego crítico (Caminho 3)**.  

Justificativa:  
- Backpressure evita a formação de backlog, garantindo que o throughput permaneça em torno de 180 k msgs/s, atendendo os SLAs de Forge e Sentinel sem necessidade de aumentar a capacidade do Relay.  
- O isolamento de tráfego crítico cria um caminho dedicado para os eventos de alerta, permitindo que o Sentinel consuma a taxa necessária (≥ 3,5 M msgs/s) sem depender da capacidade compartilhada.  
- Essa combinação mantém a infra dentro do orçamento (o isolamento pode ser feito em poucos nós adicionais, mantendo o custo abaixo de 8 % acima do previsto).  
- A perda de mensagens é evitada porque os produtores mantêm buffer local e o roteamento garante duplicação segura.  
- No pico de 25 min, os produtores reduzirão a taxa de envio, evitando backlog de 210 M msgs. O Sentinel, com seu tópico dedicado, processará as mensagens de alerta em tempo real (≤ 60 s) graças à capacidade alocada. Forge, com seu tópico principal, pode tolerar atraso de até 15 min, pois o backlog será pequeno (≤ 233 k msgs/s).  

Limites e validação  
- O cenário não informa a capacidade máxima atual do Relay; a recomendação assume que a infra pode ser escalada em poucos nós para o isolamento.  
- Suposições: produtores suportam pause/throttle; roteador de eventos pode duplicar mensagens sem perda; capacidade dedicada pode ser provisionada dentro do orçamento.  
- Para validar, execute um teste de carga controlado simulando 320 k msgs/s por 25 min, com backpressure habilitado e tópico isolado para Sentinel; monitore latência de alerta e atraso de Forge.  
- Métricas: atraso médio de Sentinel, atraso médio de Forge, taxa de mensagens processadas, uso de CPU/banda, custo de infra.  
- Revisão: se o orçamento exceder 8 % ou se os produtores não suportarem backpressure, reavalie para escalonamento horizontal. Se a latência de alerta ainda exceder 60 s, aumente a capacidade dedicada do tópico Sentinel.
````
