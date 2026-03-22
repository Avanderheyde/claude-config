---
description: Extract reusable patterns from the session, self-evaluate quality before saving, and determine the right save location (Global vs Project).
---

# /learn-eval - Extract, Evaluate, then Save

Extends `/learn` with a quality gate and save-location decision before writing any skill file.

## What to Extract

Look for:

1. **Error Resolution Patterns** - root cause + fix + reusability
2. **Debugging Techniques** - non-obvious steps, tool combinations
3. **Workarounds** - library quirks, API limitations, version-specific fixes
4. **Project-Specific Patterns** - conventions, architecture decisions, integration patterns

## Process

1. Review the session for extractable patterns
2. Identify the most valuable/reusable insight

3. **Determine save location:**
   - Ask: "Would this pattern be useful in a different project?"
   - **Global** (`~/.claude/skills/learned/`): Generic patterns usable across 2+ projects
   - **Project** (`.claude/skills/learned/` in current project): Project-specific knowledge
   - When in doubt, choose Global

4. Draft the skill file using this format:

```markdown
---
name: pattern-name
description: "Under 130 characters"
user-invocable: false
origin: auto-extracted
---

# [Descriptive Pattern Name]

**Extracted:** [Date]
**Context:** [Brief description of when this applies]

## Problem
[What problem this solves - be specific]

## Solution
[The pattern/technique/workaround - with code examples]

## When to Use
[Trigger conditions]
```

5. **Self-evaluate before saving** using this rubric:

   | Dimension | 1 | 3 | 5 |
   |-----------|---|---|---|
   | Specificity | Abstract principles only | Representative code example | Rich examples covering all patterns |
   | Actionability | Unclear what to do | Main steps understandable | Immediately actionable, edge cases covered |
   | Scope Fit | Too broad or narrow | Mostly appropriate | Name, trigger, and content aligned |
   | Non-redundancy | Nearly identical to another skill | Some overlap but unique | Completely unique value |
   | Coverage | Covers fraction of task | Main cases covered | Main cases, edge cases, and pitfalls |

   - Score each dimension 1-5
   - If any dimension scores 1-2, improve the draft and re-score until all >= 3
   - Show the user the scores table and the final draft

6. Ask user to confirm before saving
7. Save to the determined location

## Notes

- Don't extract trivial fixes (typos, simple syntax errors)
- Don't extract one-time issues (specific API outages, etc.)
- Focus on patterns that will save time in future sessions
- Keep skills focused - one pattern per skill
