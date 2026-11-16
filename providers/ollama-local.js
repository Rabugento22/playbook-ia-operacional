// ollama-local.js — provedor do promptfoo para o Ollama local, informando custo US$ 0.
// Necessário porque o provedor nativo do Ollama não devolve custo e o assert `cost` falha.
module.exports = class OllamaLocal {
  constructor(options) {
    this.config = options.config || {};
    this.providerId = options.id || `ollama-local:${this.config.model}`;
  }

  id() {
    return this.providerId;
  }

  async callApi(prompt) {
    const {
      model,
      think = false,
      baseUrl = process.env.OLLAMA_BASE_URL || 'http://localhost:11434',
      ...options
    } = this.config;
    const res = await fetch(`${baseUrl}/api/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model,
        think,
        stream: false,
        options,
        messages: [{ role: 'user', content: prompt }],
      }),
    });
    const data = await res.json();
    if (data.error) return { error: data.error };
    return {
      output: data.message.content,
      cost: 0,
      tokenUsage: {
        prompt: data.prompt_eval_count,
        completion: data.eval_count,
        total: (data.prompt_eval_count || 0) + (data.eval_count || 0),
      },
    };
  }
};
