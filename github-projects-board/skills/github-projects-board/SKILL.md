---
name: github-projects-board
description: Gestiona el tablero de GitHub Projects del proyecto en curso (estilo Jira). Úsala (1) AL EMPEZAR una sesión de trabajo en un proyecto que tenga `.claude/board.json` — analiza el tablero y resume en qué se estaba; (2) AL RECIBIR CUALQUIER TAREA en ese proyecto — comprueba si ya hay tarjeta o si es trabajo nuevo que hay que dar de alta, ANTES de tocar código; y (3) AL TERMINAR un flujo/tarea — mueve la tarjeta a su columna y actualiza su detalle. Es global pero se centra en el board del proyecto actual (lee `.claude/board.json` de la raíz del repo). Triggers: "tablero", "board", "kanban", "empezar a trabajar", "actualiza el tablero", "mueve la tarjeta", "en qué me quedé", terminar/cerrar una tarea o feature, y CUALQUIER petición de trabajo (bug, feature, arreglo) en un repo con `.claude/board.json`.
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

## 2) AL RECIBIR UNA TAREA — ¿ya está en el tablero o es nueva?

**Antes de tocar código**, cada vez que el usuario pida trabajo (un bug, una feature, un arreglo) en un repo con `.claude/board.json`, mira si ya hay tarjeta. Cuesta una llamada y evita los dos fallos típicos: duplicar tarjetas y trabajar fuera del tablero.

1. **Busca** entre los items que no estén cerrados:
   ```bash
   gh project item-list <num> --owner <owner> --limit 60 --format json \
     --jq '.items[] | select(.status != "En producción") | "\(.status)\t\(.content.number // "-")\t\(.content.title // .title)"'
   ```
   Compara por **significado**, no por literal: "no puedo continuar la carrera" y "se pierde el entreno al minimizar" son la misma tarjeta. Si dudas, abre el body y léelo.
2. **Si existe** → muévela a *En curso* y dile al usuario por dónde iba (según el checklist de su body). Si lo que pide es sólo una parte de esa tarjeta, dilo en vez de darla entera por empezada.
3. **Si NO existe** → **créala antes de empezar**, con Priority y Area, y déjala en *En curso*. El body inicial es el encargo con las palabras del usuario (si es un bug, sus pasos de reproducción tal cual: es la fuente de verdad, no la reescribas).
4. **Si encaja en varias**, o no está claro si es tarjeta nueva o parte de una existente → pregunta en una línea y sigue trabajando; no bloquees por esto.

**No crees tarjeta para todo.** Un typo, renombrar una variable, responder una pregunta, explorar o depurar sin entregable no van al tablero. La regla práctica: **si va a acabar en un commit o el usuario va a revisarlo, merece tarjeta**; si no, no.

## 3) AL TERMINAR un flujo — actualizar
Cuando cierres/avances una unidad de trabajo:
1. **Mueve la tarjeta** de columna (ver flujo abajo).
2. **Actualiza su body** (Markdown) reflejando qué se hizo / dónde quedó / qué falta (usa checklists `- [ ]`).
3. **Crea items nuevos** si surgió trabajo colateral, con Priority y Area.
4. **Di qué NO cubre** lo hecho (techo conocido, casos sin cubrir) en el body: es lo primero que se olvida y lo que más duele después.

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

### Drafts vs issues — un board mezcla los dos
Un item es **draft** (nació en el board) o un **issue** del repo. Se distingue en el JSON: `content.number` no nulo → es issue.

| | Draft | Issue |
|---|---|---|
| Crear | `gh project item-create <num> --owner <owner> --title … --body …` | `gh issue create --title … --body-file …` + `gh project item-add <num> --owner <owner> --url <url>` |
| Título / body | `gh project item-edit --id <DI_…> --title … --body …` | `gh issue edit <n> --title … --body …` |
| Añadir hallazgos | reescribir el body | **`gh issue comment <n> --body-file <f>`** — mejor que editar: no pisas el reporte original del usuario y queda la cronología |
| Estado / priority / area | `gh project item-edit --id <PVTI_…> --field-id …` | igual, con el **item id** `PVTI_…` (no el número del issue) |
| Cerrar | mover a *Hecho* | `Closes #n` en el commit cierra el issue, pero **la tarjeta no se mueve sola** si renombraste las columnas (el workflow integrado apunta a option ids que cambiaron) → muévela tú y compruébalo |

Cuál usar: si el trabajo acaba en un commit, **issue** (se enlaza con `Closes #n` y queda trazado desde el código); si es gestión (deploy, credenciales, decisión, recordatorio), **draft**.

**IDs — OJO (gotcha clave):**
- Editar **estado / priority / area** usa el **item id** (`PVTI_…`, campo `.id`).
- Editar **título / body de un draft** usa el **content id** (`DI_…`, campo `.content.id`).

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
