#!/usr/bin/env bash
# selecionar.sh — decide quais prompts a suíte testa.
# Uso: selecionar.sh <sha-base> <sha-novo>   (ou "todos" no lugar do primeiro argumento)
# Imprime um nome de prompt por linha.
#   - mudou devops/<prompt>/            => só esse prompt (e os que dependem dele na cadeia do Forge)
#   - mudou providers/, .github/ ou validate.sh (infraestrutura da suíte) => todos
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
todos() { ls -d devops/*/ | xargs -n1 basename; }

base="${1:-todos}"; novo="${2:-HEAD}"
if [ "$base" = "todos" ] || [ "$base" = "0000000000000000000000000000000000000000" ] || ! git cat-file -e "$base" 2>/dev/null; then
  todos; exit 0
fi
mudou="$(git diff --name-only "$base" "$novo")"
if echo "$mudou" | grep -qE '^(providers/|\.github/(scripts|workflows)/|validate\.sh)'; then
  todos; exit 0
fi
{
  echo "$mudou" | grep -E '^devops/[^/]+/' | cut -d/ -f2
  # a cadeia do Forge: mudar um elo muda a entrada do seguinte, então testa-se o elo e os seguintes
  if echo "$mudou" | grep -q '^devops/migracao-forge-diagnostico/'; then echo migracao-forge-plano; echo migracao-forge-execucao; fi
  if echo "$mudou" | grep -q '^devops/migracao-forge-plano/'; then echo migracao-forge-execucao; fi
} | sort -u | while read -r p; do [ -f "devops/$p/promptfooconfig.yaml" ] && echo "$p"; done || true
