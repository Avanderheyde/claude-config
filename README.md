# Claude Code Config

Personal Claude Code setup — settings, hooks, plugins, commands, skills, and MCP servers.

## Quick Setup

```bash
git clone git@github.com:Avanderheyde/claude-config.git
cd claude-config
./setup.sh
```

## What's Included

### Config Files
- **CLAUDE.md** — Global behavioral guidelines (think before coding, simplicity first, surgical changes)
- **settings.json** — Permissions, hooks, enabled plugins, status line config
- **settings.local.json.example** — Template for machine-specific permissions (nvm paths, MCP tool grants)
- **statusline.sh** — Custom status bar with rate limits, context usage, git info, session timer

### Hooks (`hooks/scripts/`)
- **session-start.js** — Loads previous session context on startup
- **session-end.js** — Persists session summary (tasks, files modified, tools used)
- **quality-gate.js** — Auto-formats/lints files on Edit/Write (Biome/Prettier/ruff/gofmt)
- **suggest-compact.js** — Suggests `/compact` after ~50 tool calls
- **evaluate-session.js** — Signals when sessions have extractable patterns
- **cost-tracker.js** — Tracks token usage and estimated costs to `metrics/costs.jsonl`

### Commands (`commands/`)
11 custom slash commands: `/checkpoint`, `/verify`, `/diff-review`, `/learn`, `/project-recap`, `/generate-slides`, `/generate-visual-plan`, `/generate-web-diagram`, `/fact-check`, `/plan-review`, `/learn-eval`

### Skills (`skills/`)
- **plankton-code-quality** — Write-time code quality enforcement reference
- **portless** — Named local dev server URLs

### Plugins (60+)
Installed from 7 marketplaces — see `setup.sh` for the full list.

### MCP Servers
Installed by `setup.sh`:
- **Firecrawl** — Converts URLs to clean markdown (web scraping, content ingestion)
- **Upstash** — Redis/rate limiting management

Already provided by plugins (no separate install needed):
- Supabase, GitHub, Vercel, Playwright, Chrome DevTools, Context7, Episodic Memory, Notion, Sentry

### Project Templates (`templates/`)
- **claude.json.nextjs-supabase** — Pre-wired `.claude.json` for Next.js + Supabase projects with Supabase MCP and common permissions. Copy to your project root as `.claude.json` and fill in your project ref.

## Post-Setup

### MCP API Keys
Some MCP servers need API keys as environment variables:
```bash
export FIRECRAWL_API_KEY=...          # firecrawl.dev
export UPSTASH_REDIS_REST_URL=...     # upstash.com
export UPSTASH_REDIS_REST_TOKEN=...
```

### Machine-Specific Settings
The setup copies `settings.local.json.example` to `~/.claude/settings.local.json` if none exists. Edit it to add machine-specific paths (e.g., nvm node paths, project-specific tool grants).

## Platform Notes

- **macOS Notification hook** uses `osascript`. On Linux, replace with `notify-send`.
- **statusline.sh** uses BSD `date -j` with GNU `date -d` fallback — works on both macOS and Linux.

## Excluded from Repo
- `statusline-command.sh` — Unused duplicate of statusline logic
- `double-shot-latte` plugin — Was installed but disabled
- Plugin cache (`plugins/cache/`) — Reinstalled by `setup.sh`
- Sessions, metrics, telemetry — Ephemeral runtime data
- `visual-explainer` skill — Has its own git repo, clone separately if needed
- `vliw-kernel-optimization.md` — Project-specific skill
