# Playbook de IA Operacional

Biblioteca de prompts parametrizáveis, versionada, testada e tratada como código, para a operação da Aegis (empresa fictícia de observabilidade e resposta a incidentes). Desenvolvida como desafio da pós-graduação em AIOps e Inteligência Artificial com Engenharia Cloud ([pos.veronez.io/pos-aiops](https://pos.veronez.io/pos-aiops/)).

## Estrutura

```text
playbook-ia-operacional/
├── README.md  CLAUDE.md  CHANGELOG.md  CONTRIBUTING.md  LICENSE
├── validate.sh                  # valida a estrutura e os prompts
├── providers/
│   └── ollama-local.js          # provedor do promptfoo para o Ollama local (custo US$ 0)
└── checkpoints/
    └── checkpoint-XX/
        ├── README.md            # frontmatter + documentação do prompt (CP01–06)
        ├── prompt.md            # frontmatter + texto do prompt, com {{placeholders}}
        ├── promptfooconfig.yaml # teste do prompt (a partir do CP08)
        ├── 01-contexto.md
        ├── 02-prompt.md
        ├── 03-execucao.md
        ├── 04-curadoria.md
        └── entradas/            # dados do enunciado, transcritos
```

Cada checkpoint que produz um prompt guarda o prompt, o teste e o caminho percorrido na mesma pasta: o teste viaja junto com o prompt. As convenções do template `prompt-registry` (frontmatter com `nome`, `descricao`, `versao`, `tags` e `inputs`, placeholders `{{variavel}}`, semver e commits semânticos) valem dentro de cada checkpoint. Detalhes em [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Checkpoints

| CP | Tema | Situação |
|----|------|----------|
| [01](checkpoints/checkpoint-01/) | Triagem de pods | Concluído |
| 02 | Nota de triagem padronizada | Pendente |
| 03 | Causa-raiz da degradação no Cerebro | Pendente |
| 04 | Decisão de backpressure do Relay | Pendente |
| 05 | Cadeia de prompts da migração do Forge | Pendente |
| 06 | NetworkPolicy do Sentinel, com verificação e refino | Pendente |
| 07 | Biblioteca no formato do template | Pendente |
| 08 | Testes determinísticos com `promptfoo` | Pendente |
| 09 | Gate de qualidade com LLM-as-judge | Pendente |
| 10 | Pipeline no GitHub Actions | Pendente |

## Modelos

As execuções rodam localmente, via Ollama, sem custo de API. Cada execução registra o modelo e o fornecedor realmente usados.

| Modelo | Fornecedor | Uso previsto |
|--------|-----------|-----|
| `qwen3:14b` | Alibaba | Prompts dos CP01 a CP06 e juiz do CP09 |
| `gpt-oss:20b` | OpenAI | Prompts dos CP01 a CP06 |
| `llama3.2:3b` | Meta | Testes com limite de latência de 5 s (CP08) |
| `gemma3:4b` | Google | Testes com limite de latência de 5 s (CP08) |

## Como reproduzir

Requisitos: Ollama com os modelos acima, Node.js e `promptfoo`.

```bash
ollama pull qwen3:14b && ollama pull gpt-oss:20b && ollama pull llama3.2:3b && ollama pull gemma3:4b
npm install -g promptfoo
./validate.sh
```

## Licença

Ver [`LICENSE`](LICENSE).
