#!/usr/bin/env bash
# SessionStart hook: si el proyecto tiene .claude/board.json, inyecta un resumen del tablero.
# Diseñado para NUNCA romper el arranque de la sesión (siempre exit 0).

DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
BOARD="$DIR/.claude/board.json"
[ -f "$BOARD" ] || exit 0

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
command -v gh >/dev/null 2>&1 || exit 0
command -v python3 >/dev/null 2>&1 || exit 0
gh auth status 2>/dev/null | grep -q "project" || exit 0

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
