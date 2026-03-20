#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
# Post-install script — runs on first boot after autoinstall
# Lean setup: drivers, Docker, core CLI tools, sysctl optimizations
# Everything else can be installed on demand (see on-demand-install.sh)
# ═══════════════════════════════════════════════════════════════════════
set -euo pipefail
exec > /var/log/post-install.log 2>&1
echo "=== Post-install started at $(date) ==="

export DEBIAN_FRONTEND=noninteractive

# ─── 1. Add external APT repositories ────────────────────────────────

# Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable" \
  > /etc/apt/sources.list.d/docker.list

# NVIDIA (driver repo — for GPU driver, not full CUDA toolkit)
curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb \
  -o /tmp/cuda-keyring.deb
dpkg -i /tmp/cuda-keyring.deb

# Microsoft Edge
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | \
  gpg --dearmor -o /usr/share/keyrings/microsoft-edge.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-edge.gpg] https://packages.microsoft.com/repos/edge stable main" \
  > /etc/apt/sources.list.d/microsoft-edge.list

# eza (modern ls)
curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | \
  gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
  > /etc/apt/sources.list.d/gierens.list

# Git PPA (latest git)
add-apt-repository -y ppa:git-core/ppa

# ─── 2. Install essential packages only ───────────────────────────────

apt-get update

apt-get install -y \
  curl \
  git \
  git-delta \
  jq \
  tmux \
  tree \
  fzf \
  ripgrep \
  bat \
  fd-find \
  eza \
  pipx \
  python3-pip \
  python3-venv \
  ntfs-3g \
  linux-generic-hwe-24.04 \
  nvidia-driver-535 \
  microsoft-edge-stable \
  containerd.io \
  docker-ce \
  docker-ce-cli \
  docker-buildx-plugin \
  docker-compose-plugin

# ─── 2b. Remove bloatware ──────────────────────────────────────────────

# Remove Firefox (replaced by Edge)
snap remove firefox 2>/dev/null || true

# Remove Ubuntu snaps that aren't needed for development
snap remove snap-store 2>/dev/null || true
snap remove firmware-updater 2>/dev/null || true
snap remove gnome-42-2204 2>/dev/null || true
snap remove gtk-common-themes 2>/dev/null || true
snap remove snapd-desktop-integration 2>/dev/null || true

# Remove pre-installed Ubuntu bloat packages
apt-get remove -y --purge \
  gnome-games \
  aisleriot \
  gnome-mahjongg \
  gnome-mines \
  gnome-sudoku \
  thunderbird \
  libreoffice-* \
  rhythmbox \
  shotwell \
  cheese \
  totem \
  remmina \
  transmission-gtk \
  simple-scan \
  gnome-todo \
  gnome-contacts \
  gnome-calendar \
  gnome-maps \
  gnome-weather \
  gnome-clocks \
  usb-creator-gtk \
  brltty \
  speech-dispatcher \
  orca \
  gnome-accessibility-themes \
  2>/dev/null || true

# Clean up orphaned dependencies
apt-get autoremove -y --purge

# ─── 3. Sysctl optimizations ─────────────────────────────────────────

cat > /etc/sysctl.d/99-ml-performance.conf << 'SYSCTL'
# --- RAM: Always prefer RAM over swap ---
vm.swappiness = 1
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 40
vm.dirty_background_ratio = 5
vm.overcommit_memory = 1
vm.min_free_kbytes = 1048576
vm.admin_reserve_kbytes = 524288
vm.user_reserve_kbytes = 524288
vm.oom_kill_allocating_task = 1
vm.panic_on_oom = 0
vm.zone_reclaim_mode = 0

# --- Network: BBR congestion + max throughput ---
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 1048576
net.core.wmem_default = 1048576
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_slow_start_after_idle = 0
net.core.netdev_max_backlog = 16384
net.core.somaxconn = 8192
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_tw_reuse = 1
kernel.sysrq = 1
SYSCTL

cat > /etc/sysctl.d/99-performance.conf << 'SYSCTL'
# Performance tuning
fs.inotify.max_user_watches=524288
fs.inotify.max_user_instances=1024
fs.file-max=2097152

# Memory protection — 1.5GB always reserved for kernel/UI
vm.min_free_kbytes=1572864
vm.oom_kill_allocating_task=1
vm.overcommit_memory=0
vm.overcommit_ratio=95
vm.panic_on_oom=0
SYSCTL

# Apply immediately (will also apply on every boot)
sysctl --system

# ─── 4. AppArmor / Edge sandbox fix ───────────────────────────────────
# Without this, Edge crashes because it can't create sandboxed processes.
# This allows unprivileged user namespaces (needed by Chromium-based browsers
# and many container runtimes).

cat > /etc/sysctl.d/99-edge-sandbox.conf << 'EOF'
kernel.apparmor_restrict_unprivileged_userns = 0
EOF
sysctl -w kernel.apparmor_restrict_unprivileged_userns=0

# Also create an AppArmor profile exception for Edge so it works
# even if the sysctl gets reverted by an Ubuntu update
if [ -d /etc/apparmor.d ]; then
  cat > /etc/apparmor.d/microsoft-edge << 'APPARMOR'
# Allow Microsoft Edge to use unprivileged user namespaces for its sandbox
abi <abi/4.0>,

include <tunables/global>

profile microsoft-edge /opt/microsoft/msedge/microsoft-edge flags=(unconfined) {
  userns,
  include if exists <local/microsoft-edge>
}
APPARMOR

  # Reload AppArmor
  systemctl reload apparmor 2>/dev/null || true
fi

# ─── 5. Add user to docker group ─────────────────────────────────────

usermod -aG docker dmj || true

# ─── 6. Install VS Code via snap ─────────────────────────────────────

snap install code --classic

# ─── 7. Install Node.js (via nvm) + Claude Code ──────────────────────

if [ ! -d /home/dmj/.nvm ]; then
  sudo -u dmj bash -c '
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    nvm install --lts
    npm install -g @anthropic-ai/claude-code
  '
fi

# ─── 8. Install Claude Code VS Code extension ────────────────────────

sudo -u dmj bash -c '
  code --install-extension anthropic.claude-code 2>/dev/null || true
'

# ─── 9. Done ──────────────────────────────────────────────────────────

echo "=== Post-install completed at $(date) ==="
echo "=== REBOOT RECOMMENDED ==="

# Remind user to change password on next login
cat > /etc/profile.d/change-password-reminder.sh << 'REMIND'
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ⚠️  DEFAULT PASSWORD IN USE — CHANGE IT NOW:               ║"
echo "║     sudo passwd dmj                                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
REMIND
