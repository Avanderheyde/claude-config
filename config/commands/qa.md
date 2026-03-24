# QA Test

Run gstack's `/qa` skill to test your app in a real browser, then record completion.

## Instructions

1. **Run the gstack QA skill**
   Invoke the `/qa` skill from gstack with the provided URL. This:
   - Opens a real headless browser
   - Navigates your app and finds bugs
   - Fixes bugs with atomic commits
   - Re-verifies each fix
   - Auto-generates regression tests

2. **Drop the QA marker**
   After QA completes, run:
   ```bash
   node "$HOME/.claude/hooks/scripts/hooks/drop-marker.js" qa
   ```
   This records that `/qa` was run on this branch so the pre-push reminder won't nag.

## Arguments

$ARGUMENTS should be the URL to test. Examples:
- `http://localhost:3000` — test local dev server
- `https://staging.myapp.com` — test staging
- (no args) — QA will ask for the URL
