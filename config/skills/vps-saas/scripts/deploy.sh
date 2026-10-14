#!/usr/bin/env bash
# Deploy / update the app on the box. Run as the deploy user (sudo for systemd).
# Idempotent. First run also installs the systemd unit + Caddy + Litestream config.
#
#   APP=myapp DOMAIN=app.example.com REPO=git@github.com:you/app.git \
#   ./deploy.sh
#
# Assumes harden-vps.sh has run and /etc/$APP/env exists (0640 root:deploy).

set -euo pipefail

APP="${APP:?set APP}"
DOMAIN="${DOMAIN:?set DOMAIN}"
REPO="${REPO:?set REPO (git url)}"
# APP and DOMAIN land in root-owned files below, so allow only plain names.
[[ "$APP" =~ ^[a-z][a-z0-9-]{0,31}$ ]] || { echo "APP must match ^[a-z][a-z0-9-]{0,31}$"; exit 1; }
[[ "$DOMAIN" =~ ^[A-Za-z0-9.-]+$ ]] || { echo "DOMAIN must be a bare hostname"; exit 1; }
SRV="/srv/$APP"

[ -f "/etc/$APP/env" ] || { echo "missing /etc/$APP/env — write it first (0640)"; exit 1; }

echo "==> sync source"
if [ ! -d "$SRV/.git" ]; then
  git clone --recurse-submodules "$REPO" "$SRV"
else
  git -C "$SRV" fetch --all --prune
  git -C "$SRV" reset --hard origin/main
  git -C "$SRV" submodule update --init --recursive
fi
cd "$SRV"

echo "==> build (standalone)"
npm ci
npm run build
# Next standalone output needs static + public copied alongside server.js
cp -r .next/static ".next/standalone/.next/static"
[ -d public ] && cp -r public ".next/standalone/public" || true

echo "==> service user"
# The app runs as its own unprivileged user. The deploy user has passwordless
# sudo, so running the app as it would turn any app RCE into root.
id -u "$APP" >/dev/null 2>&1 || sudo useradd --system --no-create-home --shell /usr/sbin/nologin "$APP"
sudo install -d -m 750 -o "$APP" -g "$APP" "/var/lib/$APP"

echo "==> systemd unit"
sudo tee "/etc/systemd/system/$APP.service" >/dev/null <<EOF
[Unit]
Description=$APP (Next.js)
After=network.target

[Service]
Type=simple
User=$APP
NoNewPrivileges=true
WorkingDirectory=$SRV
EnvironmentFile=/etc/$APP/env
ExecStart=/usr/bin/node $SRV/.next/standalone/server.js
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

echo "==> Caddy"
sudo tee /etc/caddy/Caddyfile >/dev/null <<EOF
$DOMAIN {
    encode gzip zstd
    reverse_proxy 127.0.0.1:3000
}
EOF

echo "==> Litestream (if /etc/litestream.yml present, enable service)"
if [ -f /etc/litestream.yml ]; then
  sudo systemctl enable --now litestream || sudo systemctl restart litestream
fi

echo "==> (re)start services"
sudo systemctl daemon-reload
sudo systemctl enable --now "$APP"
sudo systemctl restart "$APP"
sudo systemctl reload caddy || sudo systemctl restart caddy

echo
echo "DONE. Verify: curl -sI https://$DOMAIN"
sudo systemctl --no-pager --full status "$APP" | head -12 || true
