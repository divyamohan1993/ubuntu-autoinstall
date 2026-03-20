# Ubuntu 24.04 LTS — Automated System Setup

Lean, automated Ubuntu 24.04 installation — drivers, Docker, core CLI tools, VS Code, Claude Code, and performance-tuned kernel settings. Everything else is available on-demand via `on-demand-install.sh`.

> **⚠️ SECURITY NOTICE:** Default credentials are **`dmj` / `dmj`** (intentionally public for quick setup).
> **Change your password immediately** after installation: `sudo passwd dmj`

---

## Table of Contents

- [What This Does](#what-this-does)
- [Files in This Repo](#files-in-this-repo)
- [Disk Partitioning](#disk-partitioning)
- [What Gets Installed (Base)](#what-gets-installed-base)
  - [Packages installed during OS install](#packages-installed-during-os-installation)
  - [External APT Repositories](#external-apt-repositories)
  - [Packages installed on first boot](#packages-installed-on-first-boot)
  - [Snap Packages](#snap-packages)
  - [Node.js + Claude Code](#nodejs--claude-code)
- [What Gets Removed](#what-gets-removed)
- [On-Demand Packages](#on-demand-packages)
- [System Settings Changed](#system-settings-changed)
  - [Memory & Swap Tuning](#memory--swap-tuning)
  - [Network Optimization](#network-optimization)
  - [Filesystem & Kernel Tuning](#filesystem--kernel-tuning)
  - [Security Settings](#security-settings)
  - [Filesystem Mounts (fstab)](#filesystem-mounts-fstab)
  - [User & Group Changes](#user--group-changes)
  - [Systemd Services](#systemd-services)
  - [Login Banner](#login-banner)
- [How to Use](#how-to-use)
  - [Option A: Ventoy USB (recommended)](#option-a-ventoy-usb-recommended)
  - [Option B: Rufus USB](#option-b-rufus-usb)
  - [Option C: Custom ISO (advanced)](#option-c-custom-iso-advanced)
  - [Boot and Walk Away](#boot-and-walk-away)
  - [Monitor Progress](#monitor-progress)
  - [Reboot and Secure](#reboot-and-secure)
- [How the Auto-Fetch Works](#how-the-auto-fetch-works)
- [Customization Guide](#customization-guide)
- [Troubleshooting](#troubleshooting)
- [Requirements](#requirements)
- [License](#license)

---

## What This Does

In one unattended installation, this setup:

1. **Partitions your disk** — EFI, root, experiments (NTFS), and swap
2. **Installs Ubuntu 24.04 LTS** with SSH server enabled
3. **Fetches the post-install script from this GitHub repo** (no extra files needed on USB)
4. **On first boot**, automatically:
   - Installs drivers (NVIDIA GPU + HWE kernel)
   - Sets up Docker (Engine, CLI, Compose, Buildx)
   - Installs core CLI tools (ripgrep, fzf, bat, eza, git-delta, etc.)
   - Installs VS Code, Node.js (LTS), and Claude Code
   - Removes Firefox (replaced by Edge)
   - Applies kernel/network/memory performance optimizations

**Everything else** (databases, CUDA toolkit, ML libraries, R, Terraform, etc.) is **not installed by default** but can be added in one command via `on-demand-install.sh`.

---

## Files in This Repo

| File | Purpose | When It Runs |
|------|---------|--------------|
| [`autoinstall.yaml`](autoinstall.yaml) | Ubuntu autoinstall config — disk layout, locale, identity, minimal base packages | During OS installation (Subiquity installer) |
| [`post-install.sh`](post-install.sh) | First-boot script — drivers, Docker, core CLI, VS Code, Claude Code, sysctl optimizations | On first boot (one-shot systemd service) |
| [`on-demand-install.sh`](on-demand-install.sh) | Optional extras installer — databases, CUDA, ML libs, R, Terraform, etc. | Manually, whenever you need something |
| [`README.md`](README.md) | This documentation | — |

---

## Disk Partitioning

The installer targets the **largest disk** on the system and creates:

| Partition | Size | Filesystem | Mount Point | Purpose |
|-----------|------|------------|-------------|---------|
| Part 1 | 1 GB | FAT32 (EFI) | `/boot/efi` | UEFI boot partition |
| Part 2 | 100 GB | ext4 | `/` | Root filesystem (Ubuntu OS) |
| Part 3 | 100 GB | NTFS | `/mnt/experiments` | Data partition (cross-compatible with Windows) |
| Part 4 | Remainder (~22 GB on 224 GB disk) | swap | `[SWAP]` | Swap space |

Additional mounts in `/etc/fstab`:
- `/tmp` → `tmpfs` (4 GB, RAM-backed, `noatime,nosuid,nodev`)

> **Note:** The experiments partition uses NTFS for dual-boot Windows/Linux compatibility.

---

## What Gets Installed (Base)

### Packages installed during OS installation

Installed by the Ubuntu installer itself (before first boot):

| Package | What It Is |
|---------|-----------|
| `git` | Version control |
| `curl` | HTTP client |
| `jq` | JSON processor |
| `tmux` | Terminal multiplexer |
| `tree` | Directory listing |
| `python3-pip` | Python package manager |
| `python3-venv` | Python virtual environments |
| `ntfs-3g` | NTFS filesystem support (required for experiments partition) |

### External APT Repositories

Only essential repos are added:

| Repository | Source URL | What It Provides |
|------------|-----------|-----------------|
| **Docker CE** | `download.docker.com/linux/ubuntu` | Docker Engine, CLI, Compose, Buildx |
| **NVIDIA** | `developer.download.nvidia.com/compute/cuda/repos/ubuntu2404` | GPU driver (not full CUDA toolkit) |
| **Microsoft Edge** | `packages.microsoft.com/repos/edge` | Edge browser (replaces Firefox) |
| **eza** | `deb.gierens.de` | Modern `ls` replacement |
| **Git PPA** | `ppa:git-core/ppa` | Latest Git version |

### Packages installed on first boot

#### Drivers & Kernel
| Package | What It Is |
|---------|-----------|
| `nvidia-driver-535` | NVIDIA GPU driver |
| `linux-generic-hwe-24.04` | Hardware Enablement kernel (latest hardware support) |

#### Containers
| Package | What It Is |
|---------|-----------|
| `docker-ce` | Docker Engine |
| `docker-ce-cli` | Docker CLI |
| `containerd.io` | Container runtime |
| `docker-compose-plugin` | Docker Compose v2 |
| `docker-buildx-plugin` | Docker Buildx (multi-platform builds) |

#### CLI Tools
| Package | What It Is |
|---------|-----------|
| `git` | Version control (latest from PPA) |
| `git-delta` | Beautiful git diffs |
| `ripgrep` | Fast grep (`rg`) |
| `fzf` | Fuzzy finder |
| `bat` | `cat` with syntax highlighting |
| `fd-find` | Fast `find` alternative (`fdfind`) |
| `eza` | Modern `ls` replacement (colors, git integration) |
| `jq` | JSON processor |
| `tmux` | Terminal multiplexer |
| `tree` | Directory tree listing |
| `pipx` | Install Python CLI tools in isolation |

#### Browser
| Package | What It Is |
|---------|-----------|
| `microsoft-edge-stable` | Microsoft Edge (replaces Firefox) |

### Snap Packages

| Package | What It Provides |
|---------|-----------------|
| `code --classic` | Visual Studio Code |

### Node.js + Claude Code

| Tool | Install Method | What It Is |
|------|---------------|-----------|
| **nvm** v0.40.3 | curl script | Node Version Manager |
| **Node.js LTS** | nvm | JavaScript runtime |
| **`@anthropic-ai/claude-code`** | npm (global) | Claude Code CLI — AI coding agent for the terminal |
| **`anthropic.claude-code`** | VS Code extension | Claude Code for VS Code — AI pair programming |

- **CLI:** Run `claude` in any terminal
- **VS Code:** Extension appears in the sidebar
- **API key:** Set on first use: `export ANTHROPIC_API_KEY=sk-...` or log in via `claude`

---

## What Gets Removed

| Package | Why |
|---------|-----|
| `firefox` (snap) | Replaced by Microsoft Edge |

---

## On-Demand Packages

Everything below is **NOT installed by default**. Install what you need using:

```bash
# Download the on-demand installer
curl -fsSL https://raw.githubusercontent.com/divyamohan1993/ubuntu-autoinstall/main/on-demand-install.sh -o on-demand-install.sh
chmod +x on-demand-install.sh

# Install specific categories
./on-demand-install.sh databases
./on-demand-install.sh cuda ml-libs

# Or install everything at once
./on-demand-install.sh all
```

| Category | Command | What It Installs |
|----------|---------|-----------------|
| `databases` | `./on-demand-install.sh databases` | PostgreSQL (server + client + contrib), MongoDB 8.0, Redis (server + tools), SQLite3 |
| `cuda` | `./on-demand-install.sh cuda` | NVIDIA CUDA toolkit (driver already installed) |
| `ml-libs` | `./on-demand-install.sh ml-libs` | OpenBLAS, LAPACK, FFTW3, OpenMPI, gfortran |
| `r-lang` | `./on-demand-install.sh r-lang` | R programming language (from CRAN) |
| `infra` | `./on-demand-install.sh infra` | Terraform, Ansible |
| `security` | `./on-demand-install.sh security` | Trivy container vulnerability scanner |
| `firefox` | `./on-demand-install.sh firefox` | Firefox browser (if you want it back) |
| `build-tools` | `./on-demand-install.sh build-tools` | CMake, Ninja, Shellcheck, pre-commit |
| `extras` | `./on-demand-install.sh extras` | httpie, lynx, stress-ng, xvfb, python3-docx |
| `math-libs` | `./on-demand-install.sh math-libs` | libgmp, libmpfr, libmpc |
| `codecs` | `./on-demand-install.sh codecs` | Ubuntu restricted addons (multimedia codecs) |
| `all` | `./on-demand-install.sh all` | Everything above |

You can combine categories: `./on-demand-install.sh databases cuda ml-libs`

---

## System Settings Changed

Every system setting modified by this setup is documented below. Nothing is hidden.

### Memory & Swap Tuning

**File:** `/etc/sysctl.d/99-ml-performance.conf`

| Setting | Value | Default | What It Does |
|---------|-------|---------|-------------|
| `vm.swappiness` | `1` | `60` | Almost never swap to disk — prefer keeping data in RAM |
| `vm.vfs_cache_pressure` | `50` | `100` | Keep filesystem caches in memory longer |
| `vm.dirty_ratio` | `40` | `20` | Allow up to 40% of RAM for dirty (unwritten) pages before forcing writes |
| `vm.dirty_background_ratio` | `5` | `10` | Start background writeback at 5% dirty pages |
| `vm.overcommit_memory` | `1` | `0` | Always allow memory allocation (useful for ML workloads and `fork()`) |
| `vm.min_free_kbytes` | `1048576` (1 GB) | `67584` | Keep at least 1 GB free for kernel emergency allocations |
| `vm.admin_reserve_kbytes` | `524288` (512 MB) | `8192` | Reserve 512 MB for root processes |
| `vm.user_reserve_kbytes` | `524288` (512 MB) | `131072` | Reserve 512 MB for user recovery |
| `vm.oom_kill_allocating_task` | `1` | `0` | Kill the process that triggered OOM (not a random one) |
| `vm.panic_on_oom` | `0` | `0` | Don't kernel panic on OOM — just kill the offending process |
| `vm.zone_reclaim_mode` | `0` | `0` | Don't aggressively reclaim NUMA zones (better for single-socket systems) |

**File:** `/etc/sysctl.d/99-performance.conf`

| Setting | Value | Default | What It Does |
|---------|-------|---------|-------------|
| `vm.min_free_kbytes` | `1572864` (1.5 GB) | `67584` | Keep 1.5 GB free for kernel + UI responsiveness |
| `vm.overcommit_memory` | `0` | `0` | Heuristic overcommit (default safe mode) |
| `vm.overcommit_ratio` | `95` | `50` | Allow committing up to 95% of RAM + swap |

> **Note:** `99-performance.conf` loads after `99-ml-performance.conf` (alphabetical), so where settings overlap (e.g. `vm.min_free_kbytes`), `99-performance.conf` wins.

### Network Optimization

**File:** `/etc/sysctl.d/99-ml-performance.conf`

| Setting | Value | Default | What It Does |
|---------|-------|---------|-------------|
| `net.core.default_qdisc` | `fq` | `fq_codel` | Fair Queue scheduler — required for BBR |
| `net.ipv4.tcp_congestion_control` | `bbr` | `cubic` | Google's BBR — higher throughput, lower latency |
| `net.core.rmem_max` | `16777216` (16 MB) | `212992` | Maximum receive socket buffer |
| `net.core.wmem_max` | `16777216` (16 MB) | `212992` | Maximum send socket buffer |
| `net.core.rmem_default` | `1048576` (1 MB) | `212992` | Default receive buffer |
| `net.core.wmem_default` | `1048576` (1 MB) | `212992` | Default send buffer |
| `net.ipv4.tcp_rmem` | `4096 87380 16777216` | `4096 131072 6291456` | TCP receive buffer: min / default / max |
| `net.ipv4.tcp_wmem` | `4096 65536 16777216` | `4096 16384 4194304` | TCP send buffer: min / default / max |
| `net.ipv4.tcp_fastopen` | `3` | `1` | TCP Fast Open for client and server |
| `net.ipv4.tcp_mtu_probing` | `1` | `0` | Auto-discover optimal MTU size |
| `net.ipv4.tcp_slow_start_after_idle` | `0` | `1` | Don't reset congestion window after idle |
| `net.core.netdev_max_backlog` | `16384` | `1000` | Larger network device backlog queue |
| `net.core.somaxconn` | `8192` | `4096` | Maximum socket listen backlog |
| `net.ipv4.tcp_max_syn_backlog` | `8192` | `1024` | Maximum SYN queue |
| `net.ipv4.tcp_window_scaling` | `1` | `1` | TCP window scaling for high bandwidth |
| `net.ipv4.tcp_timestamps` | `1` | `1` | Better RTT estimation |
| `net.ipv4.tcp_sack` | `1` | `1` | Selective ACKs — faster packet loss recovery |
| `net.ipv4.tcp_no_metrics_save` | `1` | `0` | Don't cache TCP metrics between connections |
| `net.ipv4.tcp_tw_reuse` | `1` | `2` | Reuse TIME_WAIT sockets (less port exhaustion) |

### Filesystem & Kernel Tuning

**File:** `/etc/sysctl.d/99-performance.conf`

| Setting | Value | Default | What It Does |
|---------|-------|---------|-------------|
| `fs.inotify.max_user_watches` | `524288` | `65536` | More inotify watches (VS Code, webpack, etc.) |
| `fs.inotify.max_user_instances` | `1024` | `128` | More inotify instances |
| `fs.file-max` | `2097152` | `9223372036854775807` | System-wide max open files (2 million) |
| `kernel.sysrq` | `1` | `176` | Enable all Magic SysRq key functions |

### Security Settings

**File:** `/etc/sysctl.d/99-edge-sandbox.conf`

| Setting | Value | Default | What It Does |
|---------|-------|---------|-------------|
| `kernel.apparmor_restrict_unprivileged_userns` | `0` | `1` | Allow unprivileged user namespaces (required for Edge/Chromium sandbox and containers) |

### Filesystem Mounts (fstab)

| Mount | Filesystem | Options | Purpose |
|-------|------------|---------|---------|
| `/` | ext4 | `noatime,errors=remount-ro` | Root — `noatime` skips unnecessary disk writes |
| `/boot/efi` | vfat | `umask=0077` | EFI boot partition |
| `/mnt/experiments` | ntfs3 | `noatime,uid=1000,gid=1000,nofail` | Data partition — owned by first user, won't block boot if missing |
| `/tmp` | tmpfs | `noatime,nosuid,nodev,size=4G` | RAM-backed temp dir — fast, auto-cleared on reboot |

### User & Group Changes

| Change | What It Does |
|--------|-------------|
| `usermod -aG docker dmj` | Run `docker` commands without `sudo` |

### Systemd Services

| Service | What It Does |
|---------|-------------|
| `post-install.service` | One-shot service that runs `post-install.sh` on first boot, then disables and removes itself |

### Login Banner

A password-change reminder appears on every login until removed:
```
╔══════════════════════════════════════════════════════════════╗
║  ⚠️  DEFAULT PASSWORD IN USE — CHANGE IT NOW:               ║
║     sudo passwd dmj                                        ║
╚══════════════════════════════════════════════════════════════╝
```
Remove after changing password: `sudo rm /etc/profile.d/change-password-reminder.sh`

---

## How to Use

### Option A: Ventoy USB (recommended)

[Ventoy](https://www.ventoy.net) lets you boot multiple ISOs from one USB and supports autoinstall natively.

1. Install Ventoy on a USB drive
2. Download the [Ubuntu 24.04 Server ISO](https://ubuntu.com/download/server)
3. Copy these files to the USB:

```
USB drive/
├── ventoy/
│   └── ventoy.json
├── ubuntu-24.04-live-server-amd64.iso
└── autoinstall.yaml
```

**`ventoy/ventoy.json`:**
```json
{
  "control": [
    {
      "VTOY_DEFAULT_SEARCH_ROOT": "/",
      "VTOY_DEFAULT_MENU_MODE": "0"
    }
  ],
  "auto_install": [
    {
      "image": "/ubuntu-24.04-live-server-amd64.iso",
      "template": "/autoinstall.yaml"
    }
  ]
}
```

### Option B: Rufus USB

[Rufus](https://rufus.ie) is a popular Windows tool for creating bootable USB drives.

1. Download [Rufus](https://rufus.ie) and the [Ubuntu 24.04 Server ISO](https://ubuntu.com/download/server)
2. Open Rufus, select the ISO, and flash it to your USB drive
   - Partition scheme: **GPT**
   - Target system: **UEFI**
   - File system: **FAT32**
3. After flashing, place `autoinstall.yaml` on the USB:
   - **Root of the USB**, or create `autoinstall/` directory and place it inside as `user-data`
4. If the USB is read-only after flashing (ISO9660):
   - **Recommended:** Use Rufus in **DD mode** instead of ISO mode
   - **Alternative:** Repack the ISO (see below)

> **Tip:** Ventoy is generally easier because it doesn't modify the ISO.

### Option C: Custom ISO (advanced)

Bake `autoinstall.yaml` directly into the ISO:

```bash
mkdir /tmp/iso-extract
7z x ubuntu-24.04-live-server-amd64.iso -o/tmp/iso-extract
cp autoinstall.yaml /tmp/iso-extract/

xorriso -as mkisofs \
  -r -V "Ubuntu Auto" \
  --grub2-mbr /tmp/iso-extract/boot/1-Boot-NoEmul.img \
  -partition_offset 16 \
  --mbr-force-bootable \
  -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b \
  /tmp/iso-extract/boot/2-Boot-NoEmul.img \
  -appended_part_as_gpt \
  -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
  -c '/boot.catalog' \
  -b '/boot/1-Boot-NoEmul.img' \
  -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
  -eltorito-alt-boot \
  -e '--interval:appended_partition_2:::' \
  -no-emul-boot \
  -o /tmp/ubuntu-24.04-autoinstall.iso \
  /tmp/iso-extract
```

### Boot and Walk Away

1. Plug in USB → Boot from it (F12/F2/Del for boot menu)
2. If Ventoy, select the Ubuntu ISO
3. Installer runs **fully unattended**
4. System reboots when done

### Monitor Progress

Post-install runs on first boot (~10–20 minutes with good internet):

```bash
journalctl -u post-install.service -f
# or
tail -f /var/log/post-install.log
```

### Reboot and Secure

```bash
sudo reboot                                          # Load NVIDIA drivers + new kernel
sudo passwd dmj                                      # CHANGE THE DEFAULT PASSWORD
sudo rm /etc/profile.d/change-password-reminder.sh   # Remove the login nag
```

---

## How the Auto-Fetch Works

```yaml
late-commands:
  - curtin in-target -- curl -fsSL \
      https://raw.githubusercontent.com/divyamohan1993/ubuntu-autoinstall/main/post-install.sh \
      -o /root/post-install.sh
```

- **Only `autoinstall.yaml` needed on USB**
- **`post-install.sh` fetched from GitHub** at install time
- **Update once, deploy everywhere** — edit on GitHub, every future install gets latest
- **Requires internet** during installation

---

## Customization Guide

| Want to... | Do this |
|------------|---------|
| Change disk sizes | Edit `size:` under `storage.config` in `autoinstall.yaml` |
| Change username | Replace `dmj` in both `autoinstall.yaml` and `post-install.sh` |
| Change password | `openssl passwd -6 'newpass'` → replace hash in `autoinstall.yaml` |
| Skip NVIDIA driver | Remove `nvidia-driver-535` from `post-install.sh` |
| Add to base install | Add packages to `apt-get install` in `post-install.sh` |
| Add desktop GUI | Add `apt-get install -y ubuntu-desktop-minimal` to `post-install.sh` |
| Change sysctl values | Edit `cat > /etc/sysctl.d/...` blocks in `post-install.sh` |
| Target specific disk | Change `match: size: largest` to `match: serial: YOUR_SERIAL` |
| Fork for your use | Fork repo, update raw GitHub URL in `autoinstall.yaml` |

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Post-install didn't run | `systemctl status post-install.service` and check `/var/log/post-install.log` |
| No internet during install | Connect Ethernet before booting. WiFi may not work during server install. |
| Wrong disk selected | Use `match: serial: YOUR_SERIAL` instead of `match: size: largest` |
| NVIDIA driver issues | Reboot after post-install. Check `nvidia-smi`. May need Secure Boot disabled. |
| Experiments not mounting | `blkid` to find UUID, update `/etc/fstab` |
| Rufus USB read-only | Use Ventoy or Rufus DD mode |
| Autoinstall not detected | Ensure `autoinstall.yaml` is in USB root |
| Hangs at "Continue with autoinstall?" | Normal — press Enter or wait 30s |

---

## Requirements

- **Disk:** Minimum 224 GB (1 GB EFI + 100 GB root + 100 GB experiments + swap)
- **RAM:** 4 GB minimum, 16+ GB recommended
- **Internet:** Required during installation
- **Boot mode:** UEFI (not legacy BIOS)
- **Architecture:** x86_64 / amd64 only

---

## License

Provided as-is for personal and educational use. No warranty. Use at your own risk.

**Built for Ubuntu 24.04 LTS (Noble Numbat) on x86_64.**
