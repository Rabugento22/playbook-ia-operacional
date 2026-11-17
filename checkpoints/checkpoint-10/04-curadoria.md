# Curadoria

Em andamento: falta a evidência de execução no GitHub (T053 e T054). Cobre a T050 (testes dos prompts restantes) e a estratégia de gate com a justificativa estendida (T055).

## O que os testes dos prompts de saída aberta mostram

- **Só dá para verificar a forma e alguns fatos.** Títulos, formato proibido, nomes de dependentes, a janela de madrugada e as contas do pico são verificáveis por regra. A qualidade do raciocínio (a cadeia causal do plano, a proporção das ações) não é, e fica sem cobertura até existir um juiz para cada prompt.
- **O ponto forte:** os testes pegam defeitos reais já conhecidos, sem juiz. O erro de conta do `decisao-backpressure` (480 milhões no lugar de 210 milhões) e a ordem das seções da cadeia do Forge são detectados por regra, e o teste da janela de madrugada protege a correção do CP05.
- **O ponto fraco:** todos os quatro reprovam hoje, no mesmo assert (asteriscos), e o `decisao-backpressure` reprova também nas contas. Um build que barra tudo não informa nada. É o ponto central da T055: o gate precisa distinguir *uma regressão nova* de *um defeito conhecido*.

## O ponto de partida da estratégia de gate

Opções que estes resultados tornam concretas (a justificativa completa está na seção seguinte):

1. **Falhar em qualquer assert.** Simples, mas hoje 7 dos 8 prompts têm ao menos um assert reprovando (quatro pelos asteriscos e três no CP08, por latência ou conteúdo) e não deixa passar nenhum PR.
2. **Falhar só quando o resultado piora em relação à versão anterior** (por exemplo, um assert que passava na `main` e passa a falhar no PR). É o que o enunciado descreve (\"regride em relação à versão anterior\") e deixa os defeitos conhecidos fora do portão, ao custo de guardar o resultado de referência.
3. **Separar os asserts em duas classes:** os que bloqueiam (formato estrutural, regressões já corrigidas) e os que só avisam (asteriscos, latência dos modelos grandes). Exige decidir, assert por assert, em que classe ele cai.
## Estratégia de gate e justificativa estendida

**Resumo do gate adotado.** O pipeline roda a suíte nos prompts afetados pela mudança e **falha quando um assert que passava na linha de base passa a falhar**, ou quando o juiz de qualidade do `causa-raiz`, que aprovava, passa a reprovar duas vezes seguidas. Defeitos que já existiam não bloqueiam; aparecem no relatório. Tudo roda num runner nesta máquina, com modelos do Ollama, sem chave de API.

**Números que sustentam as escolhas** (medidos nas execuções reais dos checkpoints 08, 09 e 10):

| Prompt | Tempo de uma execução | Tokens (geração e juiz) |
|---|---|---|
| `nota-de-triagem` | 9 s | cerca de 4,8 mil |
| `triagem-de-pods` | 24 s | cerca de 9,9 mil |
| `networkpolicy-sentinel` | 15 s | cerca de 3,6 mil |
| `causa-raiz` (gera e julga) | cerca de 3,5 min | cerca de 15 mil |
| `decisao-backpressure` | 2 min 9 s | cerca de 3,3 mil |
| `migracao-forge-diagnostico` | 1 min 24 s | cerca de 2,6 mil |
| `migracao-forge-plano` | 2 min 44 s | cerca de 4,9 mil |
| `migracao-forge-execucao` | 3 min 22 s | cerca de 6,9 mil |
| **Suíte inteira** | **cerca de 15 minutos** | **cerca de 51 mil** |

### Decisão 1: o que faz o build falhar

| Alternativa | O que se ganha | O que se perde |
|---|---|---|
| A. Falhar em qualquer assert reprovado | Simples de explicar; nenhum defeito passa | Hoje 7 dos 8 prompts têm ao menos um assert reprovando por defeitos conhecidos do modelo (asteriscos, contas, latência, handle): o build ficaria vermelho em todo PR e ninguém olharia mais para ele |
| B. Só os asserts determinísticos bloqueiam; o juiz só informa | Nenhuma flutuação do juiz derruba um build; barato de explicar | O `causa-raiz`, o único prompt com juiz, ficaria sem gate de qualidade, e o enunciado do CP09 diz que o juiz é o gate |
| **C. Só regressão em relação à linha de base, para os asserts e para o juiz (adotada)** | Barra o que a mudança piorou e deixa passar o que já era conhecido; a linha de base é uma lista objetiva do que existe hoje | Defeitos conhecidos ficam escondidos do bloqueio (aparecem só no relatório); exige manter a linha de base atualizada |
| D. Nota mínima absoluta do juiz em todo build | Regra única e fácil: total ≥ 6 | O juiz varia até 2 pontos entre execuções do mesmo texto (CP09): um prompt na faixa de 5 a 7 pontos seria aprovado ou reprovado por sorte |

**Escolhi C.** Os defeitos conhecidos (como os asteriscos) continuam documentados nos checkpoints e no relatório do PR; o gate responde à pergunta do enunciado, "uma mudança piora um prompt em relação à versão anterior?". O custo da escolha é real: um prompt já ruim não será barrado por continuar ruim, e uma linha de base mal atualizada vira um valor errado aceito.

### Decisão 2: o limiar do juiz diante de um juiz que não é determinístico

O CP09 mediu: duas execuções do mesmo juiz deram notas diferentes em seis de oito amostras, com diferença de até 2 pontos.

| Alternativa | O que se ganha | O que se perde |
|---|---|---|
| A. Uma execução, corte fixo (total ≥ 6, nenhum critério 0) | Rápido (cerca de 3,5 min) | Reprova ou aprova por flutuação, sobretudo perto do corte |
| B. Sempre duas execuções e exigir as duas | Reduz a aprovação por sorte | Dobra o tempo e o consumo de modelo em todo build com o `causa-raiz`; ainda reprova por azar de uma das duas |
| C. Tolerância de 1 ponto no total | Absorve flutuação pequena | Aceita regressões reais de 1 ponto; o corte deixa de ser o do enunciado |
| **D. Uma execução e, só se reprovar, uma nova tentativa; falha se reprovar nas duas (adotada)** | Custo extra só quando há suspeita (cerca de 3,5 min); uma reprovação por azar raramente se repete | Uma aprovação por sorte passa; duas execuções seguidas de azar derrubam um build bom |

**Escolhi D.** A assimetria é deliberada: o gate custa mais quando há motivo para desconfiar. O enunciado também pergunta qual limiar; a regra de cada execução continua sendo a do enunciado (soma ≥ 6, nenhum critério 0), e o que a linha de base compara é aprovado ou reprovado, e não a nota exata.

### Decisão 3: a suíte inteira ou só os prompts alterados

| Alternativa | O que se ganha | O que se perde |
|---|---|---|
| A. Suíte inteira a cada mudança (cerca de 15 min, 51 mil tokens) | Pega regressão em qualquer prompt, inclusive por efeito colateral | Quinze minutos de runner para corrigir um erro de digitação no README de um prompt; fila no único runner |
| **B. Só os prompts afetados, e todos quando a mudança é na infraestrutura (adotada)** | De 10 s a 4 min na maioria dos PRs; menos consumo | Efeito colateral entre prompts que o seletor não conhece passa sem teste; o seletor precisa conhecer a cadeia do Forge (feito: mudar o diagnóstico testa também o plano e o roteiro) |
| C. Suíte inteira só na `main` e à noite; o PR testa o que mudou | Pega a deriva do modelo e o efeito colateral | Exige um agendamento num runner que é iniciado à mão pelo mantenedor, então a execução noturna ficaria na fila sem ninguém para rodá-la |

**Escolhi B**, com o seletor testando tudo quando muda `providers/`, `.github/` ou `validate.sh`. O risco que sobra é uma atualização do Ollama ou de um modelo que muda o comportamento sem que nenhum arquivo mude; a alternativa C cobriria isso e fica como evolução, quando houver um runner permanente.

### Decisão 4: o custo de chamar modelo a cada PR

| Alternativa | O que se ganha | O que se perde |
|---|---|---|
| A. API paga (OpenAI, Anthropic, Google) | Modelos fortes e rápidos; sem máquina própria | Custo por PR (cerca de 51 mil tokens por suíte inteira, mais a repetição do juiz) que cresce com o número de prompts; chave de API para guardar; contraria a decisão de não ter custo (D1) |
| B. API de camada gratuita | Sem custo; roda no runner da própria hospedagem | Limite de requisições por minuto e por dia, que uma suíte de 15 minutos e um juiz que repete esgotam; os modelos mudam sem aviso e a linha de base envelhece |
| **C. Ollama local no runner self-hosted (adotada)** | Custo de API zero; os dados dos cenários nunca saem da máquina; modelos fixos | Depende de uma máquina ligada e de um runner iniciado à mão; o tempo é o de uma GPU de 12 GB; só roda quando o mantenedor liga o runner |

Complementos que reduzem o consumo: o seletor de prompts (Decisão 3), o cancelamento de runs antigos do mesmo ramo (`concurrency`) e a nova tentativa só na reprovação do juiz. O cache do `promptfoo` ficou **desligado**: com ele, a segunda execução devolveria a resposta guardada e esconderia justamente a flutuação que se quer ver.

### Decisão 5: onde ficam as chaves dos provedores

| Alternativa | O que se ganha | O que se perde |
|---|---|---|
| A. Secrets do repositório ("Settings, Secrets") para uma API | É o caminho padrão e simples do GitHub | A chave fica acessível a qualquer workflow do repositório; um PR malicioso pode tentar exfiltrá-la |
| B. Secrets de um *environment* com aprovação manual | Uma pessoa libera cada uso da chave | Cada PR espera aprovação; excessivo para um projeto de um mantenedor |
| **C. Nenhuma chave (adotada)** | Nada a vazar ou rotacionar | Só funciona enquanto os modelos forem locais; o workflow usa apenas o `GITHUB_TOKEN` automático |

O `GITHUB_TOKEN` tem permissões mínimas (`contents: read`, `pull-requests: write`, só para comentar). Se uma API gratuita entrar depois (decisão PR12), a chave vai em *secrets*, é lida por `env` somente no passo que a usa, e o job continua restrito a PRs do próprio repositório.

### Decisão 6: onde o pipeline roda

| Alternativa | O que se ganha | O que se perde |
|---|---|---|
| A. Runner hospedado pelo GitHub com API gratuita | Sem máquina ligada; qualquer colaborador dispara | Depende do limite da API (Decisão 4); os modelos são os da API |
| **B. Runner self-hosted nesta máquina, iniciado à mão (adotada)** | Modelos locais, custo zero, GPU própria | Um PR de fork poderia executar código na máquina; por isso o job só roda PRs do próprio repositório. Sem o runner ligado, nada roda |
| C. Self-hosted permanente (servidor ou VM com GPU) | Roda a qualquer hora, inclusive à noite | Custo e manutenção de uma máquina com GPU; fora do orçamento do projeto |

### Decisão 7: a linha de base e a ferramenta de comentário

| Alternativa | O que se ganha | O que se perde |
|---|---|---|
| A. Rodar a versão anterior de cada prompt a cada PR e comparar | A referência é sempre a `main` de verdade | Dobra o tempo (cerca de 30 min na suíte inteira) |
| **B. Linha de base versionada em `.github/baseline/` (adotada)** | Sem custo extra por PR; a referência é um arquivo revisável no próprio PR | Pode ficar desatualizada se esquecerem de regenerá-la; um PR pode mexer nela e esconder uma regressão (por isso o arquivo aparece no diff do PR e deve ser revisado) |
| C. A action oficial `promptfoo/promptfoo-action` | Comentário pronto e comparação antes e depois | Avalia os arquivos de prompt direto (o frontmatter entraria no texto avaliado) e usa um visualizador externo; não consegui verificar mais do que a página de documentação, e por isso não a usei |

### O que o gate não pega

- Regressão em prompt que não mudou, causada por atualização do Ollama ou de um modelo (Decisão 3).
- Piora de qualidade em quatro dos oito prompts (`decisao-backpressure` e a cadeia do Forge), que só têm asserts de forma e fatos, sem juiz.
- Um prompt já ruim que continua ruim (Decisão 1).
- Um juiz que erra de forma consistente: o juiz do `causa-raiz` foi calibrado contra oito amostras e uma referência que o Claude propôs, e tem diferenças de 2 pontos em alguns critérios.

### Evidência de execução

O workflow foi testado localmente (suíte de ponta a ponta com código 0 e uma regressão provocada com código 1; ver [`03-execucao.md`](03-execucao.md)). **O run verde e o run vermelho no GitHub (T053 e T054) ainda não existem**: dependem de publicar o repositório e registrar o runner. Esta seção será atualizada com os links dos runs.
