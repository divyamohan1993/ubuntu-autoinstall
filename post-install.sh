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

# Auto-detect NVIDIA driver: use ubuntu-drivers to find the right version
# Older GPUs need legacy drivers; installing the wrong one wastes 40s+ on boot probes
NVIDIA_DRIVER=""
NVIDIA_KERNEL_MODULES=""
if lspci | grep -qi 'nvidia'; then
  NVIDIA_DRIVER=$(ubuntu-drivers devices 2>/dev/null \
    | grep -oP 'nvidia-driver-\d+(?=.*recommended)' | head -1)
  if [ -z "$NVIDIA_DRIVER" ]; then
    echo "WARNING: NVIDIA GPU found but no recommended driver. Skipping NVIDIA install."
  else
    # Prefer pre-built kernel modules over DKMS (avoids build failures on newer kernels)
    KVER=$(uname -r)
    DRIVER_NUM="${NVIDIA_DRIVER##*-}"
    NVIDIA_KERNEL_MODULES=$(apt-cache search "linux-modules-nvidia-${DRIVER_NUM}-${KVER}" 2>/dev/null \
      | grep -oP 'linux-modules-nvidia-\S+' | head -1)
    if [ -z "$NVIDIA_KERNEL_MODULES" ]; then
      echo "NOTE: No pre-built nvidia kernel modules for ${KVER}, will use DKMS"
    fi
  fi
else
  echo "No NVIDIA GPU detected, skipping driver install."
fi

# Auto-detect latest GCC version available
GCC_VERSION=$(apt-cache search '^gcc-[0-9]+$' 2>/dev/null \
  | grep -oP 'gcc-\K\d+' | sort -n | tail -1)
GCC_VERSION="${GCC_VERSION:-14}"

# Auto-detect latest nvm release from GitHub
NVM_VERSION=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest 2>/dev/null \
  | grep -oP '"tag_name":\s*"\K[^"]+')
NVM_VERSION="${NVM_VERSION:-v0.40.3}"

echo "Detected: Ubuntu ${UBUNTU_VERSION} (${UBUNTU_CODENAME})"
echo "  NVIDIA driver: ${NVIDIA_DRIVER:-SKIPPED (no supported GPU)}"
echo "  GCC version:   gcc-${GCC_VERSION}"
echo "  nvm version:   ${NVM_VERSION}"

# ─── 1. Add external APT repositories ────────────────────────────────

# Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list

# NVIDIA (driver repo — only if a supported GPU was detected)
if [ -n "$NVIDIA_DRIVER" ]; then
  curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${UBUNTU_VERSION//.}/x86_64/cuda-keyring_1.1-1_all.deb \
    -o /tmp/cuda-keyring.deb
  dpkg -i /tmp/cuda-keyring.deb
fi

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
  ${NVIDIA_DRIVER:+$NVIDIA_DRIVER} \
  ${NVIDIA_KERNEL_MODULES:+$NVIDIA_KERNEL_MODULES} \
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
  language-selector-gnome \
  yelp \
  2>/dev/null || true

# Clean up orphaned dependencies
apt-get autoremove -y --purge

# Re-install packages that autoremove may have pulled out via metapackage deps
apt-get install -y --no-install-recommends gnome-control-center update-manager 2>/dev/null || true

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

# ─── 5b. Fast shutdown/reboot ────────────────────────────────────────

# Reduce service stop timeout to 10s (default 90s) so restart is near-instant
mkdir -p /etc/systemd/system.conf.d
cat > /etc/systemd/system.conf.d/fast-shutdown.conf << 'EOF'
[Manager]
DefaultTimeoutStopSec=10s
EOF

# Limit shutdown inhibitor delay to 5s (apps like VS Code, GNOME Shell)
mkdir -p /etc/systemd/logind.conf.d
cat > /etc/systemd/logind.conf.d/fast-restart.conf << 'EOF'
[Login]
InhibitDelayMaxSec=5
EOF

# Suppress broadcast "wall" messages on shutdown/reboot via logind
# NOTE: --no-wall is NOT valid for systemd-shutdown (low-level binary).
# Wall suppression must go through logind.conf, not ExecStart overrides.
cat > /etc/systemd/logind.conf.d/no-wall.conf << 'EOF'
[Login]
WallMessage=
EOF

# Allow sudo users to reboot/shutdown without delay
cat > /etc/polkit-1/rules.d/85-no-shutdown-delay.rules << 'POLKIT'
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.login1.power-off" ||
         action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
         action.id == "org.freedesktop.login1.reboot" ||
         action.id == "org.freedesktop.login1.reboot-multiple-sessions") &&
        subject.isInGroup("sudo")) {
        return polkit.Result.YES;
    }
});
POLKIT

# ─── 6. Add user to docker group + socket-activate ───────────────────

usermod -aG docker dmj || true
# Don't start Docker daemon at boot; socket-activate on first use instead
systemctl disable docker.service 2>/dev/null || true
systemctl enable docker.socket 2>/dev/null || true

# ─── 7. Install VS Code via snap ─────────────────────────────────────

snap install code --classic

# ─── 8. Install Node.js (via nvm) + Claude Code ──────────────────────

if [ ! -d /home/dmj/.nvm ]; then
  export NVM_VERSION
  sudo -u dmj -E bash -c "
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash
    export NVM_DIR=\"\$HOME/.nvm\"
    [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"
    nvm install node
    npm install -g @anthropic-ai/claude-code
  "
fi

# ─── 9. Install Claude Code VS Code extension ────────────────────────

sudo -u dmj bash -c '
  code --install-extension anthropic.claude-code 2>/dev/null || true
'

# ─── 10. Configure Claude Code: agent teams, plugins, marketplace ────

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

# ─── 11. Configure aggressive auto-updates (ALL packages, ALL repos) ─

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
ExecStart=/bin/bash -c 'apt-get update -qq && unattended-upgrade -v >> /var/log/catch-up-updates.log 2>&1'
ExecStartPost=/bin/bash -c '/etc/cron.daily/update-node-and-npm'
ExecStartPost=/bin/bash -c 'snap refresh >> /var/log/catch-up-updates.log 2>&1 || true'
EOF

# Timer triggers the service 2 min after boot — does NOT block boot
cat > /etc/systemd/system/catch-up-updates.timer << 'EOF'
[Unit]
Description=Run catch-up updates 2 minutes after boot

[Timer]
OnBootSec=120
Unit=catch-up-updates.service

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable catch-up-updates.timer

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

# ─── 12. SSD I/O optimization ──────────────────────────────────────────

cat > /etc/udev/rules.d/60-ssd-scheduler.rules << 'EOF'
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/read_ahead_kb}="2048"
EOF

# ─── 13. Protect UI processes from OOM killer (timer-based) ───────────
# Timer-based so it doesn't block boot — runs 15s after graphical.target

cat > /etc/systemd/system/protect-ui.service << 'EOF'
[Unit]
Description=Protect UI processes from OOM killer
After=graphical.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c '\
  for proc in gnome-shell gdm3 Xwayland gnome-session-b pipewire pipewire-pulse gnome-system-mo nautilus; do \
    for pid in $(pgrep -x "$proc" 2>/dev/null); do \
      echo -900 > /proc/$pid/oom_score_adj 2>/dev/null || true; \
    done; \
  done; \
  for pid in $(pgrep -x "code" 2>/dev/null); do \
    echo -500 > /proc/$pid/oom_score_adj 2>/dev/null || true; \
  done; \
  exit 0'

[Install]
WantedBy=graphical.target
EOF

cat > /etc/systemd/system/protect-ui.timer << 'EOF'
[Unit]
Description=Delay protect-ui until after desktop is ready

[Timer]
OnActiveSec=15
Unit=protect-ui.service

[Install]
WantedBy=graphical.target
EOF

systemctl enable protect-ui.timer

# ─── 13b. Fast boot: disable services that block the critical chain ───

# plymouth-quit-wait blocks multi-user.target for 20s+ waiting for splash to finish
systemctl mask plymouth-quit-wait.service 2>/dev/null || true

# NetworkManager-wait-online blocks boot waiting for full connectivity — not needed for desktop
systemctl disable NetworkManager-wait-online.service 2>/dev/null || true

# Disable NVIDIA HDA audio on dGPU (causes D3cold power state errors, no audio output on 940MX etc.)
if lspci | grep -qi 'nvidia.*audio'; then
  cat > /etc/udev/rules.d/99-nvidia-hda-disable.rules << 'EOF'
SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{remove}="1"
EOF
fi

# ─── 14. Blacklist NVIDIA only if no compatible driver exists ───────────

if [ -z "$NVIDIA_DRIVER" ] && lspci | grep -qi 'nvidia'; then
  cat > /etc/modprobe.d/blacklist-nvidia.conf << 'EOF'
# GPU not supported by available nvidia drivers — blacklist to prevent boot probe delays
blacklist nvidia
blacklist nvidia_drm
blacklist nvidia_modeset
blacklist nvidia_uvm
EOF
  update-initramfs -u
fi

# ─── 15. Boot diagnostics tool ────────────────────────────────────────

cat > /usr/local/bin/boot-diag << 'SCRIPT'
#!/bin/bash
OUT="/tmp/boot-diag-$(date +%Y%m%d-%H%M%S).log"
BOOT="-b 0"
[[ "$1" == "--previous" || "$1" == "-p" ]] && BOOT="-b -1"
{
echo "══ BOOT DIAGNOSTICS — $(date) ══"
echo -e "\n── Boot timing ──"
systemd-analyze 2>&1
systemd-analyze blame 2>&1 | head -20
echo -e "\n── Critical chain ──"
systemd-analyze critical-chain 2>&1 | head -30
echo -e "\n── Failed units ──"
systemctl --failed 2>&1
echo -e "\n── Boot errors ──"
journalctl $BOOT -p err --no-pager 2>&1
echo -e "\n── Shutdown errors (previous boot) ──"
journalctl -b -1 -p err --no-pager 2>&1 | tail -30
echo -e "\n── Active inhibitors ──"
systemd-inhibit --list 2>&1
echo -e "\n── Pending jobs ──"
systemctl list-jobs 2>&1
} > "$OUT" 2>&1
echo "Saved to: $OUT"
SCRIPT
chmod +x /usr/local/bin/boot-diag

# ─── 16. Done ─────────────────────────────────────────────────────────

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
