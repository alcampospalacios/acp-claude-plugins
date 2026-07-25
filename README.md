# acp-claude-plugins

Marketplace personal de plugins de Claude Code (Alejandro Campos Palacios).

---

## Plugin: `github-projects-board`

Gestiona el tablero de **GitHub Projects** (estilo Jira) del proyecto en el que estés trabajando: te resume en qué te quedaste al empezar y actualiza las tarjetas conforme avanzas.

### ¿Se carga solo o hay que invocarlo?

**Las dos cosas** — hay una parte automática y otra manual:

| Modo | Cómo se dispara | Qué hace |
|---|---|---|
| 🟢 **Automático** (hook `SessionStart`) | Al **empezar / reanudar / limpiar** una sesión, **sin que hagas nada** | Si el proyecto tiene `.claude/board.json`, inyecta un resumen del tablero (qué hay En curso / En espera, qué está en Hecho pendiente de tu revisión, y el siguiente Por hacer). Si el proyecto **no** tiene `board.json`, no hace nada. |
| 🔵 **Manual** (comando) | Escribes **`/tablero`** | Fuerza el análisis del tablero en ese momento. |
| 🔵 **Automático por contexto** (skill) | Cuando hablas de *"tablero / kanban / en qué me quedé / actualiza el tablero"* o **terminas una tarea** | El agente aplica el protocolo: mueve las tarjetas (hasta *Hecho*) y actualiza sus detalles. |

> En resumen: **no tienes que hacer nada al empezar** — el resumen sale solo. `/tablero` es solo por si lo quieres a mitad de sesión.

### Reparto de responsabilidades

Flujo de columnas (igual en **todos** los proyectos):

```
Por hacer → En curso → En espera → Hecho → En revisión → En producción
```

- **El agente** mueve las tarjetas hasta **Hecho** (desarrollo terminado).
- **Tú (humano)** mueves **En revisión** → **En producción** (revisión y validación las haces tú). *En producción* es el estado final.

### Requisitos

- **`gh` CLI** instalado y autenticado con scope **`project`**.
  - Si **no** tienes `gh`, el plugin **te avisa al arrancar** con las instrucciones (y el agente te pedirá aprobación antes de instalarlo):
    - macOS: `brew install gh` · Ubuntu/Debian: `sudo apt install gh` · Windows: `winget install GitHub.cli`
    - Luego: `gh auth login -s project -w`
  - Si tienes `gh` pero sin el scope: `gh auth refresh -s project`.
- **`python3`** (lo usa el hook para leer `board.json`; viene de serie en macOS/Linux).

---

## Instalación

Desde GitHub (recomendado):
```
/plugin marketplace add alcampospalacios/acp-claude-plugins
/plugin install github-projects-board@acp-plugins
/reload-plugins
```

O desde una copia local:
```
/plugin marketplace add ~/Develop/acp-claude-plugins
/plugin install github-projects-board@acp-plugins
/reload-plugins
```

### Actualizar a una versión nueva
```
/plugin marketplace update acp-plugins
/plugin update github-projects-board@acp-plugins
/reload-plugins
```
(Si `/plugin update` no aparece: `/plugin uninstall …` y vuelve a instalar.)

---

## Activar el plugin en un proyecto (`board.json`)

El plugin solo actúa en proyectos que tengan un archivo **`.claude/board.json`** en su raíz, que apunta a **su** tablero de GitHub Projects. Ejemplo:

```json
{
  "owner": "<tu-usuario-github>",
  "project_number": 4,
  "project_id": "PVT_...",
  "url": "https://github.com/users/<tu-usuario>/projects/4",
  "fields": {
    "status": {
      "id": "PVTSSF_...",
      "flow": ["Por hacer", "En curso", "En espera", "Hecho", "En revisión", "En producción"],
      "options": {
        "Por hacer": "…", "En curso": "…", "En espera": "…",
        "Hecho": "…", "En revisión": "…", "En producción": "…"
      }
    },
    "priority": { "id": "PVTSSF_...", "options": { "High": "…", "Medium": "…", "Low": "…" } },
    "area": { "id": "PVTSSF_...", "options": { "…": "…" } }
  }
}
```

**La forma fácil:** no lo escribas a mano — pídeselo a Claude en ese proyecto:
> "Configúrame el `board.json` de este proyecto para el plugin github-projects-board" (o "crea el tablero si no existe").

Los `id` de campos/opciones se obtienen con:
```
gh project list --owner <owner>
gh project field-list <num> --owner <owner> --format json
```

> Si cambias/renombras/reordenas columnas por la web, los `option ids` cambian → refresca `board.json`. La skill documenta el procedimiento seguro para hacerlo por API sin perder las asignaciones.

---

## Contenido del plugin

```
github-projects-board/
├── .claude-plugin/plugin.json      # manifiesto
├── skills/github-projects-board/SKILL.md # protocolo + comandos gh + gotchas
├── commands/tablero.md             # comando /tablero
└── hooks/
    ├── hooks.json                  # SessionStart
    └── analyze-board.sh            # analiza el board al arrancar
```
