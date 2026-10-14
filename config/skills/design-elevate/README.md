# design-elevate

An [Agent Skill](https://code.claude.com/docs/en/skills) that turns a functional-but-generic web app into one with a real, non-"vibe-coded" visual identity.

Use it when a site "looks AI-generated", "looks like every other SaaS", or needs a serious design pass. It does **not** invent a house style — it establishes a real identity for *your* product and enforces it ruthlessly, through:

- **A token-first `DESIGN.md`** as the single source of truth (typography roles, one rationed accent, content-encoding law, a decisions log that stops re-litigation).
- **A variant-board approval loop** — 3–4 genuinely distinct directions as real HTML mockups (not AI images), screenshotted and rated before a single line of app code changes.
- **Per-page pass pipelines** — an ordered hit-list (type → layout → color → motion → feel → polish → review gates) mapped onto the best available design skills.
- **A curated research source map** — where to steal *structure* (never visuals) per surface type, and which galleries are slop vectors to avoid.
- **Zero-tolerance anti-patterns** — a mechanically auditable list of AI-design tells, re-audited as the tell-list moves.

## This is an aggregator, not an original work

The core of this skill is curation: it orchestrates other people's skills, references, and writing into one repeatable pipeline. Every borrowed technique is cited inline, and all sources are listed in [SKILL.md → Sources & Credits](SKILL.md#sources--credits). If you add a technique from elsewhere, cite it — uncredited borrowing is a bug.

Highlights of what it builds on: [impeccable.style](https://impeccable.style)'s core design suite, [Emil Kowalski's motion skills](https://github.com/emilkowalski/skills), [Jakub Krehel's micro-craft pass](https://github.com/jakubkrehel/make-interfaces-feel-better), [Vercel's react-best-practices](https://github.com/vercel-labs/agent-skills), [Addy Osmani's web-quality budgets](https://github.com/addyosmani/web-quality-skills), [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill), and the galleries and references in the source map.

## Install

```bash
npx skills add Avanderheyde/design-elevate
```

Or copy `SKILL.md` into your agent's skills directory, e.g. for Claude Code:

```bash
mkdir -p ~/.claude/skills/design-elevate
curl -o ~/.claude/skills/design-elevate/SKILL.md \
  https://raw.githubusercontent.com/Avanderheyde/design-elevate/main/SKILL.md
mkdir -p ~/.claude/skills/design-elevate/references
curl -o ~/.claude/skills/design-elevate/references/beautiful-ui.md \
  https://raw.githubusercontent.com/Avanderheyde/design-elevate/main/references/beautiful-ui.md
curl -o ~/.claude/skills/design-elevate/references/generative-loaders.md \
  https://raw.githubusercontent.com/Avanderheyde/design-elevate/main/references/generative-loaders.md
curl -o ~/.claude/skills/design-elevate/references/departure-mono.md \
  https://raw.githubusercontent.com/Avanderheyde/design-elevate/main/references/departure-mono.md
```

The skill references companion skills it orchestrates when they're available — see [SKILL.md → One-time setup](SKILL.md#one-time-setup-adopted-externals) for the recommended installs. It degrades gracefully when they're absent, but the per-page pass table works best with the full set.

## License

[MIT](LICENSE) for the text of this skill. The external skills, galleries, and references it points to remain under their own authors' licenses and terms.
