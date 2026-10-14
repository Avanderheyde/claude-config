#!/bin/bash
# Mirror the Claude Code setup into Codex. Run after ../setup.sh. Idempotent.
# Skills are symlinked, not copied, so one copy serves both tools.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
CODEX_SKILLS="$CODEX_DIR/skills"

command -v codex >/dev/null || { echo "codex CLI not found"; exit 1; }
mkdir -p "$CODEX_SKILLS"

link() { # link <source dir> <name>: never replace a real directory
  local src="$1" dest="$CODEX_SKILLS/$2"
  [ -e "$src/SKILL.md" ] || return 0
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "  skip $2: $dest is a real directory"; return 0
  fi
  ln -sfn "$src" "$dest"
}

echo "=== Instructions: ~/.codex/AGENTS.md -> ~/.claude/CLAUDE.md ==="
if [ -e "$CODEX_DIR/AGENTS.md" ] && [ ! -L "$CODEX_DIR/AGENTS.md" ]; then
  echo "  skip: $CODEX_DIR/AGENTS.md exists and is not a link"
else
  ln -sfn "$CLAUDE_DIR/CLAUDE.md" "$CODEX_DIR/AGENTS.md"
fi

echo "=== Skills ==="
# ~/.agents/skills is already read by Codex directly.
# Matt Pocock skills, same selection as setup.sh.
for skill in "$CLAUDE_DIR"/vendor/mattpocock-skills/skills/{engineering,productivity}/*/; do
  name="$(basename "$skill")"
  # ask-matt and resolving-merge-conflicts are turned off in Claude (unused).
  case "$name" in grill-me|diagnosing-bugs|ask-matt|resolving-merge-conflicts) continue ;; esac
  link "${skill%/}" "$name"
done
# Custom skills from this repo, plus standalone skill repos.
for skill in "$SCRIPT_DIR"/../config/skills/*/; do
  name="$(basename "$skill")"
  case "$name" in plankton-code-quality) continue ;; esac  # turned off in Claude too
  link "$CLAUDE_DIR/skills/$name" "$name"
done
for name in visual-explainer resy; do link "$CLAUDE_DIR/skills/$name" "$name"; done

echo "=== Slash commands -> skills ==="
# Codex has no custom-command folder, so each command becomes a skill.
# Skipped: goal (Codex has a built-in /goal), learn and learn-eval
# (they write Claude-specific skill files).
python3 - "$SCRIPT_DIR/../config/commands" "$CODEX_SKILLS" <<'EOF'
import os, re, sys
src, dest = sys.argv[1], sys.argv[2]
skip = {"goal", "learn", "learn-eval"}
for f in sorted(os.listdir(src)):
    name = f[:-3]
    if not f.endswith(".md") or name in skip:
        continue
    text = open(os.path.join(src, f)).read()
    desc = ""
    m = re.match(r"---\n(.*?)\n---\n", text, re.S)
    if m:
        d = re.search(r"^description:\s*(.+)$", m.group(1), re.M)
        desc = d.group(1).strip() if d else ""
        text = text[m.end():]
    if not desc:
        h = re.search(r"^#\s*(.+)$", text, re.M)
        desc = (h.group(1) if h else name).strip()
    desc = desc.strip("\"'").replace('"', "'")
    text = text.replace("$ARGUMENTS", "the user's request").replace("$@", "the user's request")
    out = os.path.join(dest, name)
    if os.path.exists(out) and not os.path.exists(os.path.join(out, ".from-claude-command")):
        print(f"  skip {name}: a different skill already uses that name")
        continue
    os.makedirs(out, exist_ok=True)
    open(os.path.join(out, ".from-claude-command"), "w").close()
    with open(os.path.join(out, "SKILL.md"), "w") as fh:
        fh.write(f'---\nname: {name}\ndescription: "{desc} (Use when the user asks for /{name}.)"\n---\n\n{text.lstrip()}')
    print(f"  {name}")
EOF

echo "=== gstack ==="
if [ -x "$CLAUDE_DIR/skills/gstack/setup" ]; then
  (cd "$CLAUDE_DIR/skills/gstack" && ./setup --host codex) || echo "  gstack codex setup failed; rerun it from $CLAUDE_DIR/skills/gstack"
fi

echo "=== pstack (Codex plugin + agent roles) ==="
PSTACK_DIR="$CLAUDE_DIR/vendor/pstack-claude"
if [ -d "$PSTACK_DIR/.agents/plugins" ]; then
  codex plugin marketplace add "$PSTACK_DIR" >/dev/null 2>&1 || true
  codex plugin add pstack@pstack-claude >/dev/null 2>&1 || echo "  pstack plugin install failed; try: codex plugin add pstack@pstack-claude"
  # Codex custom agents: a role TOML per pstack agent, registered in config.toml.
  mkdir -p "$CODEX_DIR/agents"
  python3 - "$PSTACK_DIR/plugins/pstack/agents" "$CODEX_DIR" <<'PY'
import json, os, re, sys
src, codex = sys.argv[1], sys.argv[2]
cfg_path = os.path.join(codex, "config.toml")
cfg = open(cfg_path).read() if os.path.exists(cfg_path) else ""
for f in sorted(os.listdir(src)):
    if not f.endswith(".md"):
        continue
    fm, body = open(os.path.join(src, f)).read().split("---", 2)[1:]
    name = "pstack_" + re.search(r"^name:\s*(\S+)", fm, re.M).group(1).replace("-", "_")
    desc = re.search(r"^description:\s*(.+)$", fm, re.M).group(1).strip()
    role = os.path.join(codex, "agents", name + ".toml")
    open(role, "w").write("developer_instructions = " + json.dumps(body.strip()) + "\n")
    if not re.search(rf"^\[agents\.{name}\]", cfg, re.M):
        with open(cfg_path, "a") as fh:
            fh.write(f"\n[agents.{name}]\ndescription = {json.dumps(desc)}\nconfig_file = {json.dumps(role)}\n")
    print("  role:", name)
PY
fi

echo "=== MCP servers ==="
# Local stdio server: no sign-in needed (the hosted URL requires OAuth).
codex mcp get context7 >/dev/null 2>&1 || codex mcp add context7 -- npx -y @upstash/context7-mcp

echo "Done. Start a new Codex session to load the changes."
