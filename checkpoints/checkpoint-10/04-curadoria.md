# Curadoria

Em andamento. Cobre a T050 (testes dos prompts restantes) e o desenho provisório do gate da T051. A justificativa estendida, comparando alternativas em cada decisão, entra na T055.

## O que os testes dos prompts de saída aberta mostram

- **Só dá para verificar a forma e alguns fatos.** Títulos, formato proibido, nomes de dependentes, a janela de madrugada e as contas do pico são verificáveis por regra. A qualidade do raciocínio (a cadeia causal do plano, a proporção das ações) não é, e fica sem cobertura até existir um juiz para cada prompt.
- **O ponto forte:** os testes pegam defeitos reais já conhecidos, sem juiz. O erro de conta do `decisao-backpressure` (480 milhões no lugar de 210 milhões) e a ordem das seções da cadeia do Forge são detectados por regra, e o teste da janela de madrugada protege a correção do CP05.
- **O ponto fraco:** todos os quatro reprovam hoje, no mesmo assert (asteriscos), e o `decisao-backpressure` reprova também nas contas. Um build que barra tudo não informa nada. É o ponto central da T055: o gate precisa distinguir *uma regressão nova* de *um defeito conhecido*.

## Para a T055 (gate)

Opções que estes resultados tornam concretas, a comparar na justificativa estendida:

1. **Falhar em qualquer assert.** Simples, mas hoje reprova 6 dos 8 prompts (quatro pelos asteriscos, dois por latência ou conteúdo no CP08) e não deixa passar nenhum PR.
2. **Falhar só quando o resultado piora em relação à versão anterior** (por exemplo, um assert que passava na `main` e passa a falhar no PR). É o que o enunciado descreve (\"regride em relação à versão anterior\") e deixa os defeitos conhecidos fora do portão, ao custo de guardar o resultado de referência.
3. **Separar os asserts em duas classes:** os que bloqueiam (formato estrutural, regressões já corrigidas) e os que só avisam (asteriscos, latência dos modelos grandes). Exige decidir, assert por assert, em que classe ele cai.
## Desenho do gate adotado na T051 (provisório)

O pipeline usa a opção 2: **falha só quando um assert que passava passa a falhar** em relação à linha de base. Escolhi porque os resultados mostram que seis dos oito prompts já reprovam em algum assert por defeitos conhecidos do modelo (asteriscos, latência, contas), e um gate que barra qualquer reprovação barraria todo pull request. O gate sozinho não diz que os prompts estão bons; diz que a mudança não piorou. A comparação com as outras opções (falhar em qualquer assert; separar asserts que bloqueiam dos que avisam), o custo por PR, a escolha de rodar só o que mudou contra a suíte inteira, o limiar do juiz e a guarda das chaves entram na T055.

Duas decisões já tomadas no código, que a T055 deve justificar:

- **Juiz com uma nova tentativa:** se o juiz do `causa-raiz` reprova, a suíte roda esse prompt mais uma vez e só falha se repetir. Custa cerca de 3,5 minutos a mais quando há reprovação, e reduz o risco de barrar por flutuação do juiz (as duas execuções do CP09 deram notas diferentes em seis de oito amostras).
- **Linha de base no repositório:** `.github/baseline/` é versionada e atualizada à mão depois de uma mudança aceita. Evita rodar a versão anterior de cada prompt a cada PR (dobraria o tempo), ao custo de a linha de base poder ficar defasada se alguém esquecer de atualizá-la.

