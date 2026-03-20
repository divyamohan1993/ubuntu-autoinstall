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

# ─── Auto-detect latest versions of everything ───────────────────────
UBUNTU_CODENAME=$(lsb_release -cs)
UBUNTU_VERSION=$(lsb_release -rs)
HWE_KERNEL="linux-generic-hwe-${UBUNTU_VERSION}"

# Auto-detect latest NVIDIA driver available
NVIDIA_DRIVER=$(apt-cache search '^nvidia-driver-[0-9]+$' 2>/dev/null \
  | grep -oP 'nvidia-driver-\d+' | sort -t- -k3 -n | tail -1)
NVIDIA_DRIVER="${NVIDIA_DRIVER:-nvidia-driver-535}"

# Auto-detect latest GCC version available
GCC_VERSION=$(apt-cache search '^gcc-[0-9]+$' 2>/dev/null \
  | grep -oP 'gcc-\K\d+' | sort -n | tail -1)
GCC_VERSION="${GCC_VERSION:-14}"

# Auto-detect latest nvm release from GitHub
NVM_VERSION=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest 2>/dev/null \
  | grep -oP '"tag_name":\s*"\K[^"]+')
NVM_VERSION="${NVM_VERSION:-v0.40.3}"

echo "Detected: Ubuntu ${UBUNTU_VERSION} (${UBUNTU_CODENAME})"
echo "  NVIDIA driver: ${NVIDIA_DRIVER}"
echo "  GCC version:   gcc-${GCC_VERSION}"
echo "  nvm version:   ${NVM_VERSION}"

# ─── 1. Add external APT repositories ────────────────────────────────

# Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list

# NVIDIA (driver repo — for GPU driver, not full CUDA toolkit)
curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${UBUNTU_VERSION//.}/x86_64/cuda-keyring_1.1-1_all.deb \
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

# Ubuntu Toolchain PPA (latest gcc/g++)
add-apt-repository -y ppa:ubuntu-toolchain-r/test

# Kitware (latest CMake)
curl -fsSL https://apt.kitware.com/keys/kitware-archive-latest.asc | \
  gpg --dearmor -o /usr/share/keyrings/kitware-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ ${UBUNTU_CODENAME} main" \
  > /etc/apt/sources.list.d/kitware.list

# ─── 2. Upgrade everything to latest, then install ────────────────────

apt-get update
apt-get dist-upgrade -y

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
  build-essential \
  gcc-${GCC_VERSION} \
  g++-${GCC_VERSION} \
  cmake \
  ninja-build \
  ${HWE_KERNEL} \
  ${NVIDIA_DRIVER} \
  microsoft-edge-stable \
  containerd.io \
  docker-ce \
  docker-ce-cli \
  docker-buildx-plugin \
  docker-compose-plugin

# Set latest gcc/g++ as default
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${GCC_VERSION} 100 \
  --slave /usr/bin/g++ g++ /usr/bin/g++-${GCC_VERSION}

# ─── 2b. Remove bloatware ──────────────────────────────────────────────

# Remove Firefox (replaced by Edge)
snap remove firefox 2>/dev/null || true

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
  totem-plugins \
  remmina \
  transmission-gtk \
  simple-scan \
  gnome-todo \
  gnome-contacts \
  gnome-calendar \
  gnome-maps \
  gnome-weather \
  gnome-clocks \
  gnome-font-viewer \
  gnome-logs \
  brltty \
  orca \
  gnome-accessibility-themes \
  update-manager \
  language-selector-gnome \
  yelp \
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

# ─── 5. GNOME tweaks ──────────────────────────────────────────────────

# Disable the 60-second shutdown confirmation dialog — shuts down immediately
sudo -u dmj dbus-launch gsettings set org.gnome.SessionManager logout-prompt false 2>/dev/null || true

# ─── 6. Add user to docker group ─────────────────────────────────────

usermod -aG docker dmj || true

# ─── 6. Install VS Code via snap ─────────────────────────────────────

snap install code --classic

# ─── 7. Install Node.js (via nvm) + Claude Code ──────────────────────

if [ ! -d /home/dmj/.nvm ]; then
  sudo -u dmj bash -c '
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    nvm install node
    npm install -g @anthropic-ai/claude-code
  '
fi

# ─── 8. Install Claude Code VS Code extension ────────────────────────

sudo -u dmj bash -c '
  code --install-extension anthropic.claude-code 2>/dev/null || true
'

# ─── 9. Configure Claude Code: agent teams, plugins, marketplace ─────

sudo -u dmj mkdir -p /home/dmj/.claude
sudo -u dmj tee /home/dmj/.claude/settings.json > /dev/null << 'CLAUDE_SETTINGS'
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "enabledPlugins": {
    "frontend-design@claude-plugins-official": true,
    "superpowers@claude-plugins-official": true,
    "code-review@claude-plugins-official": true,
    "github@claude-plugins-official": true,
    "feature-dev@claude-plugins-official": true,
    "playwright@claude-plugins-official": true,
    "autofix-bot@claude-plugins-official": true,
    "semgrep@claude-plugins-official": true,
    "claude-code-setup@claude-plugins-official": true,
    "security-guidance@claude-plugins-official": true,
    "code-simplifier@claude-plugins-official": true,
    "claude-md-management@claude-plugins-official": true
  },
  "extraKnownMarketplaces": {
    "claude-plugins-official": {
      "source": {
        "source": "github",
        "repo": "anthropics/claude-plugins-official"
      }
    }
  }
}
CLAUDE_SETTINGS

# ─── 10. Configure aggressive auto-updates (ALL packages, ALL repos) ─

# APT auto-updates: check daily, install everything
cat > /etc/apt/apt.conf.d/20auto-upgrades << 'APTCONF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
APTCONF

cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'APTCONF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}:${distro_codename}-updates";
    "${distro_id}:${distro_codename}-backports";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
    "*:*";
};

Unattended-Upgrade::Origins-Pattern {
    "origin=*";
};

Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "04:00";

Dpkg::Options {
    "--force-confdef";
    "--force-confold";
};
APTCONF

systemctl enable unattended-upgrades
systemctl restart unattended-upgrades

# Snap auto-refresh: twice daily
snap set system refresh.timer=00:00~04:00/2

# Daily cron: auto-update Node.js to latest + npm globals (Claude Code etc.)
cat > /etc/cron.daily/update-node-and-npm << 'CRON'
#!/bin/bash
export HOME=/home/dmj
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install node --reinstall-packages-from=current >> /var/log/node-auto-update.log 2>&1
nvm alias default node >> /var/log/node-auto-update.log 2>&1
npm update -g >> /var/log/node-auto-update.log 2>&1
echo "$(date): Node $(node --version), npm $(npm --version)" >> /var/log/node-auto-update.log
CRON
chmod +x /etc/cron.daily/update-node-and-npm

# Catch-up service: runs missed updates after boot + when network connects
apt-get install -y anacron

cat > /etc/apt/apt.conf.d/10periodic-boot << 'EOF'
APT::Periodic::RandomSleep "0";
EOF

cat > /etc/systemd/system/catch-up-updates.service << 'EOF'
[Unit]
Description=Catch-up on missed auto-updates after boot
After=network-online.target
Wants=network-online.target
ConditionACPower=true

[Service]
Type=oneshot
ExecStartPre=/bin/sleep 60
ExecStart=/bin/bash -c 'apt-get update -qq && unattended-upgrade -v >> /var/log/catch-up-updates.log 2>&1'
ExecStartPost=/bin/bash -c '/etc/cron.daily/update-node-and-npm'
ExecStartPost=/bin/bash -c 'snap refresh >> /var/log/catch-up-updates.log 2>&1 || true'
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable catch-up-updates.service

# NetworkManager hook: trigger catch-up when WiFi/Ethernet connects
cat > /etc/NetworkManager/dispatcher.d/99-catch-up-updates << 'DISPATCH'
#!/bin/bash
if [ "$2" = "up" ] || [ "$2" = "connectivity-change" ]; then
    STAMP="/var/lib/apt/periodic/update-success-stamp"
    if [ -f "$STAMP" ]; then
        AGE=$(( $(date +%s) - $(stat -c %Y "$STAMP") ))
        if [ "$AGE" -gt 21600 ]; then
            systemctl start catch-up-updates.service &
        fi
    else
        systemctl start catch-up-updates.service &
    fi
fi
DISPATCH
chmod +x /etc/NetworkManager/dispatcher.d/99-catch-up-updates

# ─── 11. Done ─────────────────────────────────────────────────────────

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
