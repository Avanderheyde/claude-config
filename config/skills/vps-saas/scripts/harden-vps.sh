#!/usr/bin/env bash
# Harden + provision a fresh Ubuntu 24.04 Hetzner VPS for a single-box SaaS.
# Run as root on the box (first boot). Idempotent — safe to re-run.
#
#   DEPLOY_USER=deploy DEPLOY_PUBKEY="ssh-ed25519 AAAA... you@host" \
#   APP=myapp ./harden-vps.sh
#
# Leaves: a non-root sudo user (key-only), SSH locked down, UFW (22/80/443),
# fail2ban, unattended-upgrades, Node 22, Caddy, Litestream. It does NOT deploy
# the app — that's deploy.sh.

set -euo pipefail

DEPLOY_USER="${DEPLOY_USER:-deploy}"
APP="${APP:-app}"
DEPLOY_PUBKEY="${DEPLOY_PUBKEY:-}"

[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 1; }
[ -n "$DEPLOY_PUBKEY" ] || { echo "set DEPLOY_PUBKEY to your SSH public key"; exit 1; }

echo "==> base packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y ufw fail2ban unattended-upgrades ca-certificates curl gnupg debian-keyring debian-archive-keyring apt-transport-https

echo "==> non-root sudo user: $DEPLOY_USER"
if ! id "$DEPLOY_USER" &>/dev/null; then
  adduser --disabled-password --gecos "" "$DEPLOY_USER"
  usermod -aG sudo "$DEPLOY_USER"
  echo "$DEPLOY_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/90-$DEPLOY_USER"
  chmod 0440 "/etc/sudoers.d/90-$DEPLOY_USER"
fi
install -d -m 700 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "/home/$DEPLOY_USER/.ssh"
echo "$DEPLOY_PUBKEY" > "/home/$DEPLOY_USER/.ssh/authorized_keys"
chmod 600 "/home/$DEPLOY_USER/.ssh/authorized_keys"
chown "$DEPLOY_USER:$DEPLOY_USER" "/home/$DEPLOY_USER/.ssh/authorized_keys"

echo "==> lock down sshd (key-only, no root)"
cat > /etc/ssh/sshd_config.d/99-hardening.conf <<'EOF'
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no
X11Forwarding no
MaxAuthTries 3
EOF
sshd -t && systemctl restart ssh

echo "==> firewall"
ufw --force reset >/dev/null
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo "==> fail2ban + auto security updates"
systemctl enable --now fail2ban
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

echo "==> Node.js 22"
if ! command -v node &>/dev/null || [ "$(node -v | cut -c2-3)" -lt 22 ] 2>/dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  apt-get install -y nodejs
fi

echo "==> Caddy"
if ! command -v caddy &>/dev/null; then
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' > /etc/apt/sources.list.d/caddy-stable.list
  apt-get update -y && apt-get install -y caddy
fi

echo "==> Litestream"
if ! command -v litestream &>/dev/null; then
  LS_VER="0.3.13"
  curl -fsSL "https://github.com/benbjohnson/litestream/releases/download/v${LS_VER}/litestream-v${LS_VER}-linux-amd64.deb" -o /tmp/litestream.deb
  apt-get install -y /tmp/litestream.deb && rm -f /tmp/litestream.deb
fi

echo "==> app dirs"
install -d -m 755 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "/srv/$APP"
install -d -m 750 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "/var/lib/$APP"
install -d -m 750 -o root -g "$DEPLOY_USER" "/etc/$APP"

echo
echo "DONE. Verify:"
echo "  ssh $DEPLOY_USER@<ip>      # should work"
echo "  ssh root@<ip>              # should be refused"
echo "  ufw status                 # 22/80/443 only"
echo "  sshd -T | grep -Ei 'permitrootlogin|passwordauthentication'   # both 'no'"
echo "Next: write /etc/$APP/env (0640 root:$DEPLOY_USER), then run deploy.sh"
