#!/usr/bin/env bash
# rodar-suite.sh — roda o promptfoo nos prompts escolhidos e compara com a linha de base.
# Uso: PROMPTS="a b c" .github/scripts/rodar-suite.sh [--atualizar-baseline]
# Saídas: resultados/<prompt>.json (promptfoo), resultados/<prompt>.resumo.json, resultados/relatorio.md
# Código de saída: 0 sem regressão, 1 com regressão em algum prompt.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
atualizar=0; [ "${1:-}" = "--atualizar-baseline" ] && atualizar=1
out="${SAIDA:-resultados}"; mkdir -p "$out"
relatorio="$out/relatorio.md"; : > "$relatorio"
regrediu=0

command -v promptfoo >/dev/null || { echo "promptfoo não encontrado no PATH"; exit 2; }
curl -fsS "${OLLAMA_BASE_URL:-http://localhost:11434}/api/tags" >/dev/null || { echo "Ollama não responde"; exit 2; }

aquecer() { # o primeiro uso de um modelo frio inclui o carregamento e estoura a latência
  curl -s "${OLLAMA_BASE_URL:-http://localhost:11434}/api/generate" \
    -d "{\"model\":\"$1\",\"prompt\":\"oi\",\"stream\":false,\"keep_alive\":\"30m\",\"options\":{\"num_ctx\":8192,\"num_predict\":5}}" >/dev/null || true
}
for p in $PROMPTS; do
  case "$p" in nota-de-triagem|triagem-de-pods|networkpolicy-sentinel) aquecer llama3.2:3b; aquecer gemma3:4b; break;; esac
done

rodar() { # <prompt> <tentativa>
  promptfoo eval -c "devops/$1/promptfooconfig.yaml" --no-cache -j 1 --no-progress-bar -o "$out/$1.json" > "$out/$1.console.txt" 2>&1 || true
  node .github/scripts/resumir.js "$out/$1.json" > "$out/$1.resumo.json"
}

for p in $PROMPTS; do
  echo "== $p"
  if [ ! -f "devops/$p/promptfooconfig.yaml" ]; then echo "- \`$p\`: sem promptfooconfig.yaml" >> "$relatorio"; regrediu=1; continue; fi
  rodar "$p"
  if [ "$atualizar" = 1 ]; then cp "$out/$p.resumo.json" ".github/baseline/$p.json"; echo "linha de base de $p atualizada"; continue; fi
  if [ ! -f ".github/baseline/$p.json" ]; then
    echo "## $p" >> "$relatorio"; echo "### REGRESSÃO: prompt sem linha de base (.github/baseline/$p.json)" >> "$relatorio"; regrediu=1; continue
  fi
  cmp_out="$(node .github/scripts/comparar.js ".github/baseline/$p.json" "$out/$p.resumo.json")"; cod=$?
  # o juiz LLM varia entre execuções: uma reprovação isolada é refeita uma vez, e só barra se repetir
  if [ "$cod" = 1 ] && [ "$p" = "causa-raiz" ]; then
    echo "juiz reprovou; repetindo uma vez"
    rodar "$p"
    cmp_out="$(node .github/scripts/comparar.js ".github/baseline/$p.json" "$out/$p.resumo.json")"; cod=$?
  fi
  { echo "## $p"; echo "$cmp_out"; echo; } >> "$relatorio"
  [ "$cod" != 0 ] && regrediu=1
done
cat "$relatorio"
exit "$regrediu"
