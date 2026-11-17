#!/usr/bin/env node
// resumir.js — reduz o JSON do `promptfoo eval` a um resumo comparável.
// Uso: node .github/scripts/resumir.js <resultado.json> > resumo.json
// Cada resultado vira { caso, modelo, asserts: [{id, ok}] } (asserts comuns)
// ou { caso, modelo, notas: [c1, c2, c3, c4] } (juiz LLM: uma nota de 0 a 2 por critério).
const fs = require('fs');

const arquivo = process.argv[2];
if (!arquivo) {
  console.error('uso: resumir.js <resultado.json>');
  process.exit(2);
}
const dados = JSON.parse(fs.readFileSync(arquivo, 'utf-8'));
const rotulo = (a) => {
  const v = a.value === undefined ? a.threshold ?? '' : String(a.value).replace(/\s+/g, ' ').trim();
  return `${a.type}:${String(v).slice(0, 120)}`;
};
const resumo = dados.results.results.map((r) => {
  const comp = (r.gradingResult && r.gradingResult.componentResults) || [];
  const base = { caso: r.testCase.description, modelo: r.provider.label };
  if (comp.length && comp.every((c) => c.assertion && c.assertion.type === 'llm-rubric')) {
    return { ...base, notas: comp.map((c) => Math.round(c.score)) };
  }
  // failureReason: 0 = passou, 1 = assert falhou, 2 = erro de execução (modelo fora do ar, tempo esgotado)
  if (r.failureReason === 2) return { ...base, erro: String(r.error).slice(0, 200), asserts: [] };
  return { ...base, asserts: comp.map((c) => ({ id: rotulo(c.assertion), ok: !!c.pass })) };
});
console.log(JSON.stringify(resumo, null, 2));
