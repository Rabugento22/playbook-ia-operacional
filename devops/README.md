# DevOps

Prompts de operação para a plataforma da Aegis: triagem de pods, notas de triagem de alertas, análise de causa-raiz, decisões de arquitetura de filas, migração de pipelines de dados e endurecimento de políticas de rede.

Cada prompt vive em sua pasta, nomeada pelo resultado, com `prompt.md` (frontmatter e texto, com `{{placeholders}}`), `README.md` (o mesmo frontmatter e a documentação) e, a partir do CP08, `promptfooconfig.yaml`. O caminho de construção de cada prompt está em [`checkpoints/`](../checkpoints/).

## Prompts

- [triagem-de-pods](./triagem-de-pods/) — Analisa um snapshot do cluster (kubectl get, describe e logs) e devolve os pods problemáticos com causa provável, evidência e ação para o plantão.
- [nota-de-triagem](./nota-de-triagem/) — Transforma um alerta cru do Sentinel em uma nota de triagem padronizada de cinco rótulos para o plantonista do turno seguinte.
- [causa-raiz](./causa-raiz/) — Cruza configuração, métricas e logs de um sistema degradado e devolve linha do tempo, cadeia causal, causa-raiz com confiança, limitações dos dados e ações proporcionais.
- [decisao-backpressure](./decisao-backpressure/) — Compara pelo menos três caminhos para segurar o excesso de carga em um barramento de eventos, pesando prós e contras contra as restrições do cenário antes de recomendar.
- [migracao-forge-diagnostico](./migracao-forge-diagnostico/) — Diagnostica o estado atual de um pipeline em lote e lista as garantias, os dependentes, os pontos frágeis, os invariantes e as lacunas, como entrada do plano de migração para eventos.
- [migracao-forge-plano](./migracao-forge-plano/) — A partir do cenário e do diagnóstico, monta um plano de migração em fases incrementais e reversíveis, com a troca de fonte de cada dependente, como entrada do roteiro executável.
- [migracao-forge-execucao](./migracao-forge-execucao/) — Detalha cada fase do plano em passos, verificações, critérios de go/no-go e rollback com gatilho e limite de tempo, e confere o resultado contra as garantias do cenário.
