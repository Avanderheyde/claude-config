# Pre-landing Review

Run gstack's `/review` skill on the current branch, then record completion.

## Instructions

1. **Run the gstack review skill**
   Invoke the `/review` skill from gstack. This analyzes the diff against the base branch for:
   - SQL safety issues
   - LLM trust boundary violations
   - Conditional side effects
   - Completeness gaps
   - Auto-fixable issues

2. **Drop the review marker**
   After the review completes, run:
   ```bash
   node "$HOME/.claude/hooks/scripts/hooks/drop-marker.js" review
   ```
   This records that `/review` was run on this branch so the pre-push reminder won't nag.

## Arguments

$ARGUMENTS is passed to the review skill. Common usage:
- (no args) — review current branch diff
- `--quick` — abbreviated review
