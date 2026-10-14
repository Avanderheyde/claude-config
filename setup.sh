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
for skill in "$SCRIPT_DIR/config/skills/"*/; do
  name="$(basename "$skill")"
  mkdir -p "$CLAUDE_DIR/skills/$name"
  cp -R "$skill". "$CLAUDE_DIR/skills/$name/"
done

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
  "https://github.com/tobi/qmd.git"
)
for mp in "${marketplaces[@]}"; do
  echo "  Adding marketplace: $mp"
  claude plugin marketplace add "$mp" 2>/dev/null || true
done

# pstack (poteto's Cursor plugin, converted for Claude Code) ships in this repo.
PSTACK_DIR="$CLAUDE_DIR/vendor/pstack-claude"
mkdir -p "$CLAUDE_DIR/vendor"
rsync -a --delete --exclude .git "$SCRIPT_DIR/vendor/pstack-claude/" "$PSTACK_DIR/"
claude plugin marketplace add "$PSTACK_DIR" 2>/dev/null || true

# Install every plugin that settings.json enables, so the two never drift.
echo ""
echo "Installing enabled plugins from settings.json..."
python3 -c 'import json,sys; [print(k) for k,v in json.load(open(sys.argv[1]))["enabledPlugins"].items() if v]' \
  "$SCRIPT_DIR/config/settings.json" | while read -r plugin; do
  echo "  Installing: $plugin"
  claude plugin install "$plugin" 2>/dev/null || true
done

echo ""
echo "=== Installing MCP Servers ==="

echo "Adding Firecrawl MCP (web scraping to markdown)..."
claude mcp add firecrawl --scope user -- npx -y firecrawl-mcp 2>/dev/null || true

echo "Adding Upstash MCP (Redis/rate limiting)..."
claude mcp add upstash --scope user -- npx -y @upstash/mcp-server 2>/dev/null || true

echo ""
echo "=== Installing gstack (full 28-skill sprint toolkit) ==="

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
  echo "Running gstack setup (build + register skills)..."
  (cd "$GSTACK_DIR" && ./setup) || echo "  gstack setup failed — install bun (https://bun.sh) and re-run"
else
  echo "  WARNING: bun not found. gstack /browse and /qa need bun."
  echo "  Install bun: curl -fsSL https://bun.sh/install | bash"
  echo "  Then run: cd $GSTACK_DIR && bun install && bun run build"
fi

echo ""
echo "gstack installed — 28 skills available. Key commands:"
echo "  Sprint:   /office-hours → /plan-ceo-review → /plan-eng-review → /plan-design-review"
echo "  Build:    /review → /qa → /cso → /ship → /land-and-deploy → /canary"
echo "  Tools:    /browse /investigate /retro /benchmark /design-review /document-release"
echo "  Safety:   /careful /freeze /guard /unfreeze"
echo ""

echo ""
echo "=== Installing Matt Pocock skills ==="
MATT_DIR="$CLAUDE_DIR/vendor/mattpocock-skills"
if [ -d "$MATT_DIR/.git" ]; then
  git -C "$MATT_DIR" pull --ff-only 2>/dev/null || true
else
  git clone https://github.com/mattpocock/skills.git "$MATT_DIR"
fi
# grill-me only aliases /grilling; diagnosing-bugs duplicates gstack /investigate.
for skill in "$MATT_DIR"/skills/engineering/*/ "$MATT_DIR"/skills/productivity/*/; do
  name="$(basename "$skill")"
  case "$name" in grill-me|diagnosing-bugs) continue ;; esac
  ln -sfn "$skill" "$CLAUDE_DIR/skills/$name"
done

echo ""
echo "=== Installing shared agent skills (~/.agents/skills, also read by Codex) ==="
agent_skills=(
  "pbakaus/impeccable"
  "emilkowalski/skills"
  "jakubkrehel/make-interfaces-feel-better"
  "remotion-dev/skills"
  "vercel-labs/skills"
  "herdrdev/herdr"
)
for src in "${agent_skills[@]}"; do
  echo "  Adding: $src"
  npx -y skills add "$src" -g -y 2>/dev/null || true
done

echo ""
echo "=== Installing standalone skill repos ==="
for repo in "nicobailon/visual-explainer" "Avanderheyde/resy-skills"; do
  name="$(basename "$repo")"; [ "$name" = "resy-skills" ] && name="resy"
  dest="$CLAUDE_DIR/skills/$name"
  if [ -d "$dest/.git" ]; then git -C "$dest" pull --ff-only 2>/dev/null || true
  else git clone "https://github.com/$repo.git" "$dest"; fi
done

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
