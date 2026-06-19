#!/usr/bin/env bash
# Muestra solo lo que nos interesa del repo: CLAUDE.md, el skill de Claude Code,
# y el árbol del módulo LFCS. Ignora Accenture/, DevOps/, TCC/, .git, etc.
set -euo pipefail

cd "$(dirname "$0")"

LFCS_PATH="KodeKloud/01 - Linux/01 - Linux Foundation Certified System Administrator (LFCS) Certification"

tiene_tree() { command -v tree >/dev/null 2>&1; }

echo "════════════════════════════════════════"
echo " Raíz del proyecto (config de Claude Code)"
echo "════════════════════════════════════════"
[ -f "CLAUDE.md" ] && echo "✅ CLAUDE.md" || echo "❌ CLAUDE.md (falta)"

if [ -d ".claude/skills" ]; then
  if tiene_tree; then
    tree -a ".claude/skills"
  else
    find ".claude/skills" -print | sed 's|[^/]*/|  |g'
  fi
else
  echo "❌ .claude/skills/ (falta)"
fi

echo
echo "════════════════════════════════════════"
echo " Módulo LFCS"
echo "════════════════════════════════════════"

if [ ! -d "$LFCS_PATH" ]; then
  echo "❌ No encontré: $LFCS_PATH"
  echo "   Ajustá la variable LFCS_PATH dentro del script si moviste algo."
  exit 1
fi

if tiene_tree; then
  # -I filtra ruido si algún día metés node_modules, .git, etc. dentro
  tree -I '.git|node_modules' "$LFCS_PATH"
else
  find "$LFCS_PATH" \
    \( -path '*/.git' -o -path '*/node_modules' \) -prune -o -print \
    | sed -E "s|^$LFCS_PATH||; s|[^/]*/|  |g"
fi

echo
echo "════════════════════════════════════════"
echo " Conteo de incidentes por módulo (Playgrounds)"
echo "════════════════════════════════════════"

PG="$LFCS_PATH/Playgrounds"
if [ -d "$PG" ]; then
  for carpeta in "$PG"/*/; do
    nombre=$(basename "$carpeta")
    total=$(find "$carpeta" -maxdepth 1 -name '*.md' ! -name 'Lista de Laboratorios*' ! -iname 'lista*' | wc -l)
    printf "  %-35s %s incidente(s)\n" "$nombre" "$total"
  done
else
  echo "❌ No encontré Playgrounds en: $PG"
fi
