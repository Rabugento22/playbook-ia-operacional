# Curadoria

Em andamento. Esta versão cobre só a T050 (testes dos prompts restantes). A estratégia de gate e a justificativa estendida do pipeline entram na T055.

## O que os testes dos prompts de saída aberta mostram

- **Só dá para verificar a forma e alguns fatos.** Títulos, formato proibido, nomes de dependentes, a janela de madrugada e as contas do pico são verificáveis por regra. A qualidade do raciocínio (a cadeia causal do plano, a proporção das ações) não é, e fica sem cobertura até existir um juiz para cada prompt.
- **O ponto forte:** os testes pegam defeitos reais já conhecidos, sem juiz. O erro de conta do `decisao-backpressure` (480 milhões no lugar de 210 milhões) e a ordem das seções da cadeia do Forge são detectados por regra, e o teste da janela de madrugada protege a correção do CP05.
- **O ponto fraco:** todos os quatro reprovam hoje, no mesmo assert (asteriscos), e o `decisao-backpressure` reprova também nas contas. Um build que barra tudo não informa nada. É o ponto central da T055: o gate precisa distinguir *uma regressão nova* de *um defeito conhecido*.

## Para a T055 (gate)

Opções que estes resultados tornam concretas, a comparar na justificativa estendida:

1. **Falhar em qualquer assert.** Simples, mas hoje reprova 6 dos 8 prompts (quatro pelos asteriscos, dois por latência ou conteúdo no CP08) e não deixa passar nenhum PR.
2. **Falhar só quando o resultado piora em relação à versão anterior** (por exemplo, um assert que passava na `main` e passa a falhar no PR). É o que o enunciado descreve (\"regride em relação à versão anterior\") e deixa os defeitos conhecidos fora do portão, ao custo de guardar o resultado de referência.
3. **Separar os asserts em duas classes:** os que bloqueiam (formato estrutural, regressões já corrigidas) e os que só avisam (asteriscos, latência dos modelos grandes). Exige decidir, assert por assert, em que classe ele cai.
