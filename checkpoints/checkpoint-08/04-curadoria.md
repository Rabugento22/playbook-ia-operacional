# Curadoria

Resultados completos em [`03-execucao.md`](03-execucao.md). Modelos: `llama3.2:3b` (Meta) e `gemma3:4b` (Google), via Ollama, `temperature 0`.

## O que passou

- **`nota-de-triagem`: os três asserts do enunciado passaram nas 6 execuções** (cinco rótulos, handle `@palavra`, no máximo 8 linhas), com latência de 1,2 a 1,9 s, bem dentro de 5 s. Só o assert extra do handle certo falhou uma vez (5 de 6 execuções passaram no total).
- **`triagem-de-pods`, entradas 1 e 2:** o `llama3.2:3b` passou nas duas (2,3 e 2,8 s); o `gemma3:4b` acertou os conteúdos nas duas, e na entrada 2 levou 4,3 s.
- **O assert de custo passou sempre**, porque o provedor local devolve `cost: 0`. Ele não discrimina nada nesta configuração.
- **As execuções são reproduzíveis.** Com `temperature 0`, a segunda rodada deu exatamente os mesmos resultados da primeira nos dois prompts que não mudaram (`triagem-de-pods` e `networkpolicy-sentinel`).

## O que falhou

| Prompt | Caso | Modelo | O que reprovou |
|--------|------|--------|----------------|
| `triagem-de-pods` | entrada 3 (saudável) | os dois | Os modelos inventam pods problemáticos. O `llama3.2:3b` listou dois pods: o `sentinel-api-7d9c8b6f4-h4m2t`, que não está nessa entrada, com `ImagePullBackOff`, e o `sentinel-worker-5b8f9c8d-jq7rs`, que está `Running` e `1/1`, com READY `0/1`. O `gemma3:4b` abriu com "Pods problemáticos: 1" e listou três pods, todos `Running` e `1/1`, entre eles o `sentinel-worker` (por um restart de 3 dias atrás) e o `h4m2t`, que também não está nessa entrada É a falha que o enunciado mais quer pegar, e ela aparece nos dois |
| `triagem-de-pods` | entrada 1 | `gemma3:4b` | Só a latência: 5,7 s (o conteúdo passou). Em uma tentativa anterior, com o mesmo prompt, a mesma chamada levou 4,9 s e passou |
| `triagem-de-pods` | entrada 3 | `gemma3:4b` | Também 5,4 s, além do conteúdo |
| `nota-de-triagem` | alerta 2 (Relay) | `gemma3:4b` | Handle de outro time (`@sentinel-core` em vez de `@relay-core`). Assert extra, não exigido pelo enunciado |
| `networkpolicy-sentinel` | único caso | `llama3.2:3b` | 4 de 9 asserts. Não produziu `kind: NetworkPolicy` (inventou um esquema com `networkPolicy:` e `name:`), sem `policyTypes`, sem comentários e 5,8 s. O assert `- {}` também reprovou, mas por um falso positivo (ver abaixo) |
| `networkpolicy-sentinel` | único caso | `gemma3:4b` | 7 de 9 asserts. O YAML tem `kind`, `policyTypes`, as portas 5432 e 9200 e `app: relay`, mas **nenhum comentário** (a regra mais repetida do prompt) e levou 9,2 s |

## O trade-off que o enunciado antecipa

O enunciado diz que "um modelo mais caro ou mais lento pode reprovar aqui". O comparativo com o `qwen3:14b` (mesmos testes, mesmos asserts) mostra o tamanho da escolha:

| Prompt | `llama3.2:3b` e `gemma3:4b` | `qwen3:14b` |
|--------|-----------------------------|-------------|
| `nota-de-triagem` | 5 de 6 execuções; latência de 1,2 a 1,9 s | 2 de 3; **todos os asserts de conteúdo passaram**, uma reprovação por 5,1 s |
| `triagem-de-pods` | 3 de 6; falha a entrada saudável nos dois | 1 de 3; **todos os asserts de conteúdo passaram**, inclusive a entrada saudável; reprovou em 9,3 e 12,9 s |
| `networkpolicy-sentinel` | 0 de 2; YAML sem comentários ou inválido | 0 de 1; **8 dos 9 asserts passaram**, só a latência reprovou, em 38 s |

Ou seja: os modelos que cabem em 5 s perdem exatamente o que o prompt tem de mais difícil (não inventar problema, seguir o padrão de segurança), e o modelo que acerta o conteúdo não cumpre o limite. A escolha por modelos pequenos foi a que o enunciado e a T004 impuseram (D14), e o custo dela está nos números acima.

## O que foi ajustado

**No prompt (mantido):** `nota-de-triagem` 1.0.1. O formato listava os cinco rótulos sozinhos em linhas separadas, e o `llama3.2:3b` os tratou como títulos de seção (0 de 3 nos asserts do enunciado na primeira rodada). Passar a mostrar cada linha preenchível (`ALERTA: <sistema> - <condição>`) levou o `llama3.2:3b` a 3 de 3. Para o handle, a regra passou a dizer que ele é o do sistema escrito em `ALERTA:`, e os quatro handles foram repetidos na regra. O `gemma3:4b` acertou o handle em 2 de 3 alertas com o prompt original e com o final (e em 1 de 3 nas versões intermediárias), então a mudança não melhorou o handle dele; o erro dele é de escolha do time, e nenhuma redação que tentei o corrigiu. O texto de `checkpoints/checkpoint-02/02-prompt.md` foi atualizado junto.

**No prompt (tentado e desfeito):** em `triagem-de-pods`, uma regra explícita para pod `Running` com READY completo; em `networkpolicy-sentinel`, seções de explicação limitadas a poucas linhas. Nenhuma das duas mudou o resultado (os modelos continuaram a inventar pods e a escrever de 719 a 793 tokens), então os textos voltaram ao que eram. Registrar isso importa: as falhas restantes não são de redação do prompt, são do tamanho do modelo.

**Nos testes:** o assert do handle correto em `nota-de-triagem`. Os três testes foram escritos uma vez; nenhum assert foi afrouxado para fazer uma execução passar.

## Limitações dos testes

- **O assert `- {}` do enunciado reprova por falso positivo.** O `llama3.2:3b` escreveu em prosa "Não há regra vazia (- {})", citando a regra do prompt, e o `not-contains` reprovou. O texto do enunciado pede exatamente esse assert (a saída não contém `- {}`), então foi mantido; um teste mais preciso olharia só o bloco YAML.
- **O assert de comentário é aproximado.** Conta um `#` por regra de `from`/`to` na saída inteira. Passaria com um comentário fora do lugar e com `#` em um título Markdown.
- **O `policyTypes` e o `kind` são conferidos por texto, não por YAML.** O YAML do `gemma3:4b` pode estar bem formado e não foi validado. O validador do CP06 (e o `kubectl apply --dry-run=server`) fazem isso melhor, e ficam como ideia para o CP10.
- **O assert de custo não discrimina**, pelo motivo acima.
- **Uma execução por modelo e por caso**, com `temperature 0`. A latência varia entre chamadas (o `gemma3:4b` fez 4,9 s e 5,7 s no mesmo caso); um teste de latência de verdade pediria `--repeat`.
- **Os testes de `triagem-de-pods` e de `networkpolicy-sentinel` cobrem o conteúdo exigido, não a qualidade das ações recomendadas.** Isso fica para o julgamento do CP09.

## Para o CP10

Dois dos três testes têm falhas estruturais com os modelos que o limite de 5 s permite. Se o pipeline barrar o PR a qualquer reprovação, ele barra sempre. Antes do CP10 é preciso decidir, com o Rubens, como o portão trata isso: (a) manter o limite do enunciado e registrar as reprovações como esperadas, (b) trocar o modelo do portão por um que acerte o conteúdo e aceitar a latência alta, ou (c) separar os asserts de conteúdo dos de latência em dois jobs. A decisão fica para a T050.
