# DevOps

Prompts de operação para a plataforma da Aegis: triagem de pods, notas de triagem de alertas, análise de causa-raiz, decisões de arquitetura de filas, migração de pipelines de dados e endurecimento de políticas de rede.

Cada prompt vive em sua pasta, nomeada pelo resultado, com `prompt.md` (frontmatter e texto, com `{{placeholders}}`), `README.md` (o mesmo frontmatter e a documentação) e, a partir do CP08, `promptfooconfig.yaml`. O caminho de construção de cada prompt está em [`checkpoints/`](../checkpoints/).

## Prompts

- [triagem-de-pods](./triagem-de-pods/) — Analisa um snapshot do cluster (kubectl get, describe e logs) e devolve os pods problemáticos com causa provável, evidência e ação para o plantão.
- [nota-de-triagem](./nota-de-triagem/) — Transforma um alerta cru do Sentinel em uma nota de triagem padronizada de cinco rótulos para o plantonista do turno seguinte.
