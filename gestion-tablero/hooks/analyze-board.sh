#!/usr/bin/env bash
# SessionStart hook: si el proyecto tiene .claude/board.json, inyecta un resumen del tablero.
# Diseñado para NUNCA romper el arranque de la sesión (siempre exit 0).

DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
BOARD="$DIR/.claude/board.json"
[ -f "$BOARD" ] || exit 0

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# gh no instalado: avisa (con OK del usuario) en vez de callar.
if ! command -v gh >/dev/null 2>&1; then
  echo "## 📋 Tablero del proyecto — falta \`gh\`"
  echo ""
  echo "Este proyecto tiene un tablero (\`.claude/board.json\`) pero el CLI \`gh\` no está instalado, así que no puedo resumirlo ni actualizarlo."
  echo "Con la aprobación del usuario, instálalo y autentícate:"
  echo "- macOS: \`brew install gh\`  ·  Ubuntu/Debian: \`sudo apt install gh\`  ·  Windows: \`winget install GitHub.cli\`"
  echo "- Luego: \`gh auth login -s project -w\`"
  exit 0
fi

command -v python3 >/dev/null 2>&1 || exit 0

# gh sin scope 'project': indica cómo añadirlo.
if ! gh auth status 2>/dev/null | grep -q "project"; then
  echo "## 📋 Tablero del proyecto — falta permiso en \`gh\`"
  echo ""
  echo "\`gh\` está instalado pero sin el scope \`project\`. Ejecuta: \`gh auth refresh -s project\` (o \`gh auth login -s project -w\`)."
  exit 0
fi

info=$(python3 -c "import json,sys; d=json.load(open('$BOARD')); print(d['owner'], d['project_number'])" 2>/dev/null) || exit 0
OWNER=$(printf '%s' "$info" | awk '{print $1}')
NUM=$(printf '%s' "$info" | awk '{print $2}')
[ -n "$OWNER" ] && [ -n "$NUM" ] || exit 0

SUMMARY=$(gh project item-list "$NUM" --owner "$OWNER" --limit 60 --format json \
  --jq '.items[] | "\(.status // "—")\t\(.priority // "-")\t\(.content.title // .title)"' 2>/dev/null \
  | sort | awk -F'\t' '{printf "- [%s] (%s) %s\n", $1, $2, $3}')
[ -n "$SUMMARY" ] || exit 0

echo "## 📋 Tablero del proyecto ($OWNER / #$NUM)"
echo ""
echo "$SUMMARY"
echo ""
echo "_Al empezar: revisa en qué se estaba (En curso / En espera), qué hay en Hecho pendiente de revisión del usuario, y propón el siguiente paso de Por hacer (prioriza High). 'En revisión' y 'En producción' las mueve el usuario, no el agente._"
exit 0
