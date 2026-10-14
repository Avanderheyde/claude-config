---
name: design-elevate
description: >-
  Turn a functional-but-generic web app into one with a real, non-"vibe-coded"
  visual identity. Use when the user says a site "looks AI-generated / looks vibe
  coded / looks like every other SaaS", wants to "elevate the design", "make it
  not look generic", or asks to apply a serious design pass to an existing app.
  An AGGREGATOR skill: it curates and orchestrates the best external design
  skills and sources (each credited — see Sources & Credits) around a token-first
  DESIGN.md, a mockup-board approval loop, and per-page pass pipelines.
  Aesthetic-agnostic: each site gets its OWN identity, not a copied look.
---

# Design Elevate

A repeatable pipeline for taking an app from "clearly AI-generated" to "someone
with taste made this." It does **not** invent a house style — it establishes a
real identity for *this* product and enforces it ruthlessly.

**This skill is an aggregator, not an original work.** Much of its method is
curated from other people's skills, references, and writing. Every borrowed
technique is cited inline and listed in **Sources & Credits** at the bottom.
When you add a technique from elsewhere, cite it — uncredited borrowing is a
bug in this file.

## The core diagnosis

"Looks vibe-coded" almost always decomposes into five fixable things. Name which
ones apply before touching pixels:

1. **Default identity.** Inter/Geist body, Instrument Serif headings, violet or
   generic-blue accent, `system-ui`. Fix: a deliberate, non-default type + one
   accent chosen for *this* product.
   ⚠️ **The tell-list is a moving target.** By mid-2026 the "tasteful" defaults
   are tells too: *dark warm editorial* (near-black + cream + serif display +
   single warm accent + film grain) and *tan/cream paper editorial* both read
   as AI now. Yesterday's tasteful default is today's slop — re-audit this list
   every few months against what AI tools currently converge on.
2. **Anti-pattern slop.** Icon-in-colored-circle grids, centered-everything,
   uniform bubbly radii, gradient CTAs, blobs, emoji-as-design. Fix: the
   zero-tolerance list below, enforced in every review.
3. **No craft in the hard parts.** Div-bar "charts" with no axis, cards with no
   hierarchy, instant state changes. Fix: full component anatomy (below).
4. **Text where a picture belongs.** Metrics as sentences instead of bars,
   flows, or logo stacks. Fix: visual encoding.
5. **Wrong composition register.** Product pages built like landing posters —
   hero statements, taglines, marketing copy on a page whose job is data. Fix:
   working-instrument furniture (toolbars, ruled tables, pagination, colophons).
   A product page with a job earns trust; a poster begs for it.

## Step 0 — Establish (or read) DESIGN.md

Everything hangs off a single source of truth. If the project has a `DESIGN.md`,
read it first and treat it as law. If it doesn't — or the user says throw it
out — create one **before** any visual change. Gather context (users, brand
personality, references, anti-references) via `teach-impeccable` or gstack's
`/design-consultation`, then write `DESIGN.md` at the repo root with:

- **Product context** — what, who for, and the *memorable thing*. Force this
  question: *"What's the ONE thing someone should remember after seeing this
  for the first time?"* The answer can reframe the whole premise (a
  "leaderboard" whose users come to *learn* is a reference guide, not a live
  scoreboard — that answer kills entire aesthetic directions before they're
  built).
- **Aesthetic direction** — one line, decoration level, mood, reference peers
  *studied for structure, never copied*. If the user names a brand anchor
  (e.g. teenage.engineering), record it here verbatim.
- **Typography** — explicit roles + size scale + rules (tabular-nums globally,
  curly quotes, `…`, `text-wrap: balance`, tracking only on caps). A single
  variable family with multiple voices (width/weight axes) is a strong
  anti-default move.
- **Color** — neutrals + **one** accent with **named slots** (e.g. "the №1 rank
  numeral, the active tab, one primary action — nowhere else"). *The accent is
  information, not decoration.*
- **Content encoding** (see section below) — what the product refuses to
  display is a design decision of equal rank to color.
- **Spacing / Layout / Charts / Motion / Mobile / Anti-patterns / Decisions
  log** — the decisions log (date + decision + rationale) is what stops drift
  and re-litigation across sessions.

## Step 1 — The variant-board approval loop

Never implement a redesign the user hasn't *seen*. The loop that works:

1. Sketch 3–4 genuinely distinct directions (different worlds, not palette
   swaps). Add a **wildcard from outside voices**: independent proposals from a
   second model (e.g. `codex exec`) and a blind subagent — convergence between
   them is signal, and their best divergent idea becomes variant D.
2. **Build real HTML mockups, not AI images.** One self-contained HTML file per
   direction, real Google-Fonts loads, exact hexes, the SAME realistic content
   in each (fair comparison). Parallel subagents, one per direction. Real HTML
   beats image-gen for typography-led design — image models garble UI text —
   and it's free.
3. Screenshot each at 1440px in a real browser; publish a rated comparison
   board the user can mark up (gstack `design compare --serve`, or any board
   with per-variant ratings + an overall comment box).
4. Read the feedback file, restate what you understood, and iterate. Round 2 is
   usually **one locked system across the real pages** (the app's actual
   key pages, not an imagined homepage) — mock the surfaces that exist.
5. On approval: write DESIGN.md from the winning mockups (they are the visual
   contract), record the decision, and only then touch the app.

## Step 2 — Foundation, then per-page passes

**Foundation commit first** (via `frontend-design` discipline): tokens as CSS
variables, the new type loaded, `tabular-nums` global, Tailwind mappings —
namespaced so legacy tokens keep un-migrated pages alive, annotated
"no new uses." Then migrate page by page against the mockup contract.

### The per-page hit-list

Run these passes IN ORDER on every page. Map to whatever skills exist locally;
the order is the invariant:

| # | Pass | Skill(s) | Gate |
|---|---|---|---|
| 1 | Build to contract | (implementation) + `vercel:react-best-practices` for data-fetching/list perf (Vercel Engineering) | Matches approved mockup |
| 2 | Type | `/typeset` (impeccable.style) | Registers, tabular-nums, tracking |
| 3 | Layout | `/arrange` (impeccable.style) | Shared grid axes, density |
| 4 | Color | `/colorize` (impeccable.style) | Token compliance; accent-slot budget audit |
| 5 | Motion — find | `find-animation-opportunities` (Emil Kowalski) | ≤5–7 survivors of the 4-question gate |
| 6 | Motion — build | `/animate` (impeccable.style) + `emil-design-eng` values (Emil Kowalski) | ease-out, transform/opacity, <300ms |
| 7 | Feel | `make-interfaces-feel-better` (Jakub Krehel) + `/delight` | Exact-value micro-craft, no decoration |
| 8 | Polish | `/polish` (impeccable.style) + userinterface.wiki article for the surface (Raphael Salaja) | States, empty/loading/error, optical alignment |
| 9 | Motion — review | `review-animations` (Emil Kowalski) | 10 standards; `transition: all` is a block |
| 10 | Design gate | `/critique` then `/design-review` (impeccable.style) | Zero anti-pattern hits vs DESIGN.md |
| 11 | Quality gate | chrome-devtools `lighthouse_audit` + perf budgets (Addy Osmani) | JS <300KB gz, fonts <100KB, LCP/INP/CLS at p75 |

For exploring layout/density options *within* a locked system, `design-and-refine`
(0xdesign) renders 5 real-code variants inside the live dev server at
`/__design_lab` using your actual Tailwind tokens — constrain its interview to
the DESIGN.md tokens so it explores structure, not identity.

## Step 3 — The research loop that actually works

Don't design components from imagination — but choose sources by surface, and
know which sources are slop vectors. Fan out parallel research agents, collapse
findings into a **steal-list** (structure, never visuals), build against your
own tokens.

**Source map (curated + verified 2026-07):**

| Surface | Steal structure from |
|---|---|
| Ranked lists / leaderboards | **Mobbin** (shipped ranking screens: App Store charts, finance movers — row anatomy, delta indicators, mobile collapse) + **component.gallery** (Iain Bean — Table/Pagination/Tabs anatomy across 95 real design systems) |
| Data-dense index typography | **Savee** (art-director taste density: timetables, annual reports, ruled tables) + **Cosmos** (attributed, AI-detecting: statistical atlases, Swiss print, isotype) |
| Charts/maps | Print archives via Cosmos/Savee first, UI galleries second — a treemap's visual language lives in statistical atlases, not dashboards |
| Nav (once) | navbar.gallery — Static/Sticky category for dense utilitarian bars |
| Future homepage | saaspo.com (page-type + stack filters; blacklist bento/gradient entries) + supahero.io (type-led heroes only) + landing.love filtered Minimal/Light (motion in full-page video) |
| Identity | rebrand.gallery (single-grotesque + signal-color brand systems — precedent for accent-slot rationing) + floguo.com (Flora Guo — personality-through-restraint: version stamps, mono metadata, ASCII detail) |
| Component mechanics | 21st.dev as a **code quarry only** — take sorting/sticky-header/virtualization mechanics, strip every visual decision |
| Brand-system prose | voltagent/awesome-design-md — 73 reverse-engineered DESIGN.md files (Linear, The Verge, Vercel) as comparative references for your own DESIGN.md's rigor |

**Slop-pull exclusions (do not browse for inspiration):** Dribbble — the
canonical fantasy-UI source; *"looks like a Dribbble shot" is itself a rejection
criterion*. Pinterest (algorithmic, AI-polluted). motionsites.ai (AI-template
marketplace). reactbits.dev / Magic-UI-style component packs (maximalist
showcases that fail every restraint gate). Font catalogues (fontshare, uncut.wtf)
once type is locked — browsing them only invites drift.

## Motion doctrine

Distilled from Emil Kowalski's skills (github.com/emilkowalski/skills) — the
most operational motion methodology assessed; install the whole bundle, two
skills need their sibling STANDARDS/AUDIT files:

- **Find as a rejection filter** (`find-animation-opportunities`): every
  candidate passes a 4-question gate — frequency tier (keyboard-triggered
  actions never animate), purpose named from a closed list ("looks cool" is
  banned), per-element ms budget, function-vs-decoration. Cap suggestions at
  5–7 and keep a mandatory rejected-candidates section.
- **Never animate data being read.** Motion on content under the user's eyes is
  decoration at best, sabotage at worst.
- **Review as a hard gate** (`review-animations`): ease-in on enter is a block;
  sub-300ms for UI; no `scale(0)`; transform-origin from the trigger; GPU
  properties only; `prefers-reduced-motion` = gentler, not zero; flag-on-sight:
  `transition: all`, keyframes on toasts, ungated `:hover`.
- **Exact values beat vibes** (`emil-design-eng`, `make-interfaces-feel-better`):
  scale(0.96–0.97) on press, ~100ms stagger, spring bounce:0, concentric radii
  (outer = inner + padding), 44px hit areas, interruptible transitions that
  start from the live presentation value (the one universal idea worth keeping
  from Apple's fluid-interfaces canon even in a no-bounce Swiss system).
- **Calm systems don't bounce.** If DESIGN.md says editions-not-live, then no
  pulsing dots, no tickers, no "updated 2 min ago".

## Content encoding & credibility

What a product refuses to display is a design decision of equal rank to color
— put it in DESIGN.md as binding law. Learned on a real program (2026-07):

- **Small numbers undermine authority.** Early-stage products hide inventory
  totals ("128 apps indexed", "of N" pagination) and raw engagement counts
  (votes) — they make the site look small. `SHOWING 01–08 · LOAD MORE` needs
  no total.
- **Opacity can be strategy.** "Ranked by a proprietary index" beats a
  methodology page when the ranking can be gamed. One line + a corrections
  invitation builds more trust than exposition.
- **A proprietary score column** (e.g. `VIBE SCORE 94.2`, tabular) gives ranks
  a visible driver without exposing raw counts.
- **Editorial verdicts are the learning layer** — a one-line human judgment per
  ranked entity ("why this matters") keeps a reference page useful when ranks
  don't move. Never fabricate verdicts about real people; render-if-present.
- If a figure can be a bar, a flow, or a logo stack, it is not a line of text.

## Component anatomy (where taste is proven)

**Charts** — *a chart without a scale is decoration.* 2–3 hairline gridlines,
nice-number ticks, x-axis with current period emphasized, muted data palette
(accent reserved for one meaningful series), trend line over the populated span
only, HTML tooltips, mount-only stagger ≤360ms. Hand-roll the SVG for small
fixed series. A data map can be a *statistical atlas page*: grey density ramp +
one accent region, `FIG. 01` caption with a scale note, legend as a ruled list.

**Tables/indexes** — header band and rows share ONE explicit grid template so
every column sits on the same axis (check with component.gallery's Table
anatomy). Rank numerals oversized + tabular. Numeric columns right-aligned.
Lettermark tiles over full-color logos in dense rows.

**Cards / dashboard** — one big number as the hero, composition as a segmented
split-bar with dot legend, counts as an overlapping logo stack, asymmetric grid,
small-caps titles. Normals whisper, exceptions shout.

**Forms** — never ask for what the system already knows.

## Identity: wordmark, logo, share surfaces

- **One display voice, upright.** Italic-serif wordmarks are a default-AI tell;
  so is swapping to another era's default. A single variable family doing the
  wordmark via a width axis is stronger than a second font.
- **A real mark, not a glyph.** Explore 5+ ligature/layer options as an
  artifact the user picks from. Define it ONCE as SVG; mirror it everywhere
  (React component + raw data-URI for image pipelines).
- **Share cards are brand walls.** Logo-forward, text-free, one accent rule,
  never private data. satori gotchas: no woff2 (vendor TTFs), pre-fetch remote
  images to base64, inline-SVG-via-`<img>` data URI for the mark.
- Study rebrand.gallery for how strict single-typeface brands ration their
  accent — collect 5 precedents before writing your accent-slot rules.

## Mobile discipline

- Bottom tab bar (fixed, `border-t`, safe-area padded) or restyled collapse —
  never a desktop nav crammed down. Sticky headers under ~90px.
- **No horizontal overflow, ever.** Explicit mobile grid templates
  (`grid-cols-1` = `minmax(0,1fr)`); flex mains need `min-w-0`. Tables collapse
  to stacked ruled rows — never a sideways-scrolling table body.
- Chip/tab rows become one `overflow-x-auto` scroller (`shrink-0
  whitespace-nowrap`), re-wrapping at `sm:`.
- Touch targets ≥44px; hover-revealed actions pair with
  `pointer-coarse:opacity-100`.
- **Modals portal to `<body>`** — a `fixed inset-0` overlay inside any
  scroll/overflow container clips to it (mobile shows a thin strip).
  `createPortal` to body; bottom sheets (`items-end`, `max-h-[90dvh]`,
  safe-area padding) that center at `sm:`.

## The QA loop

Verify against the **real, logged-in** state, not a mock. Screenshot the live
page at real viewports, compare to DESIGN.md and the approved mockups, fix,
re-screenshot. Keep before/after shots. Mint temporary sessions for QA accounts
and delete them after; restore any real data touched.

## Zero-tolerance anti-patterns

Flag and remove every hit in every review. Items 13–17 merged from Leon
(Leonxlnx/taste-skill)'s binary pre-flight checks — mechanically auditable:

1. Purple / violet / indigo gradients of any kind.
2. Icon-in-colored-circle feature grids; icons in circles as decoration.
3. `text-align: center` on every heading, description, and card.
4. Uniform large bubbly border-radius on everything.
5. Decorative blobs, floating circles, wavy SVG dividers, film grain/texture overlays.
6. Emoji as design elements.
7. Colored left-border accents used decoratively.
8. Generic hero copy ("Welcome to X", "Unlock the power of Y").
9. `system-ui` / Inter / Roboto / Space Grotesk as primary faces.
10. Gradient CTA buttons.
11. **Dated-tasteful clusters:** dark-warm-editorial (near-black + cream +
    serif + warm accent) and tan/cream-paper editorial. Re-audit this item
    quarterly — the tell-list moves.
12. Landing-poster composition on product pages (hero statements over data).
13. Em dashes in UI copy (labels, buttons, form copy). *(via taste-skill)*
14. Section-number "eyebrows" on more than ⅓ of sections. *(via taste-skill)*
15. Duplicate CTAs with identical intent in one viewport. *(via taste-skill)*
16. Fake previews: dashboard-shaped divs with lorem data posing as product shots. *(via taste-skill)*
17. "Looks like a Dribbble shot" — speculative-concept aesthetics (fake data,
    ornamental charts) on a real product.

## Lessons that save rework

- **Deliver exactly what was asked.** Don't gild a requested change with
  unprompted extras — they read as noise and get reverted.
- **Mock the real surfaces.** An imagined homepage impresses nobody whose
  product is three working pages. Ask which pages exist and mock THOSE.
- **The memorable-thing answer outranks your direction sketches.** If it
  contradicts them, retune or kill directions before generating anything.
- **The decisions log is load-bearing.** Write down *why* so the next session
  doesn't re-litigate.
- **Token-first or it drifts.** A hex outside the variable block means the
  system is already leaking. Namespace new tokens when legacy ones must
  coexist; annotate legacy "no new uses."
- **Two skins, one token system.** Dark mode is a designed second skin, never
  a mechanical inversion — and deferring it is a legitimate decision to log.
- **Outside voices are cheap insurance.** Two independent models converging on
  the same direction is signal; their divergence is a free wildcard variant.

## One-time setup (adopted externals)

```bash
# Emil Kowalski's motion suite (find/review/improve-animations, emil-design-eng
# — install whole directories; STANDARDS.md/AUDIT.md are load-bearing siblings)
npx skills@latest add emilkowalski/skills

# Jakub Krehel's micro-craft pass (16 techniques, hard numeric rules)
npx skills add jakubkrehel/make-interfaces-feel-better

# Icon search/sync MCP (better-auth team) — pin ONE collection per project
npx skills add better-auth/better-icons

# In-app real-code variant explorer (0xdesign) — /__design_lab in your dev server
# /plugin marketplace add 0xdesign/design-plugin
# /plugin install design-and-refine@design-plugins
```

`vercel:react-best-practices` ships with the Vercel plugin — no install.
Registry for future finds: **ui-skills.com** (Julien Thibeaut / @ibelick).

## Sources & Credits

This skill aggregates other people's work. Credit where it's due:

- **impeccable.style** — the installed core suite this pipeline orchestrates:
  `/critique /design-review /typeset /arrange /colorize /polish /delight
  /animate /teach-impeccable /frontend-design`.
- **Emil Kowalski** — github.com/emilkowalski/skills · emilkowal.ski — the
  motion doctrine's spine: find-animation-opportunities (4-question rejection
  gate), review-animations (10 standards), emil-design-eng, improve-animations.
- **Jakub Krehel** — github.com/jakubkrehel/make-interfaces-feel-better —
  exact-value micro-craft (concentric radii, press scale, stagger, hit areas).
- **Vercel Engineering** — github.com/vercel-labs/agent-skills —
  react-best-practices (70 prioritized React/Next.js perf rules).
- **Addy Osmani** — github.com/addyosmani/web-quality-skills — numeric perf
  budgets (JS <300KB gz, fonts <100KB, Core Web Vitals p75 thresholds).
- **Leon (Leonxlnx)** — github.com/Leonxlnx/taste-skill — binary-auditable
  anti-slop checks merged into the anti-pattern list (items 13–16).
- **0xdesign** — github.com/0xdesign/design-plugin — design-and-refine live
  in-app variant exploration.
- **better-auth team** — github.com/better-auth/better-icons — icon MCP/CLI.
- **Julien Thibeaut (@ibelick)** — ui-skills.com — the design-engineering
  skills registry.
- **Iain Bean** — component.gallery — component anatomy across 95 design systems.
- **Raphael Salaja** — userinterface.wiki — theory-plus-code interface manual.
- **VoltAgent** — github.com/voltagent/awesome-design-md — 73 brand DESIGN.md
  references.
- **Flora Guo** — floguo.com — personality-through-restraint reference.
- **Galleries** — Mobbin, Savee, Cosmos, saaspo.com, rebrand.gallery,
  navbar.gallery, supahero.io, landing.love, appmotion.design, 21st.dev —
  per the source map above.
- **Apple** — WWDC fluid-interfaces principles (interruptibility,
  respond-on-pointer-down), via Emil Kowalski's apple-design skill.
- **gstack** — design-consultation / design compare boards / browse binary —
  the mockup-board approval loop's tooling.
- Program lessons (tan-paper tell, content-encoding law, memorable-thing
  reframing, HTML-mockups-over-image-gen) were learned on real
  redesign programs, 2026.
