---
name: vps-saas
version: 1.0.0
description: Ship a SaaS on a single locked-down Hetzner VPS (levels.io method) — Next.js + SQLite + Auth.js + Caddy + Litestream + Stripe behind Cloudflare. Use when deploying a small/bootstrapped SaaS cheaply (~$5/mo) instead of managed PaaS (Vercel/Supabase), or when asked for the "levels.io method", "single VPS", or "cheap self-hosted SaaS".
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - AskUserQuestion
  - WebFetch
triggers:
  - levels.io method
  - levelsio stack
  - single vps saas
  - hetzner vps deploy
  - cheap saas hosting
  - raw dog the server
---

# vps-saas — ship a SaaS on one locked-down VPS (levels.io method)

The philosophy (from @levelsio, who runs $150k/mo SaaS on it): **one cheap box
runs everything.** No managed Postgres, no managed auth, no PaaS bill. SQLite on
disk, a reverse proxy with auto-HTTPS, the app as a systemd service, continuous
streaming backups offsite, Stripe for money, Cloudflare in front. Vertical-scale
the box before you ever distribute.

This skill is the repeatable recipe. Run it per project; swap the worked numbers.

## The stack (defaults — swap only with reason)

| Layer | Choice | Why |
|---|---|---|
| Host | Hetzner CX22 (2 vCPU / 4 GB, Ubuntu 24.04 LTS) | ~€4.5/mo, ample for early SaaS |
| Edge | Cloudflare (free) | DNS, origin-hiding proxy, TLS, rate-limit/WAF |
| Proxy | Caddy | auto-HTTPS, 3-line config; simpler than nginx |
| App | Next.js `output: "standalone"`, run by systemd as non-root | one process, restart-on-fail |
| DB | SQLite via Drizzle + better-sqlite3 | single file, no server, fast |
| Auth | Auth.js v5 (NextAuth) + Drizzle SQLite adapter | vetted library — never hand-roll auth |
| Secrets | app-level AES-256-GCM; key in systemd `EnvironmentFile` (0640 root:app) | a DB/file leak ≠ plaintext keys |
| Backups | Litestream → Cloudflare R2 (or Hetzner Storage Box) | continuous, point-in-time restore |
| Payments | Stripe (Checkout + webhook + customer portal) | usage-priced, no fixed cost |

Alternatives, only if the task demands: Coolify/Dokku (PaaS-on-your-VPS, easier
deploys, more overhead) instead of raw; Postgres instead of SQLite (multi-writer
or >~100GB); nginx instead of Caddy.

## Process

### 0. Decide (ask the user only what's load-bearing)
- Domain name + whether Cloudflare already manages its DNS.
- Hetzner project exists? (VPS creation is theirs — needs their account/billing.)
- Backup target: Cloudflare R2 bucket vs Hetzner Storage Box.
- Stripe price (amount + interval + trial?). Create it via the Stripe MCP if connected.

### 1. Provision the box (USER action — needs their Hetzner account)
Tell the user to create a Hetzner Cloud server: Ubuntu 24.04, CX22, **their SSH
public key added at creation** (so root login is key-only from minute one). Have
them send you the server IP. They point the domain's A record at it in Cloudflare
(proxied / orange cloud).

### 2. Harden + install (run `scripts/harden-vps.sh` on the box as root)
Idempotent. Creates a non-root sudo deploy user, locks SSH to keys + disables
root login, UFW (22/80/443 only), fail2ban, unattended-upgrades, installs Node
22, Caddy, and Litestream. See the script for the exact, re-runnable steps.
**Verify after:** you can SSH as the deploy user; root SSH is refused;
`ufw status` shows only 22/80/443; `sshd -T | grep -E 'permitrootlogin|passwordauthentication'` shows `no`.

### 3. App: make it VPS-ready (in the repo)
- `next.config.ts` → `output: "standalone"`.
- Add Drizzle + better-sqlite3; schema for the app's tables. SQLite file lives at
  e.g. `/var/lib/<app>/data.db` (outside the repo, owned by the app's own unprivileged service user).
- Add Auth.js v5 with the Drizzle SQLite adapter; providers: email (magic link) +
  Google + GitHub. OAuth callback URLs point at the app domain
  (`https://<domain>/api/auth/callback/<provider>`) — the user creates the OAuth
  apps in Google/GitHub consoles and supplies client id/secret as env vars.
- Sensitive third-party secrets (e.g. provider Admin keys): encrypt with
  AES-256-GCM (`crypto` module) using `APP_ENCRYPTION_KEY` (32 bytes, base64) from
  the environment before writing to SQLite; decrypt only server-side. Never log or
  return the plaintext. See `references/crypto.md` pattern.
- Multi-tenant: every table has an owner column; every query filters by the
  authenticated user id. (SQLite has no RLS — tenant isolation is enforced in the
  data layer; centralize it so it can't be forgotten.)

### 4. Wire the box (templates below; or `scripts/deploy.sh`)
- systemd unit runs `node .next/standalone/server.js` as the deploy user on
  127.0.0.1:3000, with `EnvironmentFile=/etc/<app>/env` (0640 root:<deploy>).
- Caddyfile reverse-proxies the domain → 127.0.0.1:3000 (auto-HTTPS; set
  Cloudflare SSL mode to "Full (strict)").
- Litestream config replicates the SQLite file → R2; enable + start its service.
- First deploy: clone repo (with `--recurse-submodules` if it uses one), `npm ci`,
  `npm run build`, copy standalone output, `systemctl restart <app>`.

### 5. Stripe
Create Product + Price (Stripe MCP `stripe_api_write` if connected, else dashboard).
Implement `/api/stripe/checkout` (create Checkout Session), `/api/stripe/webhook`
(verify signature with `STRIPE_WEBHOOK_SECRET`, update subscription state in
SQLite), and a customer-portal link. Local testing: `stripe listen --forward-to
localhost:3000/api/stripe/webhook`. Prod webhook endpoint = `https://<domain>/api/stripe/webhook`.

### 6. Verify (deterministic)
- `curl -sI https://<domain>` → 200, valid cert.
- Sign up via each auth provider; confirm a row in SQLite scoped to that user.
- Connect a secret; confirm the stored column is ciphertext, not plaintext.
- `litestream snapshots <db>` shows replicas in the bucket. Practice a restore.
- Reboot the box; confirm the app + Caddy + Litestream come back via systemd.

## Templates

**systemd unit** (`/etc/systemd/system/<app>.service`):
```ini
[Unit]
Description=<app> (Next.js)
After=network.target

[Service]
Type=simple
User=<app>
WorkingDirectory=/srv/<app>
EnvironmentFile=/etc/<app>/env
ExecStart=/usr/bin/node /srv/<app>/.next/standalone/server.js
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
```

**Caddyfile** (`/etc/caddy/Caddyfile`):
```
<domain> {
    encode gzip zstd
    reverse_proxy 127.0.0.1:3000
}
```

**Litestream** (`/etc/litestream.yml`):
```yaml
dbs:
  - path: /var/lib/<app>/data.db
    replicas:
      - type: s3
        endpoint: <accountid>.r2.cloudflarestorage.com
        bucket: <app>-backups
        path: data.db
        access-key-id: ${R2_ACCESS_KEY_ID}
        secret-access-key: ${R2_SECRET_ACCESS_KEY}
```

## Env vars (in `/etc/<app>/env`, mode 0640)
```
NODE_ENV=production
PORT=3000
AUTH_SECRET=               # openssl rand -base64 32
AUTH_URL=https://<domain>
APP_ENCRYPTION_KEY=        # openssl rand -base64 32 (32 bytes for AES-256-GCM)
DATABASE_PATH=/var/lib/<app>/data.db
GOOGLE_CLIENT_ID=          GOOGLE_CLIENT_SECRET=
GITHUB_CLIENT_ID=          GITHUB_CLIENT_SECRET=
EMAIL_SERVER=              EMAIL_FROM=        # for magic-link (or a provider API)
STRIPE_SECRET_KEY=         STRIPE_WEBHOOK_SECRET=
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=
R2_ACCESS_KEY_ID=          R2_SECRET_ACCESS_KEY=
```

## Guardrails
- Auth and crypto: use the vetted libraries above. Do not invent token formats,
  password hashing, or cipher modes.
- Secrets never enter the repo, logs, client responses, or exports. Only the
  encryption key decrypts; it lives in `/etc/<app>/env`, not in SQLite, not in git.
- Always confirm offsite backups work *before* taking real users. A single box
  with no tested restore is the one failure mode that loses customer data.
- `ufw` default-deny inbound; expose only 22/80/443. Prefer Cloudflare-proxied
  ingress and consider restricting 80/443 to Cloudflare IP ranges.
