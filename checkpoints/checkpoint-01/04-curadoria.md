# Curadoria

## Framework escolhido

**R-I-S-E** (Role, Input, Steps, Expectation), o framework do curso indicado para operações, troubleshooting e incidentes. No prompt: o papel é o engenheiro de SRE; o input é o snapshot delimitado por `<snapshot>`; os passos são os critérios de pod problemático, o cruzamento de fontes e a ação do plantão; a expectativa é o formato de saída fixo. Foi a escolha porque a tarefa é um procedimento de diagnóstico com resultado verificável, e não geração de artefato nem transformação.

## O que foi refinado

1. **v1 → v2:** o defeito mais grave foi o falso positivo da Entrada 3, que contradizia o próprio texto. A correção foi uma definição fechada de pod problemático (restart antigo e estável em pod Running não conta) e o formato de saída fixo, sem cerca de código.
2. **v2 → v3:** a causa só repetia o STATUS e o cruzamento com os logs não acontecia. A correção exigiu causa com mecanismo, evidência de pelo menos duas fontes, ação específica e a regra de que N seja igual ao número de pods listados.

Cada correção veio de uma falha observada na execução, não de suposição.

## Resultado

Com a v3, os dois modelos identificaram o pod `sentinel-api-7d9c8b6f4-h4m2t` (OOMKilled), os dois pods da Entrada 2 (tag `2.9.2` inexistente; falta de CPU) e deram `Pods problemáticos: 0` na Entrada 3, sem tratar o `sentinel-worker-5b8f9c8d-jq7rs` como falha.

## Limitações conhecidas

- O `gpt-oss:20b` incluiu a linha `Próxima ação do plantão` na Entrada 3 (N = 0), embora o prompt a peça só quando N ≥ 1. O `qwen3:14b` obedeceu. Não afeta o diagnóstico; fica como ponto a observar nos testes do CP08.
- O `qwen3:14b` repetiu "P1 > (nenhuma outra ação prioritária)" na Entrada 1, uma linha de pouco valor.
- Houve uma execução por modelo e entrada, com `temperature 0`. Não se mediu a variação entre execuções.
- O prompt só avalia o que está no snapshot: se faltar log ou evento, deve dizer "Causa não confirmada", mas esse caminho não foi exercitado nas três entradas.
- O enunciado não trouxe um gabarito; a avaliação foi feita lendo cada saída contra as evidências do próprio snapshot.
