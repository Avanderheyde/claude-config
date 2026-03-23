#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "=== Claude Code Config Setup ==="
echo "Target: $CLAUDE_DIR"
echo ""

# Check if claude is installed
if ! command -v claude &>/dev/null; then
  echo "ERROR: claude CLI not found. Install it first:"
  echo "  npm install -g @anthropic-ai/claude-code"
  exit 1
fi

# Backup existing config if present
if [ -f "$CLAUDE_DIR/settings.json" ]; then
  backup="$CLAUDE_DIR/settings.json.backup.$(date +%Y%m%d%H%M%S)"
  cp "$CLAUDE_DIR/settings.json" "$backup"
  echo "Backed up existing settings.json -> $(basename "$backup")"
fi

# Create directories
mkdir -p "$CLAUDE_DIR/hooks/scripts/hooks"
mkdir -p "$CLAUDE_DIR/hooks/scripts/lib"
mkdir -p "$CLAUDE_DIR/commands"
mkdir -p "$CLAUDE_DIR/skills/plankton-code-quality"
mkdir -p "$CLAUDE_DIR/skills/portless"
mkdir -p "$CLAUDE_DIR/skills/learned"
mkdir -p "$CLAUDE_DIR/sessions"
mkdir -p "$CLAUDE_DIR/metrics"

# Copy config files
echo "Copying config files..."
cp "$SCRIPT_DIR/config/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
cp "$SCRIPT_DIR/config/settings.json" "$CLAUDE_DIR/settings.json"
cp "$SCRIPT_DIR/config/statusline.sh" "$CLAUDE_DIR/statusline.sh"
chmod +x "$CLAUDE_DIR/statusline.sh"

# Copy hooks
echo "Copying hooks..."
cp "$SCRIPT_DIR/config/hooks/scripts/hooks/"*.js "$CLAUDE_DIR/hooks/scripts/hooks/"
cp "$SCRIPT_DIR/config/hooks/scripts/lib/"*.js "$CLAUDE_DIR/hooks/scripts/lib/"

# Copy commands
echo "Copying commands..."
cp "$SCRIPT_DIR/config/commands/"*.md "$CLAUDE_DIR/commands/"

# Copy skills
echo "Copying custom skills..."
cp "$SCRIPT_DIR/config/skills/plankton-code-quality/SKILL.md" "$CLAUDE_DIR/skills/plankton-code-quality/"
cp "$SCRIPT_DIR/config/skills/portless/SKILL.md" "$CLAUDE_DIR/skills/portless/"

echo ""
echo "=== Installing Plugins ==="

# Add marketplaces
echo "Adding plugin marketplaces..."
marketplaces=(
  "anthropics/claude-plugins-official"
  "obra/superpowers-marketplace"
  "wshobson/agents"
  "coreyhaines31/marketingskills"
  "Dammyjay93/interface-design"
  "lackeyjb/playwright-skill"
)
for mp in "${marketplaces[@]}"; do
  echo "  Adding marketplace: $mp"
  claude plugins add-marketplace "$mp" 2>/dev/null || true
done

# Install plugins from official marketplace
echo ""
echo "Installing plugins from claude-plugins-official..."
official_plugins=(
  feature-dev frontend-design ralph-loop security-guidance superpowers
  context7 code-review github commit-commands code-simplifier playwright
  Notion vercel supabase sentry typescript-lsp pr-review-toolkit
  claude-md-management notion
)
for plugin in "${official_plugins[@]}"; do
  echo "  Installing: $plugin"
  claude plugins install "$plugin" --marketplace claude-plugins-official 2>/dev/null || true
done

# Install plugins from claude-code-workflows
echo ""
echo "Installing plugins from claude-code-workflows..."
workflow_plugins=(
  api-scaffolding application-performance backend-development cicd-automation
  cloud-infrastructure code-documentation code-refactoring code-review-ai
  codebase-cleanup comprehensive-review context-management database-design
  database-migrations deployment-validation developer-essentials
  documentation-generation error-debugging kubernetes-operations
  observability-monitoring performance-testing-review python-development
  quantitative-trading ui-design conductor debugging-toolkit
  dependency-management deployment-strategies error-diagnostics
  frontend-mobile-development security-compliance security-scanning
)
for plugin in "${workflow_plugins[@]}"; do
  echo "  Installing: $plugin"
  claude plugins install "$plugin" --marketplace claude-code-workflows 2>/dev/null || true
done

# Install plugins from superpowers-marketplace
echo ""
echo "Installing plugins from superpowers-marketplace..."
superpowers_plugins=(
  elements-of-style episodic-memory superpowers superpowers-developing-for-claude-code
)
for plugin in "${superpowers_plugins[@]}"; do
  echo "  Installing: $plugin"
  claude plugins install "$plugin" --marketplace superpowers-marketplace 2>/dev/null || true
done

# Install from other marketplaces
echo ""
echo "Installing plugins from other marketplaces..."
claude plugins install marketing-skills --marketplace marketingskills 2>/dev/null || true
claude plugins install interface-design --marketplace interface-design 2>/dev/null || true

echo ""
echo "=== Installing MCP Servers ==="

echo "Adding Firecrawl MCP (web scraping to markdown)..."
claude mcp add firecrawl --scope user -- npx -y firecrawl-mcp 2>/dev/null || true

echo "Adding Upstash MCP (Redis/rate limiting)..."
claude mcp add upstash --scope user -- npx -y @upstash/mcp-server 2>/dev/null || true

echo ""
echo "=== Installing gstack (cherry-picked skills) ==="

GSTACK_DIR="$CLAUDE_DIR/skills/gstack"
if [ -d "$GSTACK_DIR/.git" ]; then
  echo "gstack already installed, pulling latest..."
  git -C "$GSTACK_DIR" pull --ff-only 2>/dev/null || true
else
  echo "Cloning gstack..."
  git clone https://github.com/garrytan/gstack.git "$GSTACK_DIR"
fi

# Build gstack (requires bun)
if command -v bun &>/dev/null; then
  echo "Building gstack browse binary..."
  (cd "$GSTACK_DIR" && bun install && bun run build) 2>/dev/null || echo "  gstack build failed — install bun (https://bun.sh) and re-run"
else
  echo "  WARNING: bun not found. gstack /browse and /qa need bun."
  echo "  Install bun: curl -fsSL https://bun.sh/install | bash"
  echo "  Then run: cd $GSTACK_DIR && bun install && bun run build"
fi

echo ""
echo "Cherry-picked gstack skills to use:"
echo "  /qa          — QA test your app, find and fix bugs with atomic commits"
echo "  /review      — Pre-landing PR review (SQL safety, LLM trust boundaries)"
echo "  /cso         — OWASP Top 10 + STRIDE security audit"
echo "  /retro       — Weekly engineering retrospective with trends"
echo "  /investigate — Systematic root-cause debugging (no fixes without RCA)"
echo "  /browse      — Headless browser (~100ms/cmd, used by /qa)"

# Copy settings.local.json.example if no local settings exist
if [ ! -f "$CLAUDE_DIR/settings.local.json" ]; then
  echo ""
  echo "No settings.local.json found — copying example."
  cp "$SCRIPT_DIR/config/settings.local.json.example" "$CLAUDE_DIR/settings.local.json"
  echo "Edit ~/.claude/settings.local.json to add machine-specific permissions."
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Notes:"
echo "  - Notification hook uses macOS osascript. On Linux, edit the"
echo "    Notification hook in settings.json to use notify-send instead."
echo "  - Run 'claude' to verify everything works."
echo "  - Plugin install commands may need adjustment if the CLI syntax"
echo "    has changed. Check 'claude plugins --help' if installs fail."
echo "  - Project templates are in templates/ — copy to your project root"
echo "    as .claude.json and fill in project-specific values."
echo "  - MCP servers (Firecrawl, Upstash) may need API keys set as env vars."
echo "    FIRECRAWL_API_KEY, UPSTASH_REDIS_REST_URL, UPSTASH_REDIS_REST_TOKEN"
