#!/bin/bash
# Install NixOS on ThinkPad X13s from an Ubuntu live environment.
#
# === PREREQUISITE: On your desktop, serve the flake ===
#   cd ~/Documents/nix-conf
#   python3 -m http.server 8080
#
# === On the X13s (Ubuntu live CD) ===
#   export PROXY=http://192.168.16.131:7897
#   export FLAKE_URL=http://<desktop-ip>:8080
#   wget -e use_proxy=yes -e https_proxy=$PROXY $FLAKE_URL/install-x13s.sh
#   bash install-x13s.sh
#
set -euo pipefail

PROXY="${PROXY:-http://192.168.16.131:7897}"
FLAKE_URL="${FLAKE_URL:-http://192.168.16.131:8080}"
FLAKE_HOST="${FLAKE_HOST:-laptop-solar-chiyoko}"

export HTTPS_PROXY="$PROXY"
export https_proxy="$PROXY"

echo "=== Step 0: Install dependencies ==="
apt-get update -qq
apt-get install -y -qq wget
apt-get install -y -qq git

echo "=== Step 1: Install nix ==="
if [ ! -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    wget -e use_proxy=yes -e https_proxy="$PROXY" -qO /tmp/nix-installer.sh \
      https://install.determinate.systems/nix
    chmod +x /tmp/nix-installer.sh
    /tmp/nix-installer.sh install --no-confirm
fi
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

echo "=== Step 2: Configure nix daemon ==="
mkdir -p /etc/systemd/system/nix-daemon.service.d
cat > /etc/systemd/system/nix-daemon.service.d/proxy.conf << EOF
[Service]
Environment="HTTPS_PROXY=$PROXY"
Environment="https_proxy=$PROXY"
EOF
cat > /etc/nix/nix.custom.conf << 'NIXEOF'
extra-experimental-features = nix-command flakes
extra-substituters = https://mirrors.ustc.edu.cn/nix-channels/store https://cache.nixos.org
extra-trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
NIXEOF
systemctl daemon-reload && systemctl restart nix-daemon
sleep 2

echo "=== Step 3: Fetch and prepare flake ==="
rm -rf /tmp/nix-conf
mkdir -p /tmp/nix-conf
wget -e use_proxy=yes -e https_proxy="$PROXY" -qO /tmp/nix-conf.tar.gz \
  "$FLAKE_URL/nix-conf.tar.gz"
tar xzf /tmp/nix-conf.tar.gz -C /tmp/nix-conf
pushd /tmp/nix-conf
git init && git config user.email "root@localhost" && git config user.name "root"
git add -A && git commit --no-gpg-sign -m "install"

echo "=== Step 4: Build and run disko ==="
DISKO_SCRIPT=$(nix build ".#nixosConfigurations.$FLAKE_HOST.config.system.build.diskoScript" \
  --no-link --print-out-paths --accept-flake-config | tail -1)
echo "Disko: $DISKO_SCRIPT"
$DISKO_SCRIPT

echo "=== Step 5: Install nixos-install-tools ==="
nix profile add nixpkgs#nixos-install-tools

echo "=== Step 6: Install NixOS ==="
nixos-install --root /mnt --flake ".#$FLAKE_HOST"
popd

echo ""
echo "=== Done! Remove USB and reboot: systemctl reboot ==="
