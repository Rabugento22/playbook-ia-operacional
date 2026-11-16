#!/usr/bin/env bash

###############################################################################
# Projeto : Playbook de IA Operacional
# Objetivo: Validar a estrutura do repositório e os prompts de cada checkpoint.
# Uso     : ./validate.sh   (saída 0 = sem erros)
###############################################################################

set -uo pipefail
cd "$(dirname "$0")"
exec python3 -I - <<'PY'
import os, re, sys, glob

erros, avisos = [], []
ok = lambda m: print(f"  ok  {m}")
def erro(m): erros.append(m); print(f" ERRO {m}")
def aviso(m): avisos.append(m); print(f"aviso {m}")

print("[1/5] Arquivos obrigatórios na raiz")
for f in ["README.md", "CLAUDE.md", "CHANGELOG.md", "CONTRIBUTING.md", "LICENSE", "validate.sh", "providers/ollama-local.js"]:
    ok(f) if os.path.isfile(f) else erro(f"falta {f}")

print("[2/5] Estrutura sem resíduos do template")
for d in ["devops", "desenvolvimento", "financas", "produtividade", "criacao-conteudo", ".claude/commands"]:
    erro(f"resíduo do template: {d}/") if os.path.exists(d) else ok(f"sem {d}/")

def frontmatter(texto):
    m = re.match(r"---\n(.*?)\n---\n", texto, re.S)
    return (m.group(1), texto[m.end():]) if m else (None, texto)

def parse(fm):
    campos = {k: re.search(rf"^{k}:\s*(.*)$", fm, re.M) for k in ["nome", "descricao", "versao", "tags"]}
    inputs = re.findall(r"^\s+- nome:\s*(\S+)", fm, re.M)
    return campos, inputs

print("[3/5] Checkpoints")
for cp in sorted(glob.glob("checkpoints/checkpoint-*")):
    n = os.path.basename(cp)
    if not os.path.isdir(f"{cp}/entradas"): aviso(f"{n}: sem entradas/")
    pm = f"{cp}/prompt.md"
    if not os.path.isfile(pm):
        print(f"  --  {n}: sem prompt.md (checkpoint ainda não produzido ou sem prompt)")
        continue
    for f in ["README.md", "01-contexto.md", "02-prompt.md", "03-execucao.md", "04-curadoria.md"]:
        if not os.path.isfile(f"{cp}/{f}"): erro(f"{n}: falta {f}")
    if not os.path.isfile(f"{cp}/README.md") or not os.path.isfile(f"{cp}/02-prompt.md"): continue
    fm_p, corpo = frontmatter(open(pm, encoding="utf-8").read())
    fm_r, _ = frontmatter(open(f"{cp}/README.md", encoding="utf-8").read())
    if fm_p is None: erro(f"{n}: prompt.md sem frontmatter"); continue
    ok(f"{n}: frontmatter presente") 
    erro(f"{n}: frontmatter diferente entre prompt.md e README.md") if fm_p != fm_r else ok(f"{n}: frontmatter idêntico em prompt.md e README.md")
    campos, inputs = parse(fm_p)
    for k, v in campos.items():
        if v is None or not v.group(1).strip(): erro(f"{n}: campo '{k}' ausente")
    if campos["versao"] and not re.fullmatch(r"\d+\.\d+\.\d+", campos["versao"].group(1).strip()): erro(f"{n}: versao fora de semver")
    if campos["tags"]:
        nt = len([t for t in campos["tags"].group(1).strip("[] ").split(",") if t.strip()])
        if not 2 <= nt <= 5: erro(f"{n}: tags deve ter de 2 a 5 itens (tem {nt})")
    ph = sorted(set(re.findall(r"\{\{(\w+)\}\}", corpo)))
    erro(f"{n}: placeholders {ph} diferentes de inputs {sorted(inputs)}") if ph != sorted(inputs) else ok(f"{n}: placeholders = inputs {ph}")
    txt02 = open(f"{cp}/02-prompt.md", encoding="utf-8").read()
    m = re.search(r"````text\n(.*?)\n````", txt02, re.S)
    if not m: erro(f"{n}: 02-prompt.md sem bloco do prompt final")
    elif m.group(1).strip() != corpo.strip(): erro(f"{n}: prompt em 02-prompt.md difere do corpo de prompt.md")
    else: ok(f"{n}: 02-prompt.md idêntico ao corpo de prompt.md")

print("[4/5] Links relativos nos arquivos Markdown")
for md in [f for f in glob.glob("**/*.md", recursive=True)]:
    texto = re.sub(r"```.*?```", "", open(md, encoding="utf-8").read(), flags=re.S)
    for alvo in re.findall(r"\]\(([^)\s]+)\)", texto):
        if re.match(r"(https?:|mailto:|#)", alvo): continue
        caminho = os.path.normpath(os.path.join(os.path.dirname(md), alvo.split("#")[0]))
        if not os.path.exists(caminho): erro(f"{md}: link quebrado -> {alvo}")
print("  ok  links conferidos") if not [e for e in erros if "link quebrado" in e] else None

print("[5/5] Sintaxe do provedor")
import subprocess
r = subprocess.run(["node", "--check", "providers/ollama-local.js"], capture_output=True, text=True)
ok("providers/ollama-local.js") if r.returncode == 0 else erro("providers/ollama-local.js: " + r.stderr.strip())

print(f"\nResultado: {len(erros)} erro(s), {len(avisos)} aviso(s)")
sys.exit(1 if erros else 0)
PY
