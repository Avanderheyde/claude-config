---
name: last-90
version: 1.0.0
description: "The last 90% of shipping a web app — everything agents skip: authz, monitoring, legal, backups, rate limits, CI/CD, ops. Run it after deploying (the follow-on to vps-saas / levels.io) to make a freshly-launched web app actually safe and set up properly. Goal-driven: keeps working until the launch gate is 10/10, checking in only when it needs your accounts or a decision. Pass 'explain' for teaching mode that explains what the last 90 is and why each item matters."
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - AskUserQuestion
  - WebFetch
  - Task
triggers:
  - last 90
  - the last 90
  - production readiness
  - launch readiness
  - make it ship-safe
  - finish the last 90
  - is my app safe to launch
---

# last-90 — finish the last 90% of a web app launch

The first 10% — a working app — is what agents do well. The **last 90%** is the
unglamorous production work everyone says agents don't do: authorization,
monitoring, legal, backups, abuse limits, CI/CD, an ops runbook. This skill does
that work, on a loop, until the app is genuinely safe to put in front of users.

**Where it fits:** this is the follow-on to `vps-saas` (the levels.io method).
That skill ends at "Verify (deterministic)" — a deployed, reachable app. `last-90`
starts there. It also handles the managed path (Vercel + Supabase + Sentry).
Detect the stack; don't assume one.

The graded checklist this skill works against lives in
[`references/scale.md`](references/scale.md); the deep end-to-end audit it scores
against lives in [`references/audit-prompt.md`](references/audit-prompt.md). Read
both at the start of every run.

## Operating contract (this is a goal, not a one-shot)

Success criterion: **Launch Gate = 10/10** in `references/scale.md` (N/A items
excused) and **no dimension is `❌ Missing`**. Loop until that holds or every
remaining item is blocked on the owner.

The rule that makes it autonomous: **do every 🤖 item yourself; only stop the
loop for 🙋 items.** Don't ping the owner for work you can do from the code.

This pairs with `/goal` — `/last-90` simply runs the goal below. You can also
paste the **Goal block** at the end into `/goal` directly.

## Modes

- **Default** — concise. Score, do the work, batch check-ins, report.
- **Explain / teach mode** — when invoked with `explain`, `teach`, `--explain`,
  or `why` (e.g. `/last-90 explain`), turn on the teaching layer below. Use it
  for first-time vibe coders who want to learn *what* the last 90 is and *why* it
  matters, not just get it done.

### Teaching layer (explain mode)
The goal is to leave the owner understanding production-readiness, not just
holding a finished app. While running, for each item you touch:
1. **What** — name the thing in one plain sentence (no jargon-dumping).
2. **Why it matters** — the concrete failure it prevents, ideally with the
   real-world consequence ("without RLS, any logged-in user can read every other
   user's rows by changing an ID in the URL — this is the #1 way vibe-coded apps
   leak data").
3. **What I'm doing about it** — the specific change, and how you'll prove it.

Open the run with a 4–6 line primer: what "the last 90" means (the first 10% is
the working demo agents nail; the last 90% — authz, monitoring, legal, backups,
abuse limits, ops — is what separates a demo from something safe for real users),
and why skipping it is how vibe-coded apps get hacked, sued, or silently lose
data. Keep each explanation tight — teach, don't lecture. The scale in
`references/scale.md` carries the per-item rationale; lean on it.

## Process

### 1. Detect the stack (no questions yet)
Read the repo: framework, host (VPS+systemd+Caddy / Vercel / Netlify), DB
(SQLite+Litestream / Supabase / Postgres), auth lib, whether it accepts
user-generated content, whether it takes payments. This decides which criteria
are 🤖 vs 🙋 and which are N/A (e.g. UGC moderation).

### 2. Baseline score (report before touching anything)
Grade the app against the full scale, using the deep pre-launch audit in
[`references/audit-prompt.md`](references/audit-prompt.md) to score the
dimensions — trace real user flows end-to-end (security, concurrency/idempotency,
reliability, accessibility, visual consistency), don't skim files. Output the
headline **Launch Gate N/10**, each dimension's grade with one line of evidence,
and split every gap into:
- 🤖 **Autonomous queue** — what you'll do now, no input needed. The audit's
  "quick wins" feed straight into this.
- 🙋 **Needs-human queue** — what's blocked on an account/secret/decision.

### 3. Access & Connections Intake (the ONE upfront check-in)
Before the loop runs, ask the owner — in a single `AskUserQuestion` — which
connections they can grant **now** vs **defer**. Only ask about services the
detected app actually needs. Typical set for a launching web app:

- **Repo + CI/CD** — push access + permission to enable GitHub Actions and add
  repo secrets (so CI can build/test on every PR).
- **Error monitoring** — a DSN from an error tracker. Open source first:
  self-hosted **Bugsink** (single box, SQLite) or **GlitchTip**; hosted Sentry if
  preferred. All speak the Sentry SDK protocol — same wiring, different DSN.
- **Uptime monitoring** — somewhere to ping `/health` from, *off the app box*:
  self-hosted **Uptime Kuma** or **Gatus** (home server / second box), or a
  hosted pinger (UptimeRobot / BetterStack) if they'd rather not run one.
- **Backups** — backup target (Cloudflare R2 bucket / Supabase paid tier) and a
  green light to rehearse a restore.
- **Auth providers** — OAuth client IDs/secrets for any social login.
- **Payments** — Stripe keys, **only if** the app monetizes.
- **Legal** — a real contact address + who approves Privacy/ToS copy.
- **Domain/DNS** — usually already done by `vps-saas`; confirm TLS is strict.

For each: *grant now*, *defer (I'll do it later)*, or *not needed*. Anything
deferred is recorded and excused from the gate — it does not silently pass.

### 4. Run the loop (autonomous)
Work the Autonomous queue to done, verifying each item deterministically (a
PASS bar in the scale is the test). Re-score after each batch. Keep going —
draft the legal pages, add the health endpoint, write the CI workflow, add RLS /
tenant-isolation tests, wire the error boundary, add rate limits, write the ops
runbook, fix unbounded queries — until **no 🤖 work remains**. For large
independent chunks, delegate to subagents via the Task tool; keep this session as
the coordinator.

Verify, don't assume. Examples: prove tenant isolation with a cross-user read
test; hit `/api/health` and assert 200/503; run `next build` and exercise the
core flow against it; confirm `.env` is gitignored and no secret is committed.

### 5. Check-in (only for 🙋 items)
When the Autonomous queue is empty, present **one consolidated list** of remaining
human actions — each with the exact step (e.g. "add `SENTRY_DSN` to repo secrets",
"enable Actions on the repo", "run the restore drill: `litestream restore ...`").
Group by service. Then pause. When the owner grants access, resume the loop and
finish those items. Don't trickle one-at-a-time interruptions.

### 6. Final report
When the gate is 10/10 (or remaining items are owner-deferred), output:
- **Verdict:** a release recommendation — **Safe to ship** / **Ship with known
  risks** / **Do not ship** (per the verdict rule in the scale), with one line of
  justification.
- **Launch Gate:** 10/10 with each blocker's evidence.
- **Dimensions:** grade table.
- **Deferred:** anything the owner chose to skip, with the residual risk named.
- **What changed:** the concrete edits/files this run added.
- **Follow-on:** suggest `/seo-setup` (technical SEO foundations — favicon,
  robots, sitemap, canonicals, Search Console) if it hasn't been run for this
  app; discoverability is part of the last 90 but scored outside this gate.

## Guardrails
- Never invent a secret, DSN, or credential. Blocked → 🙋, not a guess.
- Commit and deploy from a CLEAN checkout of the commit (git worktree), never
  the working tree — it may hold unrelated WIP, and rsync-style deploy scripts
  will ship it (including un-reviewed DB migrations). If a shared file (e.g.
  the server-actions module) entangles your changes with WIP, split the commit
  so the committed tree builds standalone; prove it by building the worktree.
- Stay faithful to the detected stack's idioms (RLS for Supabase; centralized
  owner-column filtering for SQLite — there is no RLS in SQLite).
- Surgical changes — this is a finishing pass on a working app, not a refactor.
- Backups don't count until a restore is rehearsed. Monitoring doesn't count
  until it's live in prod. Legal pages don't count until linked and reachable.

---

## Goal block (paste into `/goal`, or `/last-90` runs it for you)

> **Goal:** Make this deployed web app ship-safe by completing every item in the
> Last 90 scale (this skill's `references/scale.md`). Detect the stack,
> score the Launch Gate (target 10/10) and the 11 dimensions, then loop:
> implement and deterministically verify every 🤖 Autonomous item without asking.
> Up front, run the Access & Connections Intake once to learn which 🙋 services I
> can grant now vs defer. Only interrupt me for 🙋 items requiring an account,
> secret, or decision — and batch them into a single check-in. Keep working until
> the Launch Gate is 10/10 (deferred items excused and recorded) and no dimension
> is ❌ Missing, then give the SHIP-SAFE / NOT-YET verdict with evidence.
