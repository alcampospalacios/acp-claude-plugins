---
name: gestion-tablero
description: Gestiona el tablero de GitHub Projects del proyecto en curso (estilo Jira). Úsala (1) AL EMPEZAR una sesión de trabajo en un proyecto que tenga `.claude/board.json` — analiza el tablero y resume en qué se estaba; y (2) AL TERMINAR un flujo/tarea — mueve la tarjeta a su columna y actualiza su detalle. Es global pero se centra en el board del proyecto actual (lee `.claude/board.json` de la raíz del repo). Triggers: "tablero", "board", "kanban", "empezar a trabajar", "actualiza el tablero", "mueve la tarjeta", "en qué me quedé", terminar/cerrar una tarea o feature.
---

# Gestión del tablero (GitHub Projects, estilo Jira)

Skill global. El board concreto de cada proyecto se define en `.claude/board.json` en la raíz del repo. **Siempre trabaja sobre el board del proyecto actual.**

## Requisitos
Necesita `gh` CLI **instalado y autenticado con scope `project`**. Comprueba con `gh auth status`.

- **Si `gh` NO está instalado**: NO lo instales por tu cuenta — **pide aprobación al usuario** y guíalo según su SO:
  - macOS: `brew install gh`
  - Debian/Ubuntu: `sudo apt install gh` (o ver https://cli.github.com)
  - Windows: `winget install GitHub.cli`

  Tras instalar, autentica: `gh auth login -s project -w` (login interactivo, lo hace el humano).
- **Si `gh` está pero sin scope `project`** (`gh auth status` no lista `project`): `gh auth refresh -s project` (o `gh auth login -s project -w`).
- Si `gh` no está en el PATH (macOS Homebrew): `export PATH="/opt/homebrew/bin:$PATH"`.

Sin `gh` con scope `project` no puedes operar el tablero: para y resuelve esto primero (pidiendo el OK para instalar).

## Localizar el board
Lee `.claude/board.json` de la raíz del repo. Trae: `owner`, `project_number`, `project_id`, y los `fields` (status/priority/area) con sus **option ids cacheados**. Si no existe ese archivo, ofrece crearlo (`gh project list --owner <owner>` para encontrar el número, `gh project field-list <num> --owner <owner> --format json` para los ids) y guárdalo.

## 1) AL EMPEZAR — analizar el tablero
```bash
gh project item-list <num> --owner <owner> --limit 50 --format json \
  --jq '.items[] | "\(.status // "—")\t\(.priority // "-")\t\(.area // "-")\t\(.content.title // .title)"'
```
Resume al usuario **por columna**: qué hay en *En curso*, *En espera*, *En revisión*, *En producción*; y propón lo siguiente de *Por hacer* (prioriza `High`). Si una tarjeta *En curso* tiene checklist en su body, di por dónde iba. No hace falta pedir permiso para leer.

## 2) AL TERMINAR un flujo — actualizar
Cuando cierres/avances una unidad de trabajo:
1. **Mueve la tarjeta** de columna (ver flujo abajo).
2. **Actualiza su body** (Markdown) reflejando qué se hizo / dónde quedó / qué falta (usa checklists `- [ ]`).
3. **Crea items nuevos** si surgió trabajo nuevo, con Priority y Area.

### Flujo estándar — IGUAL en TODOS los proyectos (homogeneidad)
`Por hacer → En curso → En espera → Hecho → En revisión → En producción`

| Columna | Significado |
|---|---|
| Por hacer | backlog / sin empezar |
| En curso | trabajándose ahora |
| En espera | empezado pero bloqueado por una dependencia externa para probarlo del todo |
| Hecho | desarrollo terminado, listo para revisión humana |
| En revisión | pendiente de revisión HUMANA (la hace el usuario) |
| En producción | validado y desplegado — **ESTADO FINAL** |

Usa **este mismo set y orden** al crear el board de cualquier proyecto nuevo. Los **option ids** concretos (distintos en cada proyecto) se cachean en su `board.json` (`fields.status.options`), junto al `flow` y `column_meaning`.

**Reglas al mover (quién mueve qué):**
- El agente gestiona los movimientos hasta **Hecho**: empiezas algo → *En curso*; se bloquea por dependencia → *En espera*; terminas el desarrollo → *Hecho*.
- **`En revisión` y `En producción` los mueve el USUARIO, no el agente.** Al terminar, deja la tarjeta en *Hecho* y avisa "listo para tu revisión". No la pases a *En revisión* ni *En producción* por tu cuenta salvo que el usuario lo pida.
- Actualiza siempre el body con qué se hizo / dónde quedó / qué falta.

## Comandos (cheat sheet)

**IDs — OJO (gotcha clave):**
- Editar **estado / priority / area** usa el **item id** (`PVTI_…`, campo `.id`).
- Editar **título / body** usa el **content id** (`DI_…`, campo `.content.id`).

**Mover de columna (estado):**
```bash
gh project item-edit --id <PVTI_...> --project-id <project_id> \
  --field-id <status.id> --single-select-option-id <option_id_de_board.json>
```

**Editar título/descripción (draft):**
```bash
gh project item-edit --id <DI_...> --title "…" --body "…"
```
Para bodies largos con acentos/símbolos/backticks, hazlo con un script Python que llame a `gh` por subprocess (evita el escapado del shell).

**Crear item + colocarlo:**
```bash
id=$(gh project item-create <num> --owner <owner> --title "…" --body "…" --format json --jq '.id')
gh project item-edit --id "$id" --project-id <project_id> --field-id <status.id> --single-select-option-id <opt>
```

**Set priority / area:** igual que estado, con su `field-id` y `option_id`.

## Gotchas aprendidos
- **zsh**: `status` es variable de solo lectura → usa otro nombre (`st`, `col`) en bucles bash.
- **Añadir/renombrar/reordenar columnas** se hace con `gh api graphql` (`updateProjectV2Field`) y **RESETEA todos los option ids** → los items pierden su estado. Procedimiento seguro:
  1. Backup: guarda `(item_id, status_name)` de cada item **antes**.
  2. Ejecuta el `updateProjectV2Field` con la lista completa de opciones (las viejas + la nueva, en orden).
  3. Lee los **nuevos** option ids de la respuesta.
  4. Reasigna cada item por **nombre** de estado → nuevo option id.
  5. **Actualiza `.claude/board.json`** con los nuevos ids.
- Colores válidos de opciones: `GRAY, BLUE, GREEN, YELLOW, ORANGE, RED, PURPLE, PINK`.
- Draft items: título/body por `content.id`; los campos por `.id`.

## Mantener board.json sincronizado
Si cambias columnas/campos/opciones, refresca los ids en `.claude/board.json` (con `gh project field-list <num> --owner <owner> --format json`). La skill confía en esos ids cacheados.
