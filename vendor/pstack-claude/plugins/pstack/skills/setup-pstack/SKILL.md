---
name: setup-pstack
description: Configure which models pstack uses per role and at what reasoning budget. Writes ~/.claude/pstack-models.md, which overrides the skill defaults. Use for /setup-pstack, "configure pstack models", "pstack budget", or changing pstack's model choices.
---

# Setup pstack

**Loading other pstack skills.** pstack skills are hidden from the Skill tool. When this skill names another pstack skill, Read `../<name>/SKILL.md` from this skill's base directory (shown when it loaded). A principle named **x** lives at `../principle-x/SKILL.md`. In Codex, translate Claude Code tool names with the **Running in Codex** table in `../poteto-mode/SKILL.md`.

Write `~/.claude/pstack-models.md`, the file that sets pstack's model per role. pstack skills read it before they spawn a subagent.

## Model entries

An entry is `<model>@<effort>`. `<model>` is a value the Agent tool's `model` parameter accepts: `opus`, `sonnet`, `haiku`, or `fable`. `<effort>` is a value its `effort` parameter accepts, on the ladder `max` > `xhigh` > `high` > `medium` > `low`. A spawn for `opus@xhigh` passes `model: "opus"` and `effort: "xhigh"`. The alias `inherit-parent` means the role runs on the parent chat model and effort, so the spawn omits both parameters. `auto` is an older name for the same alias. Codex reads the same file but cannot run Claude models, so in Codex only the effort part of an entry applies (see **Running in Codex** in `../poteto-mode/SKILL.md`).

## Steps

### 1. Load current state

The default role-to-model mapping is the file shape in step 4. If `~/.claude/pstack-models.md` already exists, read it and treat its `# budget` line and its role values as the current choices. Otherwise start from those defaults. A line whose role is not in step 4, such as `how critics`, is from a retired role. Drop it.

### 2. Budget, map, and confirm

**(a) Ask for a budget.** Use AskUserQuestion. Offer these four options with these exact labels, and name the current budget when the file records one. With no file, say that `large` matches the skill defaults.

- `unlimited — max reasoning`
- `large — xhigh reasoning`
- `medium — high reasoning`
- `small — medium reasoning`

**(b) Apply it.** Build the working table from the skill defaults, and on a re-run keep any role you changed by model, list, or alias. `unlimited`, `large`, `medium`, and `small` set the effort of every entry, panel entries included, to `max`, `xhigh`, `high`, or `medium`. Aliases do not change. So `unlimited` turns `opus@xhigh` into `opus@max`, and `small` turns the defaults into `opus@medium` and `sonnet@medium`.

**(c) Show the roles and confirm.** Show every role with its entry. Also list each line step 1 dropped. Ask whether to accept as-is or change specific roles, offering `opus`, `sonnet`, `haiku`, `fable`, and `inherit-parent`. Use AskUserQuestion. For panel roles (arena runners, architect runners, interrogate reviewers) the value is a list, and one subagent runs per entry, alias entries included, so the list length sets the count. Keep at least two different models in a panel so its reviewers disagree for real. `arena cross-judge pool` is also a list, but Arena selects one value from it whose model differs from the parent's when possible. `swarm workers` is the default model for every worker unless a race or comparison assigns another model per arm.

### 3. Validate

Every entry must be `inherit-parent`, `auto`, or `<model>@<effort>` with a model and effort from the lists above. If one is not, stop and ask again.

### 4. Write the file

Write `~/.claude/pstack-models.md` with a `# budget` line with the chosen label and its target effort, and one line per role, using the same labels poteto-mode uses. Overwrite the whole file so re-runs stay idempotent. Shape:

```
# pstack model configuration. One line per role. Delete a line to fall back to the skill default.
# Entry: <model>@<effort> → Agent `model` and `effort`. `inherit-parent`: omit both. Alias entries in a panel list still count toward its fan-out.
# budget: large (xhigh)
feature, refactoring: sonnet@xhigh
bug-fix: sonnet@xhigh
perf-issue: sonnet@xhigh
hillclimb: sonnet@xhigh
judgment and prose: opus@xhigh
hardest tasks: opus@xhigh
how explorer: sonnet@xhigh
how explainer: opus@xhigh
why investigators: sonnet@xhigh
why synthesizer: opus@xhigh
reflect tooling: sonnet@xhigh
reflect judgment, divergent, synthesizer: opus@xhigh
arena runners: opus@xhigh, sonnet@xhigh
arena cross-judge pool: opus@xhigh, sonnet@xhigh
swarm workers: sonnet@xhigh
architect runners: opus@xhigh, sonnet@xhigh
interrogate reviewers: opus@xhigh, sonnet@xhigh
```

### 5. Confirm

Tell the user the file was written and that pstack skills read it on their next spawn. Re-running this skill updates it.

### 6. Offer a verification skill (optional)

Check whether the project has a way to drive the real app for proof (a `verify-*` skill, or an existing harness). If not, offer once: "want a project-local verification skill, so agents can drive the app the way a user does and prove changes work? I can generate one with /create-verification-skill." On yes, invoke `/create-verification-skill`. On no, move on without pushing.
