#!/usr/bin/env node
// comparar.js — o gate do pipeline: falha só quando um prompt REGRIDE em relação à linha de base.
// Uso: node .github/scripts/comparar.js <baseline.json> <resumo.json>
// Regras:
//   - assert que passava na linha de base e agora falha                      => regressão (bloqueia)
//   - assert que já falhava na linha de base e continua falhando             => defeito conhecido (não bloqueia)
//   - assert que não existe na linha de base                                  => novo (informa; bloqueia se falhar)
//   - caso com juiz LLM: aprovado na linha de base (soma >= 6, nenhuma nota 0) e reprovado agora => regressão
// Saída: Markdown no stdout. Código de saída 0 = sem regressão, 1 = regressão, 2 = erro de uso ou de dados.
const fs = require('fs');

const [, , arqBase, arqNovo] = process.argv;
if (!arqBase || !arqNovo) {
  console.error('uso: comparar.js <baseline.json> <resumo.json>');
  process.exit(2);
}
const base = JSON.parse(fs.readFileSync(arqBase, 'utf-8'));
const novo = JSON.parse(fs.readFileSync(arqNovo, 'utf-8'));
const chave = (r) => `${r.caso} | ${r.modelo}`;
const mapaBase = new Map(base.map((r) => [chave(r), r]));
const aprovado = (n) => n.length === 4 && n.reduce((a, b) => a + b, 0) >= 6 && !n.includes(0);

const regressoes = [];
const conhecidos = [];
const novos = [];
let comparados = 0;

for (const r of novo) {
  const b = mapaBase.get(chave(r));
  if (!b) {
    regressoes.push(`caso sem linha de base: ${chave(r)}`);
    continue;
  }
  if (r.erro) {
    regressoes.push(`${chave(r)}: erro na execução (${r.erro})`);
    continue;
  }
  if (r.notas) {
    comparados += 1;
    const antes = b.notas || [];
    if (aprovado(antes) && !aprovado(r.notas)) {
      regressoes.push(`${chave(r)}: o juiz aprovava (${antes.join(',')} = ${antes.reduce((a, c) => a + c, 0)}) e agora reprova (${r.notas.join(',')} = ${r.notas.reduce((a, c) => a + c, 0)})`);
    } else if (!aprovado(r.notas)) {
      conhecidos.push(`${chave(r)}: juiz reprovado (${r.notas.join(',')}), já era assim na linha de base`);
    }
    continue;
  }
  const antes = new Map((b.asserts || []).map((a) => [a.id, a.ok]));
  for (const a of r.asserts) {
    comparados += 1;
    if (!antes.has(a.id)) {
      (a.ok ? novos : regressoes).push(`${chave(r)}: assert novo ${a.ok ? 'passa' : 'FALHA'}: ${a.id}`);
    } else if (antes.get(a.id) && !a.ok) {
      regressoes.push(`${chave(r)}: ${a.id}`);
    } else if (!a.ok) {
      conhecidos.push(`${chave(r)}: ${a.id}`);
    }
  }
}

const bloco = (titulo, itens) =>
  itens.length ? `\n\n**${titulo} (${itens.length})**\n\n${itens.map((i) => `- ${i}`).join('\n')}\n` : '';
const veredito = regressoes.length ? 'REGRESSÃO: o build falha' : 'sem regressão em relação à linha de base';
console.log(`### ${veredito}\n\nAsserts comparados: ${comparados}.${bloco('Regressões', regressoes)}${bloco('Defeitos conhecidos, não bloqueiam', conhecidos)}${bloco('Asserts novos', novos)}`);
process.exit(regressoes.length ? 1 : 0);
