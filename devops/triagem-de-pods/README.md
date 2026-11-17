---
nome: Triagem de pods
descricao: Analisa um snapshot do cluster (kubectl get, describe e logs) e devolve os pods problemáticos com causa provável, evidência e ação para o plantão.
versao: 1.0.0
tags: [kubernetes, sre, triagem, plantao]
inputs:
  - nome: snapshot
    descricao: Saída colada de kubectl get pods, kubectl describe pod e kubectl logs, coletada por quem tem acesso ao cluster
---

# Triagem de pods

## Objetivo

Dar ao plantão da SRE uma triagem rápida e confiável da saúde dos pods do cluster onde o Sentinel está hospedado. O prompt recebe o snapshot já coletado em `{{snapshot}}` e devolve a lista de pods problemáticos, com causa provável, evidência literal e ação, ou informa que não há nada problemático.

## Quando usar

- Alerta de pod reiniciando, que não sobe ou preso em `Pending`.
- Passagem de turno: conferir a saúde geral do namespace.
- Não substitui a investigação: o prompt só enxerga o que está no snapshot.

## Como usar

1. Colete o snapshot: `kubectl get pods -n <ns>`, `kubectl describe pod <pod> -n <ns>` e `kubectl logs <pod> -n <ns> [--previous]`.
2. Copie o texto de [`prompt.md`](prompt.md) (a partir do fim do frontmatter) e troque `{{snapshot}}` pelo que coletou.
3. Execute em um modelo de sua escolha.

## Exemplo

Entrada: [`entradas/entrada-1-pod-reiniciando.txt`](../../checkpoints/checkpoint-01/entradas/entrada-1-pod-reiniciando.txt). Saída real do `qwen3:14b` (via Ollama):

```text
Pods problemáticos: 1  
- NOME: sentinel-api-7d9c8b6f4-h4m2t  
- STATUS: CrashLoopBackOff | READY: 0/1 | RESTARTS: 14 (90s ago)  
- CAUSA: O pod está sendo reiniciado repetidamente devido a falhas por falta de memória (OOMKilled), provavelmente devido a limites de memória insuficientes para o workload.  
- EVIDÊNCIA: "OOMKilled" no estado do container + "high GC pressure, heap 498Mi/512Mi" nos logs  
- AÇÃO: P1 - Ajustar os limites de memória no deployment do sentinel-api para evitar OOMKilled, por exemplo, aumentar o limite de memória para 1Gi ou mais.  

**Próxima ação do plantão:**  
- P1 > (nenhuma outra ação prioritária)
```

As três execuções completas, nos dois modelos, estão em [`03-execucao.md`](../../checkpoints/checkpoint-01/03-execucao.md).

## Limitações

- O `gpt-oss:20b` incluiu a linha "Próxima ação do plantão" no snapshot saudável, que o prompt pede só quando há pods problemáticos.
- Uma execução por modelo e entrada; não se mediu a variação entre execuções.
- Sem log ou evento no snapshot, a causa deve sair como "Causa não confirmada"; esse caminho não foi exercitado nas três entradas.
- Em produção, o snapshot traz nomes internos (pods, registry, nós); avalie o que mascarar antes de enviar a um modelo externo.
- **Teste com modelos pequenos (CP08):** `llama3.2:3b` e `gemma3:4b` identificam os pods das entradas 1 e 2, mas inventam pods problemáticos no snapshot saudável (entrada 3). Para o limite de 5 s do CP08 só cabem modelos pequenos, então este prompt deve ser executado em um modelo maior (`qwen3:14b` passou nos asserts de conteúdo das três entradas, em 3 a 13 s). Detalhes em [`checkpoint-08`](../../checkpoints/checkpoint-08/).

## Documentação do caminho

O caminho até este prompt (contexto, evolução v1 → v3, execuções e curadoria) está em [`checkpoints/checkpoint-01/`](../../checkpoints/checkpoint-01/).
