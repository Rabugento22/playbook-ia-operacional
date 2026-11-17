// gate.js — regra de aprovação do CP09, aplicada às notas dos quatro critérios do juiz.
// Aprova quando a soma é >= 6 (de 8) e nenhum critério é 0.
// O promptfoo chama esta função com os resultados dos quatro llm-rubric (um por critério).
module.exports = (namedScores, context) => {
  const notas = context.componentResults.map((r) => Math.round(r.score));
  const total = notas.reduce((a, b) => a + b, 0);
  const zerados = notas.map((n, i) => (n === 0 ? `C${i + 1}` : null)).filter(Boolean);
  const pass = notas.length === 4 && total >= 6 && zerados.length === 0;
  const detalhe = notas.map((n, i) => `C${i + 1}=${n}`).join('; ');
  return {
    pass,
    score: total / 8,
    reason:
      `${detalhe}; total=${total}/8. ` +
      (pass
        ? 'Aprovada (total >= 6 e nenhum critério zerado).'
        : `Reprovada (${total < 6 ? 'total abaixo de 6' : ''}${total < 6 && zerados.length ? ' e ' : ''}${zerados.length ? 'critério zerado: ' + zerados.join(', ') : ''}).`),
  };
};
