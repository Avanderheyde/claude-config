# Claude Code Config

Personal Claude Code setup: settings, hooks, plugins, commands, skills, and MCP servers.

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
12 custom slash commands: `/checkpoint`, `/verify`, `/diff-review`, `/learn`, `/project-recap`, `/generate-slides`, `/generate-visual-plan`, `/generate-web-diagram`, `/fact-check`, `/plan-review`, `/learn-eval`, `/goal`

### Skills (`skills/`)
- **plankton-code-quality**: write-time code quality enforcement reference
- **portless**: named local dev server URLs
- **last-90**: the production-readiness pass after a first deploy (authz, monitoring, backups, CI/CD, legal)
- **vps-saas**: ship a SaaS on one locked-down VPS (levels.io method)
- **seo-setup**: verification-first technical SEO setup
- **design-elevate**: give a generic-looking web app a real visual identity

### Workflow stack: gstack + Matt Pocock + pstack
Each tool has one job, and duplicates are removed or disabled.

**gstack** ([garrytan/gstack](https://github.com/garrytan/gstack)), cloned to `~/.claude/skills/gstack/`, provides sprint *roles*:

| Phase | Skills |
|---|---|
| Think | `/office-hours`, `/plan-ceo-review`, `/plan-eng-review`, `/plan-design-review`, `/autoplan` |
| Build | `/design-consultation`, `/design-review`, `/careful`, `/freeze`, `/guard`, `/unfreeze` |
| Review | `/review` (pre-landing), `/cso` (OWASP+STRIDE security audit) |
| Test | `/qa`, `/qa-only`, `/browse`, `/benchmark`, `/canary` |
| Ship | `/ship`, `/land-and-deploy`, `/document-release` |
| Reflect | `/retro` |
| Debug | `/investigate` |

**Matt Pocock skills** ([mattpocock/skills](https://github.com/mattpocock/skills)), cloned to `~/.claude/vendor/mattpocock-skills/` with `engineering` and `productivity` symlinked into `~/.claude/skills/`, provide engineering discipline: `/tdd`, `/grilling`, `/grill-with-docs`, `/codebase-design`, `/domain-modeling`, `/to-prd`, `/to-issues`, `/implement`, `/triage`, `/handoff`, and more. `grill-me` (an alias of `/grilling`) and `diagnosing-bugs` (duplicates `/investigate`) are skipped.

**pstack** ([cursor/plugins](https://github.com/cursor/plugins/tree/main/pstack), MIT) is poteto's rigor toolkit, converted from Cursor to Claude Code in `vendor/pstack-claude/`. Start with `/pstack:poteto-mode`. Model routing uses `<model>@<effort>` entries in `~/.claude/pstack-models.md` (`/pstack:setup-pstack`). Its `tdd`, `teach`, `recall`, and `automate-me` skills are dropped as duplicates.

**Code review roles:** built-in `/code-review` (any diff or PR), gstack `/review` (pre-landing, part of `/ship`), and pstack `interrogate` (multi-model, inside poteto-mode).

**Shared agent skills** live in `~/.agents/skills/`, installed with `npx skills add`. Codex, Cursor, and Copilot read the same folder. Sources: impeccable, emilkowalski/skills, make-interfaces-feel-better, remotion, vercel-labs/skills, herdr.

### Plugins (60+)
`setup.sh` installs every plugin that `config/settings.json` enables, from 8 marketplaces (7 on GitHub plus the bundled pstack).

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
- `visual-explainer` and `resy` skills: their own git repos, cloned by `setup.sh`
- `vliw-kernel-optimization.md`: project-specific skill
- Private skills that name private repos or projects, and auto-mode rules that name hosts or keys: kept local only
- Hooks installed by other tools (herdr): those tools reinstall them
