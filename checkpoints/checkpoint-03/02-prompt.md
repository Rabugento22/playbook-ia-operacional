# Prompt parametrizável

Parâmetros: `{{config}}` (configuração), `{{metricas}}` (métricas da janela) e `{{logs}}` (logs de um nó), cada um dentro de delimitadores no fim do prompt.

O texto abaixo é idêntico ao corpo de [`devops/causa-raiz/prompt.md`](../../devops/causa-raiz/prompt.md), que é o arquivo versionado da biblioteca; a conferência é feita pelo `validate.sh`.

## Versão final (v5)

````text
Papel: engenheiro de observabilidade e resposta a incidentes.  
Tarefa: analisar a degradação de um sistema cruzando a configuração, as métricas e os logs fornecidos ao final deste prompt, para chegar à causa-raiz (e não apenas listar sintomas), ao mecanismo, aos efeitos e às correlações, com recomendações de ação.  

Regras:  
1. Linha do Tempo: ordene em ordem cronológica os eventos da configuração, das métricas e dos logs, citando horários e valores específicos.  
2. Causa-Raiz: identifique a condição inicial que, se corrigida, interrompe a cadeia que leva ao problema. Não confunda causa com sintoma ou efeito.  
3. Mecanismo: Explique como a causa-raiz gerou o problema, apresentando uma cadeia causal numerada (causa-raiz → etapa 1 → etapa 2 → … → sintoma visível), cada elo com sua evidência (valor e horário da métrica, trecho do log, parâmetro da configuração).  
4. Efeitos/Consequências: Liste impactos diretos, indicando de qual etapa do mecanismo decorrem.  
5. Correlações: itens que variam junto com o problema, mas cuja relação causal os dados não demonstram. Diferem dos efeitos, que são consequências demonstradas de uma etapa do mecanismo.  
6. Grau de Confiança: dê um único grau (alta, média ou baixa) para a causa-raiz e justifique. Antes de decidir, teste a hipótese principal contra todos os dados: liste o que ela explica e o que ela NÃO explica (valores, horários ou comportamentos que não se encaixam). Se algum dado relevante não se encaixa, a confiança não pode ser alta.  
7. Honestidade Epistêmica: Liste limitações dos dados (ex.: ausência de logs de outro nó), hipóteses alternativas não descartadas e dados adicionais necessários.  
8. Ações: recomende “conter agora” e “corrigir depois”, proporcionais ao diagnóstico e ligadas à causa-raiz. Em “conter agora”, prefira ações reversíveis e de menor alcance que interrompam a cadeia; mudanças estruturais (como aumentar recursos ou reconfigurar o cluster) só entram em “corrigir depois”, e apenas se a evidência as sustentar. Indique o que NÃO fazer ainda por falta de evidência.  
9. Evidência e fidelidade: cite sempre a evidência com valor e horário (métrica), trecho do log ou parâmetro da configuração. Não invente dados ausentes dos artefatos; se um dado ou horário não aparecer, diga isso. Leia as métricas na ordem do tempo e na direção correta (subiu ou desceu). Não confunda o horário em que algo começou (agendamento, configuração) com o horário do primeiro registro dele nos logs.
10. Estilo: escreva em português, em texto simples, sem negrito e sem cercas de código.

Formato de Saída:  
Linha do Tempo:  
- [Horário] [Evento] (Evidência: a configuração, as métricas ou os logs).  

Causa-Raiz:  
- [Descrição] (Evidência: ...).  

Mecanismo:  
1. [Etapa 1] (Evidência: ...).  
2. [Etapa 2] (Evidência: ...).  
…  
n. [Sintoma visível] (Evidência: ...).  

Efeitos/Consequências:  
- [Lista de impactos diretos, com referência à etapa do mecanismo].  

Correlações:  
- [Itens relacionados, mas não causais].  

Grau de Confiança:  
- [Alta/Média/Baixa] (Justificativa: ...).  

Limitações dos Dados:  
- [O que não pode ser concluído].  
- [Hipóteses alternativas não descartadas].  
- [Dados adicionais necessários].  

Ações:  
- Conter agora: [Recomendações imediatas].  
- Corrigir depois: [Recomendações de longo prazo].  

<config>
{{config}}
</config>
<metricas>
{{metricas}}
</metricas>
<logs>
{{logs}}
</logs>
````

## Evolução

Geração por meta-prompting; as versões 4 e 5 são refinos manuais dirigidos por mim sobre o texto gerado.

| Versão | Origem | Defeitos observados |
|--------|--------|---------------------|
| v1 | `qwen3:14b`, a partir dos requisitos do enunciado | Os três placeholders apareciam em cerca de dez pontos do texto, e a execução colaria cada artefato dezenas de vezes; exemplos com números inventados; definição de correlação errada. Não foi executada. |
| v2 | `qwen3:14b`, com esses defeitos como feedback | **Apagou os placeholders** (blocos vazios), manteve os exemplos inventados e o negrito. Não foi executada. |
| v3 | `gpt-oss:20b` (raciocínio médio, 247 s), com um bloco final especificado | Placeholders corretos (um de cada, em bloco final) e cadeia causal numerada. Ainda tinha redação truncada ("eventos de a configuração"), hífens não padrão e correlação sem definição. |
| v4 | Refino manual sobre a v3 | Redação corrigida, correlação definida (varia junto, sem causalidade demonstrada), regra de evidência e fidelidade, estilo em texto simples. Execução: `qwen3:14b` com confiança **alta**, vazão atribuída à reindexação sem sustentação e sugestão de heap de 8 para 16 GB; `gpt-oss:20b` com duas confianças ao mesmo tempo, leitura invertida da vazão ("diminuição de 12400 a 11200") e reindexação "iniciada em 08:02". |
| v5 | Refino manual sobre a v4 | Teste da hipótese contra todos os dados, grau único de confiança, "conter agora" só com ações reversíveis e de menor alcance, leitura das métricas na direção correta e distinção entre início do evento e primeiro registro no log. Resultados em [execução](03-execucao.md) e [curadoria](04-curadoria.md). |
