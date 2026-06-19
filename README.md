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

### Workflow: gstack + Matt Pocock skills
This setup uses **gstack** for sprint *roles* (reviewer, QA lead, security officer) and **Matt Pocock's skills** for engineering *discipline* (TDD, diagnosis, design, triage). The **superpowers** workflow plugins are intentionally not used — gstack + Matt Pocock cover the same ground with smaller, more composable skills.

**gstack** ([garrytan/gstack](https://github.com/garrytan/gstack)) — 28 skills, cloned to `~/.claude/skills/gstack/`:

| Phase | Skills |
|---|---|
| Think | `/office-hours`, `/plan-ceo-review`, `/plan-eng-review`, `/plan-design-review`, `/autoplan` |
| Build | `/design-consultation`, `/design-review`, `/careful`, `/freeze`, `/guard`, `/unfreeze` |
| Review | `/review` (pre-landing), `/cso` (OWASP+STRIDE security audit) |
| Test | `/qa`, `/qa-only`, `/browse`, `/benchmark`, `/canary` |
| Ship | `/ship`, `/land-and-deploy`, `/document-release` |
| Reflect | `/retro` (weekly, cross-project with `/retro global`) |
| Debug | `/investigate` (4-phase RCA, max-3 attempts) |

**Matt Pocock skills** ([mattpocock/skills](https://github.com/mattpocock/skills)) — cloned to `~/.claude/vendor/mattpocock-skills/`, with the `engineering` + `productivity` categories symlinked into `~/.claude/skills/`. Run `/setup-matt-pocock-skills` once to configure issue tracker, labels, and docs location.

| Concern | Skill |
|---|---|
| Test-driven development | `/tdd` |
| Build a feature | `/implement` |
| Diagnose bugs / regressions | `/diagnosing-bugs` |
| Module / interface design | `/codebase-design`, `/improve-codebase-architecture` |
| Domain modeling | `/domain-modeling` |
| Triage & specs | `/triage`, `/to-issues`, `/to-prd` |
| Stress-test a plan | `/grilling`, `/grill-with-docs` |
| Handoff / teaching | `/handoff`, `/teach`, `/writing-great-skills` |

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

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- [Bun](https://bun.sh/) v1.0+ (required for gstack `/browse` and `/qa`)
- Git

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
