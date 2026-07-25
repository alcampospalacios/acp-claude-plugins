# acp-claude-plugins

Marketplace personal de plugins de Claude Code (Alejandro Campos Palacios).

## Plugins

### `gestion-tablero`
Gestiona el tablero de **GitHub Projects** (estilo Jira) del proyecto en curso.

- **Hook `SessionStart`** → al empezar cada sesión, si el proyecto tiene `.claude/board.json`, inyecta un resumen del tablero (en qué se estaba, siguiente paso).
- **Skill `gestion-tablero`** → protocolo para analizar al empezar y actualizar al terminar un flujo, con el "cómo" de `gh project` y los gotchas.
- **Comando `/tablero`** → dispara el análisis del tablero manualmente.

Flujo estándar de columnas (homogéneo en todos los proyectos):
`Por hacer → En curso → En espera → Hecho → En revisión → En producción`
El agente mueve hasta *Hecho*; *En revisión* y *En producción* las mueve el usuario.

Cada proyecto define su tablero en `.claude/board.json` (owner, número de proyecto e ids de campos/opciones cacheados).

## Instalación

```
/plugin marketplace add ~/Develop/acp-claude-plugins
/plugin install gestion-tablero@acp-plugins
```

(o, si lo subes a GitHub: `/plugin marketplace add <owner>/acp-claude-plugins`)

## Requisitos
- `gh` CLI autenticado con scope `project`: `gh auth login -s project -w`.
- `python3` (para el hook).

## board.json (por proyecto)
Ejemplo mínimo:
```json
{
  "owner": "<tu-usuario>",
  "project_number": 4,
  "project_id": "PVT_...",
  "fields": {
    "status": { "id": "PVTSSF_...", "flow": ["Por hacer","En curso","En espera","Hecho","En revisión","En producción"], "options": { "Por hacer": "...", "...": "..." } }
  }
}
```
