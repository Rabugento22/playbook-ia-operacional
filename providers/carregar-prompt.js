// carregar-prompt.js — carrega devops/<prompt>/prompt.md para o promptfoo.
// Tira o frontmatter e troca cada {{parametro}} pelo valor do caso de teste,
// de modo que o teste exercite o texto exato do prompt da biblioteca.
// O caso de teste informa a pasta do prompt na variável `prompt_dir`.
const fs = require('fs');
const path = require('path');

module.exports = function carregarPrompt({ vars }) {
  const pasta = vars.prompt_dir;
  if (!pasta) throw new Error('defina a variável prompt_dir (nome da pasta em devops/)');
  const arquivo = path.join(__dirname, '..', 'devops', pasta, 'prompt.md');
  const texto = fs.readFileSync(arquivo, 'utf-8');
  const corpo = texto.replace(/^---\n[\s\S]*?\n---\n/, '').replace(/^\n+/, '');
  return corpo.replace(/\{\{(\w+)\}\}/g, (marca, nome) =>
    nome in vars ? String(vars[nome]) : marca,
  );
};
