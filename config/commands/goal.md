# Goal Command

Drive the codebase to a stated goal by iterating until three evaluation axes all pass: deterministic checks, code-quality judge, and security judge.

## Usage

`/goal <goal description>`

Example: `/goal Add a /users endpoint that returns the authenticated user's profile, with auth enforced and a passing integration test.`

## Setup (do once at the start)

1. **Check the goal is verifiable.** If the goal is vague ("improve the code", "make it better"), ask ONE clarifying question to make it concrete and verifiable. Example: "What specifically counts as 'better' — a benchmark, a missing feature, or something else?" Then proceed.

2. **Auto-detect deterministic check commands** based on what's in the repo root:
   - `go.mod` → `go test ./... -count=1`, `go vet ./...`, `go build ./...`
   - `package.json` → read `scripts`, run any of `test`, `lint`, `typecheck`, `build` that exist
   - `Cargo.toml` → `cargo test`, `cargo clippy -- -D warnings`, `cargo build`
   - `pyproject.toml` → `pytest`, `ruff check .`, `mypy .` (only if configured)
   - Mixed/none → ask the user once, remember for the session

3. **Establish baseline.** Run the deterministic checks once before any changes. If anything fails on baseline, note it — your changes must not make those failures worse, but you don't have to fix pre-existing failures unless they relate to the goal.

4. **Set up tracking** via TaskCreate:
   - Task: "Iteration 1 — implement"
   - Task: "Iteration 1 — deterministic checks"
   - Task: "Iteration 1 — judge review"
   Add tasks for additional iterations as needed. Hard cap: 10 iterations.

## The Loop

For each iteration (1 through 10):

### A. Implement
- **Iteration 1:** make the changes you believe meet the goal.
- **Iteration 2+:** address the specific issues raised by judges in the previous iteration. Fix the most critical (security > implementation gaps > quality) first.

### B. Deterministic checks (must pass to advance)
Run every detected check command. If any fails:
- Read the failure
- Fix the root cause, not the symptom
- Re-run until all pass
- If the same check fails 3 times in a row, STOP and escalate — you're spinning

### C. Dispatch three judges in parallel
Use the Agent tool in a **single message** with three Agent calls (general-purpose subagents) so they run concurrently. Give each:
- The goal verbatim
- The git diff for this iteration: `git diff <iteration-start-sha>..HEAD`
- The specific criteria block (below) for that judge

Each judge returns `APPROVE` or `REQUEST_CHANGES` with a specific bullet list of issues including file:line refs.

### D. Decide
- **All three APPROVE** → done. Skip to "Final Report" below.
- **Any REQUEST_CHANGES** → start the next iteration with the union of issues. Commit current state before starting iteration N+1 (so progress is reversible).
- **Iteration count > 10** → STOP, write a "Stopped" report (below), ask the user how to proceed.

---

## Judge Criteria

### Judge 1: Implementation Completeness

Evaluates whether the changes actually achieve the goal.

**APPROVE if:**
- The goal as stated is met (every reasonable interpretation)
- Edge cases implied by the goal are handled
- Changes solve the user-visible problem, not just a symptom
- At least one test exists that would catch regression of this specific goal

**REQUEST_CHANGES if:**
- The goal is partially met — list exactly what's missing
- Changes solve a different problem than what was asked
- No test verifies the goal-relevant behavior
- Required wiring is missing (e.g., goal mentions an endpoint, but it's not routed)
- A claim in the implementation report is unverifiable from the diff

### Judge 2: Code Quality

Evaluates maintainability, readability, and scope discipline.

**APPROVE if:**
- Names accurately describe what things do (not how they're implemented, not vague like "data" or "handler")
- Each file and function has one clear responsibility
- Code follows the EXISTING patterns in this codebase — don't enforce your own preferences over what's already there
- No speculative abstractions, no premature flexibility, no commented-out code
- No unrelated changes ("while I was here, I also refactored…")
- Tests verify behavior, not implementation details (no asserting on private internals)
- No comments that just narrate what the code already says

**REQUEST_CHANGES if:**
- Any of the above is violated
- A new file or function is added that has only one caller and adds indirection rather than clarity
- Pre-existing code was modified beyond what the goal required

### Judge 3: Security

Evaluates against common vulnerability classes and basic hygiene.

**APPROVE if:**
- User input is validated/escaped at trust boundaries (HTTP body, query params, headers, file uploads, env vars from external sources)
- No secrets in code (passwords, API keys, tokens, private keys, JWT signing keys)
- Secrets are loaded from env, secrets manager, or config — never hardcoded
- Authentication checked where needed; authorization checked SEPARATELY from authentication (logged-in ≠ allowed)
- SQL uses parameterized queries — no string interpolation of user input into queries
- Shell commands don't interpolate untrusted input
- File paths from user input are sanitized (path traversal prevented)
- HTTP responses don't echo user input as HTML without escaping
- Errors returned to clients don't leak sensitive info (stack traces, internal paths, secrets in messages)
- New dependencies are from reputable sources, version-pinned, no known critical CVEs
- Any auth/authz code change is covered by a test that proves the new path is enforced

**REQUEST_CHANGES if:**
- Any of the above is violated — cite file:line and the specific vulnerability class (e.g., "SQL injection at db.go:42 — user.Name is interpolated into query string")
- A secret appears in code, logs, or test fixtures
- A new external dependency was added without a clear reason

---

## Reporting

### Per-iteration status (one line)
```
Iter N: deterministic ✅ | impl ✅ | quality ❌ (3 issues) | security ✅
```

### Final success
```
✅ Goal complete after N iterations
   Goal: <goal>
   Changed: M files, +X / −Y LOC
   Tests: Z passing (W new this run)
   Commits: <sha>..<sha>
```

### Stopped (iteration cap or stuck)
```
⏸ Stopped at iteration N
   Open issues:
   - [bullet list of unresolved judge feedback]
   - [any deterministic check that wouldn't clear]
   Suggested next step: <your honest read of what's needed>
```

---

## Rules

- **Never skip deterministic checks** to make a judge happy
- **Never skip judges** even if you're confident the change is fine
- **Never modify the goal mid-loop** unless the user explicitly says so
- **Always commit between iterations** — each iteration produces one commit so progress is reversible via `git reset`
- **One issue category per fix attempt** — don't try to address security + quality + impl gaps in one shot; fix the highest-priority first, re-judge, repeat
- **Judges must be fresh subagents** — never let your own context evaluate the work, dispatch new agents so they read the diff cold
- **If you hit the iteration cap**, do NOT raise it on your own — stop and ask
