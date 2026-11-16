# Contexto

## Problema

Toda vez que o Sentinel dispara um alerta, o plantonista abre uma nota de triagem, e cada um escreve do seu jeito. Isso atrapalha quem assume o turno seguinte. A Carol Danvers (Head of Product) quer um padrão único de nota.

## Duas listas que não se misturam

O enunciado traz duas listas diferentes, e o prompt trata cada uma de forma distinta:

| Lista | Arquivo | Papel |
|-------|---------|-------|
| Formato de saída: três notas prontas que o time considera boas | [`entradas/formato-de-saida-exemplos.txt`](entradas/formato-de-saida-exemplos.txt) | Referência de formato. **Não é entrada do prompt.** |
| Entradas: três alertas crus | `alerta-1-sentinel.txt`, `alerta-2-relay.txt`, `alerta-3-forge.txt` | Os três (e só estes) casos de teste |

## O que o prompt precisa fazer

Receber um alerta cru por parâmetro (`{{alerta_cru}}`) e produzir a nota padronizada, com os cinco rótulos `ALERTA:`, `IMPACTO:`, `HIPÓTESE INICIAL:`, `AÇÃO IMEDIATA:` e `ESCALAR PARA:`. O enunciado deixa uma decisão de método: dá para ensinar o padrão ao modelo de mais de uma forma, e a escolha deve ser justificada.

## Decisões de escopo

- **Um único parâmetro**, `{{alerta_cru}}`, o texto do alerta sem edição.
- **Cinco linhas exatas**, sem linhas em branco, markdown ou cercas de código. O limite de 8 linhas do CP08 fica folgado.
- **Handle `@palavra`** na linha de escalonamento, com condição de tempo. O padrão `ESCALAR PARA:.*@\w+` é o que o CP08 verifica.
- **Fidelidade ao alerta:** números, tenants, horários e nomes de serviços são copiados do alerta; nada é inventado.
- **Privacidade:** os dados são fictícios e a execução foi local. Em produção, os alertas trazem nomes de tenants e de serviços internos; avalie o que mascarar antes de enviar a um modelo externo.
