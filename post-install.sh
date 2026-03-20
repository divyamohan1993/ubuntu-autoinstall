#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
# Post-install script — runs on first boot after autoinstall
# Installs all extra repos, packages, and applies system optimizations
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

# NVIDIA CUDA
curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb \
  -o /tmp/cuda-keyring.deb
dpkg -i /tmp/cuda-keyring.deb

# MongoDB 8.0
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
  gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" \
  > /etc/apt/sources.list.d/mongodb-org-8.0.list

# HashiCorp (Terraform)
curl -fsSL https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com noble main" \
  > /etc/apt/sources.list.d/hashicorp.list

# Microsoft Edge
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | \
  gpg --dearmor -o /usr/share/keyrings/microsoft-edge.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-edge.gpg] https://packages.microsoft.com/repos/edge stable main" \
  > /etc/apt/sources.list.d/microsoft-edge.list

# R Project
curl -fsSL https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | \
  gpg --dearmor -o /usr/share/keyrings/r-project.gpg
echo "deb [signed-by=/usr/share/keyrings/r-project.gpg] https://cloud.r-project.org/bin/linux/ubuntu noble-cran40/" \
  > /etc/apt/sources.list.d/r-project.list

# Trivy (security scanner)
curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | \
  gpg --dearmor -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb noble main" \
  > /etc/apt/sources.list.d/trivy.list

# eza (modern ls)
curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | \
  gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
  > /etc/apt/sources.list.d/gierens.list

# Git PPA (latest git)
add-apt-repository -y ppa:git-core/ppa

# ─── 2. Install all packages ─────────────────────────────────────────

apt-get update

apt-get install -y \
  ansible \
  cmake \
  containerd.io \
  cuda-toolkit \
  curl \
  docker-buildx-plugin \
  docker-ce \
  docker-ce-cli \
  docker-ce-rootless-extras \
  docker-compose-plugin \
  eza \
  gfortran \
  git \
  git-delta \
  httpie \
  jq \
  libfftw3-dev \
  libgmp-dev \
  liblapack-dev \
  libmpc-dev \
  libmpfr-dev \
  libopenblas-dev \
  libopenmpi-dev \
  linux-generic-hwe-24.04 \
  lynx \
  microsoft-edge-stable \
  mongodb-org \
  ninja-build \
  nvidia-driver-535 \
  openmpi-bin \
  pipx \
  postgresql \
  postgresql-client \
  postgresql-contrib \
  pre-commit \
  python3-docx \
  python3-pip \
  python3-venv \
  r-base \
  redis-server \
  redis-tools \
  ripgrep \
  shellcheck \
  sqlite3 \
  stress-ng \
  terraform \
  tmux \
  tree \
  trivy \
  ubuntu-restricted-addons \
  xvfb \
  fzf \
  bat \
  fd-find

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

# ─── 4. AppArmor unprivileged userns (needed for some containers) ────

cat > /etc/sysctl.d/99-edge-sandbox.conf << 'EOF'
kernel.apparmor_restrict_unprivileged_userns = 0
EOF

# ─── 5. Add user to docker group ─────────────────────────────────────

usermod -aG docker dmj || true

# ─── 6. Install VS Code via snap ─────────────────────────────────────

snap install code --classic

# ─── 7. Install Node.js (via nvm — for the user) ─────────────────────
# This creates a helper script the user can source on first login
if [ ! -d /home/dmj/.nvm ]; then
  sudo -u dmj bash -c '
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    nvm install --lts
  '
fi

# ─── 8. Done ──────────────────────────────────────────────────────────

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
