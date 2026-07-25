---
description: Analiza el tablero del proyecto actual y resume en qué se estaba
---

Analiza el tablero de este proyecto con la skill `github-projects-board`:

1. Lee `.claude/board.json` de la raíz del repo (owner, project_number, ids). Si no existe, ofrece crearlo.
2. Lista los items: `gh project item-list <num> --owner <owner> --limit 60 --format json`.
3. Resume **por columna**: qué hay en *En curso* y *En espera* (con lo que falta según su checklist), qué está en *Hecho* pendiente de mi revisión, y propón el siguiente paso de *Por hacer* priorizando `High`.

Recuerda: el flujo es `Por hacer → En curso → En espera → Hecho → En revisión → En producción`. Tú mueves hasta *Hecho*; *En revisión* y *En producción* las muevo yo (el usuario).
