# Playbook de IA Operacional

Biblioteca de prompts parametrizáveis, versionada, testada e tratada como código, para a operação da Aegis (empresa fictícia de observabilidade e resposta a incidentes). Desenvolvida como desafio da pós-graduação em AIOps e Inteligência Artificial com Engenharia Cloud ([pos.veronez.io/pos-aiops](https://pos.veronez.io/pos-aiops/)).

## Estrutura

```text
playbook-ia-operacional/
├── README.md  CLAUDE.md  CHANGELOG.md  CONTRIBUTING.md  LICENSE
├── validate.sh                      # valida a estrutura e os prompts
├── devops/                          # a biblioteca de prompts (convenções do template prompt-registry)
│   ├── README.md                    # escopo da categoria e índice dos prompts
│   └── <nome-do-prompt>/
│       ├── prompt.md                # frontmatter + texto do prompt, com {{placeholders}}
│       ├── README.md                # o mesmo frontmatter + documentação
│       └── promptfooconfig.yaml     # teste do prompt (a partir do CP08)
├── checkpoints/                     # o caminho percorrido em cada checkpoint
│   └── checkpoint-XX/
│       ├── README.md
│       ├── 01-contexto.md  02-prompt.md  03-execucao.md  04-curadoria.md
│       └── entradas/                # dados do enunciado, transcritos
└── providers/
    └── ollama-local.js              # provedor do promptfoo para o Ollama local (custo US$ 0)
```

A biblioteca segue o template `prompt-registry`: categoria como pasta na raiz, um prompt por pasta nomeada pelo resultado, frontmatter com `nome`, `descricao`, `versao`, `tags` e `inputs`, placeholders `{{variavel}}`, versionamento semver e commits semânticos. O teste de cada prompt viaja junto com ele, no `promptfooconfig.yaml`. A documentação por checkpoint segue o padrão do repositório `frameworks-prompt-engineering`. Detalhes em [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Checkpoints

| CP | Tema | Situação |
|----|------|----------|
| [01](checkpoints/checkpoint-01/) | Triagem de pods ([`devops/triagem-de-pods`](devops/triagem-de-pods/)) | Concluído |
| [02](checkpoints/checkpoint-02/) | Nota de triagem padronizada ([`devops/nota-de-triagem`](devops/nota-de-triagem/)) | Concluído |
| [03](checkpoints/checkpoint-03/) | Causa-raiz da degradação no Cerebro ([`devops/causa-raiz`](devops/causa-raiz/)) | Concluído |
| [04](checkpoints/checkpoint-04/) | Decisão de backpressure do Relay ([`devops/decisao-backpressure`](devops/decisao-backpressure/)) | Concluído |
| [05](checkpoints/checkpoint-05/) | Cadeia de prompts da migração do Forge ([`diagnostico`](devops/migracao-forge-diagnostico/), [`plano`](devops/migracao-forge-plano/), [`execucao`](devops/migracao-forge-execucao/)) | Concluído |
| [06](checkpoints/checkpoint-06/) | NetworkPolicy do Sentinel com verificação e refino ([`networkpolicy-sentinel`](devops/networkpolicy-sentinel/)) | Concluído |
| [07](checkpoints/checkpoint-07/) | Biblioteca no formato do template e nota de mapeamento | Em andamento (falta o link público) |
| [08](checkpoints/checkpoint-08/) | Testes determinísticos com `promptfoo` ([`nota-de-triagem`](devops/nota-de-triagem/), [`triagem-de-pods`](devops/triagem-de-pods/), [`networkpolicy-sentinel`](devops/networkpolicy-sentinel/)) | Concluído, com reprovações registradas |
| [09](checkpoints/checkpoint-09/) | Gate de qualidade com LLM-as-judge ([`causa-raiz`](devops/causa-raiz/)) | Concluído, com calibração parcial |
| [10](checkpoints/checkpoint-10/) | Pipeline no GitHub Actions ([`.github/workflows/prompts.yml`](.github/workflows/prompts.yml)) | Em andamento: workflow pronto e testado localmente, falta rodar no GitHub |

## Modelos

As execuções rodam localmente, via Ollama, sem custo de API. Cada execução registra o modelo e o fornecedor realmente usados.

| Modelo | Fornecedor | Uso previsto |
|--------|-----------|-----|
| `qwen3:14b` | Alibaba | Prompts dos CP01 a CP06 e gerador do gate do CP09 |
| `gpt-oss:20b` | OpenAI | Prompts dos CP01 a CP06 e juiz do CP09 |
| `llama3.2:3b` | Meta | Testes com limite de latência de 5 s (CP08) |
| `gemma3:4b` | Google | Testes com limite de latência de 5 s (CP08) |

Todos rodam pelo Ollama, em uma máquina local; os fornecedores são quatro (Alibaba, OpenAI, Meta e Google). A escolha segue quatro critérios:

- **Custo:** zero de API nos quatro modelos; o custo real é energia e hardware. O provedor do `promptfoo` devolve `cost: 0`.
- **Latência:** `qwen3:14b` e `gpt-oss:20b` não cumprem 5 s (17 s e de 79 a 158 s no prompt de NetworkPolicy), então ficam nos checkpoints 01 a 06, sem limite; só `llama3.2:3b` (3,2 a 4,0 s) e `gemma3:4b` (3,7 a 8,2 s, a primeira chamada estoura sem aquecimento) cabem no limite do CP08.
- **Qualidade:** `qwen3:14b` e `gpt-oss:20b` são os mais capazes que cabem na GPU local e vêm de famílias diferentes, o que permite comparar as respostas. Os modelos pequenos têm menos capacidade, e por isso o CP08 testa a estrutura da saída e o CP09 usa o `gpt-oss:20b` como juiz (o `qwen3:14b` gera a análise).
- **Privacidade:** a execução é local e nenhum dado sai da máquina; os dados dos cenários são fictícios, e o checkpoint 03 registra a sanitização que seria feita com dados reais.

## Como reproduzir

Requisitos: Ollama com os modelos acima, Node.js e `promptfoo`.

```bash
ollama pull qwen3:14b && ollama pull gpt-oss:20b && ollama pull llama3.2:3b && ollama pull gemma3:4b
npm install -g promptfoo
./validate.sh
```

## Licença

Ver [`LICENSE`](LICENSE).
