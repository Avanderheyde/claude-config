---
name: seo-setup
version: 1.0.0
description: "Set up and verify technical SEO foundations for a web app — metadata, favicons, robots.txt, sitemap, canonicals, structured data, Open Graph, and Google Search Console. Use for new apps before/at launch, after big metadata changes, or when search results look wrong (generic globe favicon, bare-domain site name, rewritten titles/descriptions). Verification-first: every item has a command that proves it from the outside, the way Google sees it. For content/keyword strategy see the marketingskills seo-audit + ai-seo skills; for launch ops see /last-90."
triggers:
  - seo setup
  - seo foundations
  - fix google search appearance
  - favicon not showing in google
  - site name wrong in google
  - request indexing
  - submit sitemap
---

# seo-setup — technical SEO foundations, verified from the outside

You are a release engineer for search appearance. Your job is to make a site
render professionally in Google (and AI search) and to PROVE each item with an
external check — never "the code looks right." Chrome showing the favicon in a
tab proves nothing about Google: browsers read `<link rel="icon">` live, while
Google uses its own crawler + cache pipeline with stricter rules.

## Related skills (don't duplicate them)

- `seo-audit` / `schema-markup` / `ai-seo` / `programmatic-seo` (marketingskills
  plugin) — content strategy, deep schema, AI-answer optimization.
- `/last-90` — launch-ops gate; run this skill as its discoverability item.
- Deep-dive references if needed: Google SEO starter guide
  (https://developers.google.com/search/docs/fundamentals/seo-starter-guide),
  community skill packs (kpab/seo-mastery-agent-skills,
  AgriciDaniel/claude-seo).

## Process

1. Run the **external verification suite** (below) against the live domain
   first. Report a scorecard before touching code.
2. Fix failures in the codebase (framework notes below), redeploy, re-verify.
3. Do the **Search Console pass** (browser workflow below).
4. Set expectations: SERP favicon/site-name changes take days→weeks after a
   recrawl. Re-check with the favicon-cache command, not by googling the site.

## The checklist (each item = what good looks like + how to verify)

### 1. robots.txt — crawlable content AND brand assets
- Sitemap line present; content pages allowed for the bots you want.
- **Brand assets must be crawlable in EVERY user-agent group**: `/favicon.ico`,
  icon/apple-icon files, OG-image routes. Google's favicon crawler
  (Googlebot-Image) and social scrapers (Twitterbot, Slackbot,
  facebookexternalhit) match the `*` group — a default-deny `Disallow: /`
  silently kills the SERP favicon and all link-preview images. Google will not
  show a favicon it cannot crawl.
- robots must not block anything the sitemap lists (GSC flags this).
```bash
curl -s https://$DOMAIN/robots.txt
```

### 2. Sitemap — generated, complete, submitted
- Auto-generated from the data layer (new pages appear without manual edits),
  only canonical indexable URLs, referenced in robots.txt, submitted in GSC.
```bash
curl -s https://$DOMAIN/sitemap.xml | head -50
```

### 3. Favicon set — a real raster, not just SVG
- `/favicon.ico` must return 200 with a multi-size ICO (16/32/48). SVG-only
  setups are unreliable in Google's pipeline; keep the SVG as a progressive
  enhancement. Ship `apple-touch-icon` (180–512px PNG) too.
- Verify what Google actually has cached (this is what SERPs show):
```bash
curl -s -o /dev/null -w "%{http_code} %{content_type}\n" https://$DOMAIN/favicon.ico
curl -sL -A "Mozilla/5.0" "https://t3.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://$DOMAIN&size=64" -o /tmp/gfav.png && file /tmp/gfav.png
# 16x16 result = Google has nothing (generic globe). 64x64 = real cached icon (may be stale).
```
- Build an ICO from an existing 512px PNG without new deps: `sips -z N N` for
  16/32/48, then wrap the PNGs in an ICO container (PNG-in-ICO is valid).

### 4. Titles & descriptions — unique, branded, written for the SERP
- Homepage title: `Brand — what the site is` (Google rewrites bare/vague
  titles). Every indexable page: unique title + 150–160 char description.
- A thin homepage description ("curated daily"-style taglines) gets ignored;
  Google will substitute body text or another page's description.
```bash
curl -s https://$DOMAIN/ | grep -oE '<title>[^<]*</title>|<meta name="description" content="[^"]*"'
```

### 5. Canonicals — self-referencing on every indexable page
- Detail pages built from generateMetadata/templates included. Never inherit a
  layout-level canonical (every page would claim "/").
```bash
for p in "" about pricing; do curl -s "https://$DOMAIN/$p" | grep -oE '<link rel="canonical"[^>]*>'; done
```

### 6. Site-name signals — make Google show the brand, not the bare domain
- `WebSite` JSON-LD on the homepage with `name`, `url`, and `alternateName`
  (short brand). `og:site_name` meta. Title branding consistent with both.
- All three must agree; conflicting signals = Google shows "domain.tld".

### 7. Structured data — minimum viable, then content types
- Minimum: `Organization` (name, url, logo, sameAs) + `WebSite` (+SearchAction
  if there's search). Then content types: Article, ItemList on rankings,
  BreadcrumbList on detail pages. Escape `<` in inlined JSON-LD.
- JSON-LD injected client-side won't show in curl — verify rendered HTML or
  use https://search.google.com/test/rich-results before reporting "missing".

### 8. Open Graph / social previews
- Per-page `og:image` (1200×630), `twitter:card`. Layout-level openGraph should
  carry `siteName`/`type` ONLY — a title/description there leaks onto every
  page's share preview that doesn't define its own.
- OG image endpoints must be robots-allowed (see item 1).

### 9. Google Search Console (browser workflow — needs the user's session)
- Property verified for the domain. Then:
  a. Sitemaps → submit `https://$DOMAIN/sitemap.xml` → status "Success".
  b. URL Inspection → homepage URL → **Request indexing** (priority crawl
     queue). Do this after any big metadata/favicon change. Re-submitting the
     same URL repeatedly does NOT speed it up.
- If driving the user's logged-in browser, screenshot the "Indexing requested"
  and sitemap "Success" confirmations as evidence.

### 10. Redirects & soft-redirect homepages
- Old URLs 301/308 to new ones; sitemap lists only the targets.
- If the homepage `redirect()`s server-side to another route (Next.js), it can
  still serve 200 + layout metadata to crawlers. Google then indexes `/` with
  the ROOT layout's title/description — so those must be real, plus a
  `canonical: "/"` on the root page.

### What NOT to burn time on (per Google)
Keywords in domains, exact word counts, subdomain-vs-subdirectory, meta
keywords tag, duplicate-content "penalties", heading-order perfectionism.

## External verification suite (run first, report a scorecard)

```bash
DOMAIN=example.com
curl -s -o /dev/null -w "favicon.ico: %{http_code} %{content_type}\n" https://$DOMAIN/favicon.ico
curl -s https://$DOMAIN/robots.txt | grep -cE "Allow: /(favicon|icon|apple-icon|opengraph|api/og)" # >0 per group
curl -s -o /dev/null -w "sitemap: %{http_code}\n" https://$DOMAIN/sitemap.xml
curl -s https://$DOMAIN/ | grep -oE '<title>[^<]*</title>|<meta name="description"[^>]*>|<link rel="canonical"[^>]*>|og:site_name[^/]*|"@type":"WebSite"' | head -8
curl -sL -A "Mozilla/5.0" "https://t3.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://$DOMAIN&size=64" -o /tmp/gfav.png && file /tmp/gfav.png
```

## Framework notes — Next.js App Router

- `app/favicon.ico` is served at `/favicon.ico` automatically; `app/icon.svg`
  and `app/apple-icon.png` emit their link tags.
- Root layout `metadata`: `metadataBase`, `applicationName`, branded default
  `title`, real `description`, `openGraph: { siteName, type }` (nothing else).
- Canonicals: `alternates: { canonical: "/route" }` per page; in
  `generateMetadata` build it from params. Never set canonical in the layout.
- Inline JSON-LD in the layout `<head>`; escape `<` via
  `JSON.stringify(x).replace(/</g, "\\u003c")`.
- `app/sitemap.ts` with `revalidate` — query the DB so it self-updates.
- `app/robots.txt/route.ts` (or `robots.ts`) — keep a BRAND_ASSET_ALLOW list
  appended to every group, with a regression test asserting each group allows
  favicon + OG paths.

## Hard-won gotchas (learned in production, 2026-08)

1. **robots.txt default-deny broke the favicon** — allowlist robots setups must
   explicitly allow brand assets in the `*` group; the named-bots group is not
   enough (Googlebot-Image isn't Googlebot).
2. **Chrome tab ≠ Google SERP** — different pipelines; only the gstatic
   faviconV2 check tells you what Google has. A correct-in-Chrome favicon with
   a 404 `/favicon.ico` still renders as the generic globe in SERPs.
3. **Google's cache is stale by design** — after fixing, expect days→2 weeks.
   A cached OLD logo (rebrand case) fixes itself on recrawl; Request Indexing
   nudges it.
4. **Weak meta = Google writes its own** — it will pull a better description
   from another page (e.g. the page your homepage redirects to).
5. **Site name needs three agreeing signals** — JSON-LD WebSite name,
   og:site_name, and title branding. Any conflict → bare domain shown.
6. **ICO link tags can lie** — a tag claiming `sizes="256x256"` over a file
   containing only 16/32 still works in tabs but is below Google's 48px
   recommendation. Check the actual file with `file`.
