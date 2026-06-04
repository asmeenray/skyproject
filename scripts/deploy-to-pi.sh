#!/usr/bin/env bash
# Push the current working tree to the skyproject Pi, rebuild, restart the server,
# and reload the kiosk. Configure via env:
#   PI_HOST     (default skyproject.local)
#   PI_USER     (default pi)
#   PI_APPDIR   (default /home/<PI_USER>/skyproject)
#   SSH_KEY     (default ~/.ssh/id_ed25519 — a passphrase-less deploy key is ideal)
#   SERVICE     (default skyproject-server)
#
# Example:
#   PI_HOST=skyproject.local ./scripts/deploy-to-pi.sh
set -euo pipefail

PI_HOST="${PI_HOST:-skyproject.local}"
PI_USER="${PI_USER:-pi}"
PI_APPDIR="${PI_APPDIR:-/home/$PI_USER/skyproject}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519}"
SERVICE="${SERVICE:-skyproject-server}"
SSH="ssh -i $SSH_KEY -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"

REPO="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> rsync $REPO/ -> $PI_USER@$PI_HOST:$PI_APPDIR/"
rsync -az --delete \
  --exclude node_modules --exclude dist --exclude .git \
  --exclude 'server/data' --exclude data \
  -e "$SSH" "$REPO/" "$PI_USER@$PI_HOST:$PI_APPDIR/"

echo "==> install + build + restart on the Pi"
# shellcheck disable=SC2087
$SSH "$PI_USER@$PI_HOST" "
  set -e
  cd '$PI_APPDIR'
  export CI=true COREPACK_ENABLE_DOWNLOAD_PROMPT=0
  pnpm install
  pnpm build
  sudo systemctl restart $SERVICE
"

echo "==> reload kiosk"
$SSH "$PI_USER@$PI_HOST" '
  export XDG_RUNTIME_DIR=/run/user/$(id -u) WAYLAND_DISPLAY=wayland-1
  pkill -f "/usr/lib/chrom[i]um" 2>/dev/null || true
  sleep 2
  setsid "$HOME/.local/bin/skyproject-kiosk.sh" < /dev/null > "$HOME/kiosk.log" 2>&1 &
  sleep 1
' || true

echo "Done → http://$PI_HOST:3000/  (control: http://$PI_HOST:3000/control)"
