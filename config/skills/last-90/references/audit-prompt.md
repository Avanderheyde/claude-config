# Deep pre-launch audit

The Launch Gate in `scale.md` is the binary go/no-go. This is the **deep read**
behind it: a systematic, adversarial audit that traces real user flows end-to-end
and surfaces the failure classes vibe-coded apps ship with. Run it during the
baseline score (SKILL.md step 2) and again before declaring a verdict.

> Adapted from a pre-launch audit prompt by **@shugardadddy**
> (https://x.com/shugardadddy/status/2075148611680149656). Extended to fit the
> Last 90 stack-aware flow.

## Directive

Perform a comprehensive audit of the application across **security, reliability,
concurrency, accessibility, and UI consistency**. Review the codebase,
architecture, data flows, API interactions, auth logic, state management, async
operations, error handling, and user-facing interfaces. **Trace important flows
end-to-end rather than reviewing files in isolation.** Do not assume client-side
validation is sufficient; do not modify code during the initial audit.

## What to investigate

**1. Security & data exposure**
- Auth/authz flaws: missing server-side permission checks, privilege escalation,
  insecure direct object references (IDOR), cross-tenant data access. (On the
  detected stack: Supabase → RLS on every table; SQLite → centralized owner-id
  filtering — verify a user cannot read another's row.)
- Secrets/PII leaked via client bundles, env vars, API responses, logs,
  analytics, URLs, storage/cookies, error messages, or source maps.
- Injection: SQL, command, template, prompt, HTML, script. Plus XSS, CSRF, SSRF,
  open redirects, unsafe uploads, path traversal, weak sessions, insecure token
  storage, missing security boundaries.
- Overly permissive DB rules, endpoints, CORS, storage buckets, webhook handlers,
  third-party integrations.
- Missing validation/sanitisation at trust boundaries.

**2. Concurrency, race conditions & state integrity**  *(the gap most vibe apps ship with)*
- Duplicate submissions from repeated clicks, retries, refreshes, or concurrent
  requests. Are mutating endpoints **idempotent**? (payments, bookings, jobs,
  messages, sign-ups must not double-fire.)
- Stale state, optimistic-update failures, lost updates, conflicting writes,
  out-of-order async responses.
- Effects, subscriptions, listeners, timers, requests not cleaned up.
- UI actions still available while an operation is already in progress.
- Cache invalidation gaps; inconsistency between client, server, and persisted
  state. Multi-tab, multi-device, and poor-network scenarios.

**3. Reliability & failure handling**
- Unhandled rejections, swallowed errors, silent failures, infinite loading,
  broken retries, incomplete rollback.
- Missing loading / empty / error / offline / timeout / partial-success states.
- Failure paths that leave data or UI inconsistent.
- Unsafe assumptions about API responses, nullability, ordering, timing, network.
- Memory leaks, needless rerenders, expensive ops, obvious bottlenecks.

**4. Accessibility** *(target WCAG 2.2 AA where applicable)*
- Semantic HTML: landmarks, headings, labels, lists, tables, buttons, links.
- Keyboard nav, logical tab order, focus visibility, focus trapping/restoration.
- Accessible names/labels/descriptions and correct ARIA.
- Colour contrast, text legibility, touch-target size, zoom, reduced-motion,
  no meaning-by-colour-alone.
- Screen-reader behaviour for modals, menus, tabs, toasts, validation, loading,
  and dynamically updated content.
- Forms: clear instructions, accessible validation, autocomplete, error recovery.

**5. Visual & interaction consistency**
- Consistent spacing, type, colour, radii, shadows, icon sizing, alignment,
  component dimensions, responsive behaviour; correct design-token / shared-
  component use.
- Every interactive state present and consistent: hover, focus, active, selected,
  disabled, loading, success, warning, destructive, error.
- Layout shift (CLS), clipping, overflow, truncation, wrapping, breakpoint
  issues, empty states.
- Copy: terminology drift, capitalisation, punctuation, date/number formats,
  action labels.

**6. Responsive & edge cases**
- Narrow mobile, tablet, desktop, ultra-wide, zoomed, large-text.
- Long names/emails, translated/expanded text, empty values, huge datasets,
  zero-result states, malformed/unexpected content.

## Report format

Produce the findings report **before** changing anything, grouped by severity
then category. For each finding:

- **Severity:** Critical | High | Medium | Low | Informational
- **Category:** Security | Race Condition | Reliability | Accessibility | Performance | Visual Consistency
- **Location:** exact file, component, function, endpoint, or flow
- **Issue:** what is wrong
- **Impact:** what can realistically happen in production
- **Evidence:** the code path / behaviour / reproducible condition
- **Reproduction:** steps to trigger or verify (where applicable)
- **Recommended fix:** specific, technically actionable
- **Confidence:** Confirmed | High Confidence | Needs Verification

Prioritise by real-world impact and exploitability. Distinguish confirmed
vulnerabilities from theoretical concerns; don't report speculation without
evidence. Then provide:

1. A prioritised remediation plan.
2. Quick wins — safe to fix with low regression risk (feed these straight into
   the Last 90 autonomous queue).
3. Issues needing architectural change or deeper investigation.
4. A **release recommendation** (see the verdict rule in `scale.md`):
   **Safe to ship** | **Ship with known risks** | **Do not ship** — with justification.

Be adversarial in security, systematic in accessibility, precise in the UI pass.
