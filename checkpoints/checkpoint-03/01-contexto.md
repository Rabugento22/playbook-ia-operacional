# Contexto

## O incidente

O Cerebro, o sistema de indexação e busca da Aegis, passou a devolver buscas lentas e resultados incompletos. O plantão (Sam Wilson) levantou três artefatos da mesma janela (cerca de 08h às 10h UTC), cada um de uma fonte diferente. A causa só aparece cruzando os três.

| Artefato | Fonte | Arquivo |
|----------|-------|---------|
| Configuração do cluster Elasticsearch (`cerebro.yaml`) | Repositório de infra | [`artefato-1-cerebro.yaml`](entradas/artefato-1-cerebro.yaml) |
| Métricas das últimas 2 horas, pontos de 30 em 30 minutos | Dashboard do Sentinel | [`artefato-2-metricas.txt`](entradas/artefato-2-metricas.txt) |
| Log do nó `cerebro-node-3` | `kubectl logs` | [`artefato-3-logs.txt`](entradas/artefato-3-logs.txt) |

## Leitura dos artefatos (antes do prompt)

O que os dados sustentam:

- A reindexação agendada às 02:00, que normalmente leva 90 minutos (termina por volta de 03:30), estava em 41% às 10:00, e avançou muito pouco ao longo da janela (38% às 08:02, 40% às 09:20, 41% às 09:58).
- O heap subiu de 61% para 94% e o circuit breaker de memória disparou a 96%; o pool de escrita encheu e passou a rejeitar bulk; as buscas estouraram o timeout de 5 s e devolveram resultado parcial (11 de 12 shards).
- O cache de query caiu de 74% para 29% de acerto: é efeito da pressão de memória, e não causa.

O que os dados **não** sustentam, e o prompt precisa deixar o modelo declarar:

- Por que a reindexação avançou tão devagar.
- Por que a vazão de indexação passou de 4.100 para 9.800 a 12.400 docs/s a partir das 09:00, enquanto a reindexação quase não andava. Parte da carga de escrita pode vir de fora da reindexação.
- O heap já estava em 61% às 08:00, antes do problema aparecer.
- Não há métricas de CPU, disco ou tamanho de segmentos, nem logs de outros nós.

## O que o prompt precisa fazer

Receber o pacote como parâmetro (`{{config}}`, `{{metricas}}`, `{{logs}}`) e levar a IA a raciocinar até a causa-raiz, de modo reutilizável: o time troca só o pacote a cada degradação. O prompt é genérico e não cita o Cerebro, para não induzir a conclusão.

## Decisão de sanitização

O enunciado pede que se decida o que tratar antes de mandar esses dados para um **modelo externo**. Os dados são fictícios, mas foram tratados como produção.

**O que existe nos artefatos e o que fazer:**

| Item | Onde aparece | Decisão para modelo externo |
|------|--------------|-----------------------------|
| Nome do nó (`cerebro-node-3`) | Logs | Mascarar com `NODE-A`; identifica a infraestrutura interna |
| Nome do índice (`logs-2026.05`) | Logs | Mascarar com `INDEX-A`; pode revelar o domínio e o período dos dados dos clientes |
| ID da tarefa de reindexação (`88123`) | Logs | Mascarar com `TASK-1`; identificador interno |
| Valores de métricas, parâmetros da configuração, horários, durações e códigos de erro | Todos | **Manter**: são a evidência do raciocínio; mascará-los destruiria a análise |
| Cabeçalhos e comentários do repositório de infra | Configuração | Manter; não identificam pessoas nem clientes |

Os identificadores são trocados por marcadores estáveis (o mesmo marcador para o mesmo item em todos os artefatos), de modo que a correlação entre eles não se perde.

**O que não está nestes artefatos, mas apareceria em produção** e deve ser procurado antes de enviar: nomes de tenants e de clientes dentro de índices ou queries, endereços IP e hostnames, identificadores de usuário, corpo de queries com dados pessoais, tokens e credenciais em stack traces.

**O que foi feito nas execuções:** as execuções principais usaram dados originais, porque rodam localmente via Ollama e nenhum dado sai da máquina. Para verificar se o mascaramento prejudica a análise, uma execução adicional usou os artefatos com os três identificadores mascarados; o resultado está em [`03-execucao.md`](03-execucao.md) e a conclusão se manteve.
