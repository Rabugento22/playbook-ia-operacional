# Contexto

## Problema

O time de SRE precisa de uma triagem rápida e confiável da saúde dos pods no cluster do Sentinel, que qualquer plantonista possa rodar. Hoje o pedido é feito de forma solta ("olha esses pods aí"), o que dá resultado irregular. O prompt do playbook recebe o snapshot já coletado: não busca nada no cluster (sem agente, sem tool).

## O que o prompt precisa fazer

1. Apontar os pods em estado problemático.
2. Chegar à causa provável de cada um cruzando STATUS, eventos (`describe`) e logs, sem só repetir o STATUS.
3. Recomendar a próxima ação do plantão.
4. Devolver uma saída legível, e não um dump.
5. Reconhecer quando não há nada problemático (Entrada 3).

## Decisões de escopo

- **Um único parâmetro**, `{{snapshot}}`, que reúne os três comandos. O namespace já aparece no próprio snapshot.
- **Campo de contagem explícito** (`Pods problemáticos: N`), para a saída ser verificável por teste automático nos checkpoints seguintes.
- **Nomes de pods preservados** na saída, sem mascaramento: o teste do CP08 exige citar `sentinel-api-7d9c8b6f4-h4m2t`.
- **Pod com restart antigo e estável não é problemático.** A Entrada 3 contém `sentinel-worker-5b8f9c8d-jq7rs` com `1 (3d ago)`, e o prompt deve tratá-lo como observação, não como falha.
- **Privacidade:** os dados são fictícios e a execução foi local, então nenhum dado saiu da máquina. Em produção, o snapshot traz nomes internos de pods, de registry e de nós; antes de enviar a um modelo externo, o plantonista deve avaliar o que mascarar.

## Entradas

Os três snapshots estão em [`entradas/`](entradas/): pod reiniciando (OOMKilled), pods que não sobem (ImagePullBackOff e Pending) e tudo saudável.
