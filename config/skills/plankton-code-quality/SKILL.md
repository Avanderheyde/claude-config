---
name: plankton-code-quality
description: "Write-time code quality enforcement using Plankton - auto-formatting, linting, and Claude-powered fixes on every file edit via hooks."
origin: community
---

# Plankton Code Quality Skill

Integration reference for Plankton (credit: @alxfazio), a write-time code quality enforcement system for Claude Code.

## When to Use

- You want automatic formatting and linting on every file edit
- You need defense against agents modifying linter configs to pass instead of fixing code
- You want tiered model routing for fixes (Haiku for style, Sonnet for logic, Opus for types)

## Three-Phase Architecture

Every time Claude Code edits or writes a file, the PostToolUse hook runs:

```
Phase 1: Auto-Format (Silent)
  Runs formatters (ruff format, biome, shfmt, taplo, markdownlint)

Phase 2: Collect Violations (JSON)
  Runs linters and collects unfixable violations as structured JSON

Phase 3: Delegate + Verify
  Spawns claude -p subprocess with violations JSON
  Routes to model tier based on violation complexity:
    Haiku: formatting, imports, style
    Sonnet: complexity, refactoring
    Opus: type system, deep reasoning
```

## ECC Quality Gate (Built-in)

The installed quality-gate.js hook provides a lightweight version:
- JS/TS/JSON/MD: Biome (preferred) or Prettier
- Go: gofmt
- Python: ruff

Enable auto-fix: `export ECC_QUALITY_GATE_FIX=true`
Enable strict mode: `export ECC_QUALITY_GATE_STRICT=true`

## Full Plankton Setup

For the full Plankton experience with subprocess delegation:

```bash
git clone https://github.com/alexfazio/plankton.git
cd plankton
brew install jaq ruff uv
uv sync --all-extras
```

Then copy `.claude/hooks/` from plankton to your project.

## Config Protection

Plankton blocks LLMs from modifying linter configs to suppress violations:
- PreToolUse hook blocks edits to `.ruff.toml`, `biome.json`, `.shellcheckrc`, etc.
- Stop hook detects config changes via `git diff`
