# Ubuntu 24.04 LTS — Automated System Setup

Lean, automated Ubuntu 24.04+ installation — always the **latest versions** of everything, auto-detected at install time. Drivers, Docker, Edge, build tools (gcc, cmake), CLI tools, VS Code, Claude Code, and performance-tuned kernel. Bloatware removed. Aggressive auto-updates keep everything current after install. Future-proofed for Ubuntu 26.04 LTS.

> **⚠️ SECURITY NOTICE:** Default credentials are **`dmj` / `dmj`** (intentionally public for quick setup).
> **Change your password immediately** after installation: `sudo passwd dmj`

---

## Table of Contents

- [What This Does](#what-this-does)
- [Files in This Repo](#files-in-this-repo)
- [Disk Partitioning](#disk-partitioning)
- [What Gets Installed (Base)](#what-gets-installed-base)
- [What Gets Removed](#what-gets-removed)
- [What Gets Kept (Ubuntu defaults)](#what-gets-kept-ubuntu-defaults)
- [On-Demand Packages](#on-demand-packages)
- [Auto-Updates](#auto-updates)
- [System Settings Changed](#system-settings-changed)
- [How to Use](#how-to-use)
- [How the Auto-Fetch Works](#how-the-auto-fetch-works)
- [Customization Guide](#customization-guide)
- [Troubleshooting](#troubleshooting)
- [Requirements](#requirements)
- [Contributing](#contributing)
- [License](#license)

---

## What This Does

In one unattended installation, this setup:

1. **Partitions your disk** — EFI, root, experiments (NTFS), and swap
2. **Installs Ubuntu 24.04 LTS** with SSH server enabled
3. **Fetches the post-install script from this GitHub repo** (no extra files needed on USB)
4. **On first boot**, automatically:
   - Auto-detects and installs the **latest** NVIDIA GPU driver + HWE kernel
   - Sets up Docker (Engine, CLI, Compose, Buildx)
   - Installs Microsoft Edge (replaces Firefox) + AppArmor sandbox fix
   - Installs **latest** gcc/g++ (from Ubuntu Toolchain PPA) + CMake (from Kitware repo) + Ninja
   - Installs core CLI tools (ripgrep, fzf, bat, eza, git-delta, etc.)
   - Installs VS Code, **latest** Node.js (via nvm), and Claude Code (CLI + extension)
   - Configures Claude Code: agent teams, 12 official plugins, marketplace
   - Removes bloatware (LibreOffice, Thunderbird, games, etc.)
   - Runs `apt dist-upgrade` to pull all latest package versions
   - Applies kernel/network/memory performance optimizations
   - Disables 60-second shutdown confirmation dialog
   - Configures **aggressive auto-updates** for all packages from all repos
   - Sets up catch-up updates on boot and network reconnect
   - Shows a password-change reminder on every login

**Everything else** (databases, CUDA toolkit, ML libraries, R, Terraform, office apps, etc.) can be added via the **interactive on-demand installer**.

### Philosophy: Always Latest

All versions are **auto-detected at runtime**. Fallbacks exist only if auto-detection fails (e.g., no internet during detection). At install time, the script auto-detects:
- **NVIDIA driver** — picks the highest numbered driver in apt
- **GCC** — picks the latest major version available
- **nvm** — fetches the latest release tag from GitHub API
- **Node.js** — installs latest (not LTS)
- **CMake** — from Kitware's repo (always ahead of Ubuntu's)
- **Everything else** — `apt dist-upgrade` before install ensures all packages are newest

---

## Files in This Repo

| File | Purpose | When It Runs |
|------|---------|--------------|
| [`autoinstall.yaml`](autoinstall.yaml) | Ubuntu autoinstall config — disk layout, locale, identity, minimal base packages | During OS installation (Subiquity installer) |
| [`post-install.sh`](post-install.sh) | First-boot script — drivers, Docker, Edge, CLI tools, VS Code, Claude Code, sysctl tuning, bloatware removal | On first boot (one-shot systemd service, self-deletes after) |
| [`on-demand-install.sh`](on-demand-install.sh) | Interactive optional package installer — 20 categories including databases, CUDA, ML libs, office apps, media players | Manually, whenever you need something |
| [`README.md`](README.md) | This documentation | — |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | How to contribute | — |
| [`LICENSE`](LICENSE) | MIT License | — |
| [`SECURITY.md`](SECURITY.md) | Security policy | — |
| [`CHANGELOG.md`](CHANGELOG.md) | Version history | — |

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

| Mount | Type | Options | Purpose |
|-------|------|---------|---------|
| `/` | ext4 | `noatime,errors=remount-ro` | `noatime` reduces unnecessary disk writes |
| `/mnt/experiments` | ntfs3 | `noatime,uid=1000,gid=1000,nofail` | Owned by first user, won't block boot if missing |
| `/tmp` | tmpfs | `noatime,nosuid,nodev,size=4G` | RAM-backed, fast, auto-cleared on reboot |

> **Note:** The experiments partition uses NTFS for dual-boot Windows/Linux compatibility.

---

## What Gets Installed (Base)

### During OS installation (autoinstall.yaml)

| Package | What It Is |
|---------|-----------|
| `git` | Version control |
| `curl` | HTTP client |
| `jq` | JSON processor |
| `tmux` | Terminal multiplexer |
| `tree` | Directory listing |
| `python3-pip` | Python package manager |
| `python3-venv` | Python virtual environments |
| `ntfs-3g` | NTFS filesystem support |

### On first boot (post-install.sh)

#### Drivers & Kernel
| Package | What It Is |
|---------|-----------|
| `nvidia-driver-*` | **Latest** NVIDIA GPU driver (auto-detected) |
| `linux-generic-hwe-*` | Hardware Enablement kernel (auto-derived from Ubuntu version) |

#### Build Tools (C/C++)
| Package | What It Is |
|---------|-----------|
| `build-essential` | gcc, g++, make, libc headers |
| `gcc-*` / `g++-*` | **Latest** GCC/G++ (auto-detected, set as default via update-alternatives) |
| `cmake` | **Latest** CMake (from Kitware repo) |
| `ninja-build` | Fast parallel build system |

#### Docker
| Package | What It Is |
|---------|-----------|
| `docker-ce` | Docker Engine |
| `docker-ce-cli` | Docker CLI |
| `containerd.io` | Container runtime |
| `docker-compose-plugin` | Docker Compose v2 |
| `docker-buildx-plugin` | Multi-platform builds |

#### CLI Tools
| Package | What It Is |
|---------|-----------|
| `git` | **Latest** from PPA |
| `git-delta` | Beautiful git diffs |
| `ripgrep` | Fast grep (`rg`) |
| `fzf` | Fuzzy finder |
| `bat` | `cat` with syntax highlighting |
| `fd-find` | Fast `find` alternative |
| `eza` | Modern `ls` (colors, git integration) |
| `jq` | JSON processor |
| `tmux` | Terminal multiplexer |
| `tree` | Directory tree listing |
| `pipx` | Isolated Python CLI tools |

#### Browser
| Package | What It Is |
|---------|-----------|
| `microsoft-edge-stable` | Microsoft Edge (replaces Firefox) |

#### System packages
| Package | What It Is |
|---------|-----------|
| `anacron` | Runs missed cron jobs after boot (for catch-up updates) |

#### Snap packages
| Package | What It Is |
|---------|-----------|
| `code --classic` | Visual Studio Code |

#### Node.js + Claude Code
| Tool | Install Method | What It Is |
|------|---------------|-----------|
| **nvm** (latest) | curl script, version auto-fetched from GitHub API | Node Version Manager |
| **Node.js** (latest, not LTS) | `nvm install node` | JavaScript runtime |
| **`@anthropic-ai/claude-code`** | npm (global) | Claude Code CLI — AI coding agent |
| **`anthropic.claude-code`** | VS Code extension | Claude Code for VS Code |

Claude Code is pre-configured with:
- Agent teams enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)
- Official plugin marketplace (`anthropics/claude-plugins-official`)
- 12 plugins pre-enabled (code-review, github, playwright, security-guidance, etc.)

#### External APT Repositories added
| Repository | What It Provides |
|------------|-----------------|
| **Docker CE** (`download.docker.com`) | Docker Engine, CLI, Compose, Buildx |
| **NVIDIA** (`developer.download.nvidia.com`) | GPU driver |
| **Microsoft Edge** (`packages.microsoft.com`) | Edge browser |
| **Kitware** (`apt.kitware.com`) | Latest CMake |
| **Ubuntu Toolchain PPA** (`ppa:ubuntu-toolchain-r/test`) | Latest GCC/G++ |
| **eza** (`deb.gierens.de`) | Modern `ls` |
| **Git PPA** (`ppa:git-core/ppa`) | Latest Git |

---

## What Gets Removed

### Snap
| Package | Why |
|---------|-----|
| `firefox` | Replaced by Microsoft Edge |

### Apt packages
| Package | What It Was |
|---------|------------|
| `libreoffice-*` | Office suite (available on-demand as `office`) |
| `thunderbird` | Email client (available on-demand as `email`) |
| `gnome-games`, `aisleriot`, `gnome-mahjongg`, `gnome-mines`, `gnome-sudoku` | Games |
| `rhythmbox` | Music player (available on-demand as `media`) |
| `shotwell` | Photo manager (available on-demand as `photo`) |
| `cheese` | Webcam app (available on-demand as `photo`) |
| `totem`, `totem-plugins` | Video player (available on-demand as `media`) |
| `remmina` | Remote desktop (available on-demand as `remote`) |
| `transmission-gtk` | Torrent client (available on-demand as `torrent`) |
| `simple-scan` | Scanner app (available on-demand as `scanner`) |
| `gnome-todo`, `gnome-contacts`, `gnome-calendar`, `gnome-maps`, `gnome-weather`, `gnome-clocks` | GNOME apps (available on-demand as `gnome-apps`) |
| `gnome-font-viewer`, `gnome-logs` | Rarely used utilities |
| `brltty` | Braille display driver |
| `orca`, `gnome-accessibility-themes` | Accessibility (available on-demand as `accessibility`) |
| `update-manager` | GUI updater (App Center handles this) |
| `language-selector-gnome` | Language settings (set once during install) |
| `yelp` | GNOME Help system |

---

## What Gets Kept (Ubuntu defaults)

These Ubuntu defaults are **not removed**:

| App | Why It Stays |
|-----|-------------|
| **Files** (Nautilus) | File manager — essential |
| **Settings** | System settings — essential |
| **Terminal** | Essential |
| **Text Editor** | Quick file editing |
| **Calculator** | Basic utility |
| **System Monitor** | Process/resource monitoring |
| **Utilities** | Archive manager, etc. |
| **Startup Applications** | Manage login startup items |
| **Disk Usage Analyzer** (Baobab) | Find what's eating disk space |
| **Document Viewer** (Evince) | PDF viewer |
| **Image Viewer** (Eye of GNOME) | View images |
| **Passwords & Keys** (Seahorse) | SSH/GPG key management |
| **Characters** | Emoji and special character picker |
| **Power Manager** | Battery/power profiles (laptop) |
| **USB Startup Disk Creator** | Create bootable USBs |
| **Speech Dispatcher** | Text-to-speech backend |
| **App Center** (GNOME Software) | GUI package installer — fallback |
| **Software & Updates** | Repository and driver management |
| **NVIDIA tools** | Nsight, X Server Settings (come with driver) |
| **All default snaps** (except Firefox) | snap-store, firmware-updater, etc. |

---

## On-Demand Packages

Everything removed from base is available via the **interactive on-demand installer**:

### Interactive mode (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/divyamohan1993/ubuntu-autoinstall/main/on-demand-install.sh -o on-demand-install.sh
chmod +x on-demand-install.sh
./on-demand-install.sh
```

This shows a colored, numbered menu:
```
  ┌──────────────────────────────────────────────┐
  │       On-Demand Package Installer            │
  └──────────────────────────────────────────────┘

  #   Category                  Packages
  1   Databases                 PostgreSQL, MongoDB 8.0, Redis, SQLite
  2   CUDA Toolkit              NVIDIA CUDA development toolkit
  3   ML / Science Libraries    OpenBLAS, LAPACK, FFTW3, OpenMPI, gfortran
  ...
  20  Accessibility             Orca, accessibility themes

  A   Install ALL
  Q   Quit

  Enter choices (e.g. 1 3 5): _
```

### CLI mode

```bash
./on-demand-install.sh databases cuda ml-libs    # specific categories
./on-demand-install.sh all                        # everything
./on-demand-install.sh --help                     # show all categories
```

### All 20 categories

| # | Category | ID | What It Installs |
|---|----------|----|-----------------|
| 1 | Databases | `databases` | PostgreSQL, MongoDB 8.0, Redis, SQLite |
| 2 | CUDA Toolkit | `cuda` | NVIDIA CUDA toolkit (driver already installed) |
| 3 | ML / Science Libraries | `ml-libs` | OpenBLAS, LAPACK, FFTW3, OpenMPI, gfortran |
| 4 | R Language | `r-lang` | R from CRAN |
| 5 | Infrastructure Tools | `infra` | Terraform, Ansible |
| 6 | Security Scanner | `security` | Trivy |
| 7 | Build Tools | `build-tools` | CMake, Ninja, Shellcheck, pre-commit |
| 8 | Math Libraries | `math-libs` | libgmp, libmpfr, libmpc |
| 9 | Office Suite | `office` | LibreOffice |
| 10 | Email Client | `email` | Thunderbird |
| 11 | Media Players | `media` | Totem, Rhythmbox |
| 12 | Photo Tools | `photo` | Shotwell, Cheese |
| 13 | Remote Desktop | `remote` | Remmina |
| 14 | Torrent Client | `torrent` | Transmission |
| 15 | Firefox | `firefox` | Firefox browser |
| 16 | Scanner | `scanner` | Simple Scan |
| 17 | Multimedia Codecs | `codecs` | Ubuntu restricted addons (MP3, H.264, etc.) |
| 18 | CLI Extras | `extras` | httpie, lynx, stress-ng, xvfb, python3-docx |
| 19 | GNOME Apps | `gnome-apps` | Calendar, Contacts, Maps, Weather, Clocks, Todo |
| 20 | Accessibility | `accessibility` | Orca, accessibility themes |

Features:
- Select by number (`1 3 5`), range (`1-5`), name (`databases`), or `all`
- Each package installs individually — failures don't stop the rest
- Color-coded summary at the end: what succeeded, what failed, retry commands
- Supports combining: `./on-demand-install.sh databases cuda ml-libs`

---

## Auto-Updates

After installation, **everything auto-updates to the latest version** as soon as it's released. No manual intervention needed.

### What updates and when

| What | How | When |
|------|-----|------|
| All APT packages (Ubuntu, Docker, NVIDIA, Edge, CMake, gcc, git, etc.) | `unattended-upgrades` with `origin=*` | Daily |
| Snap packages (VS Code, snap-store, etc.) | `snapd refresh` | Twice daily (midnight–4 AM) |
| Node.js | `nvm install node` via cron | Daily |
| npm globals (Claude Code, etc.) | `npm update -g` via cron | Daily |

### If the laptop was off or offline

| Scenario | What catches up |
|----------|----------------|
| Laptop boots after being off | `catch-up-updates.service` runs 60s after network is up |
| WiFi/Ethernet reconnects after being offline | NetworkManager hook checks if last update was >6h ago, triggers catch-up |
| Missed daily cron jobs | `anacron` re-runs them after boot |

### Auto-reboot

If a kernel or driver update requires a reboot, the system **auto-reboots at 4:00 AM**. Config files are preserved (`--force-confold`).

### Logs

| Log | What It Contains |
|-----|-----------------|
| `/var/log/unattended-upgrades/` | APT auto-update history |
| `/var/log/node-auto-update.log` | Node.js and npm update history |
| `/var/log/catch-up-updates.log` | Boot/reconnect catch-up activity |

---

## System Settings Changed

Every system setting modified by this setup is documented below. Nothing is hidden.

### Memory & Swap Tuning

**File:** `/etc/sysctl.d/99-ml-performance.conf`

| Setting | Value | Default | What It Does |
|---------|-------|---------|-------------|
| `vm.swappiness` | `1` | `60` | Almost never swap — prefer RAM |
| `vm.vfs_cache_pressure` | `50` | `100` | Keep filesystem caches longer |
| `vm.dirty_ratio` | `40` | `20` | Allow 40% RAM for dirty pages before forcing writes |
| `vm.dirty_background_ratio` | `5` | `10` | Start background writeback at 5% |
| `vm.overcommit_memory` | `1` | `0` | Always allow allocation (useful for ML/fork) |
| `vm.min_free_kbytes` | `1048576` (1 GB) | `67584` | Keep 1 GB free for kernel |
| `vm.admin_reserve_kbytes` | `524288` (512 MB) | `8192` | Reserve 512 MB for root |
| `vm.user_reserve_kbytes` | `524288` (512 MB) | `131072` | Reserve 512 MB for user recovery |
| `vm.oom_kill_allocating_task` | `1` | `0` | Kill OOM trigger (not random process) |
| `vm.panic_on_oom` | `0` | `0` | Don't kernel panic on OOM |
| `vm.zone_reclaim_mode` | `0` | `0` | Don't aggressively reclaim NUMA zones |

**File:** `/etc/sysctl.d/99-performance.conf` (loads after, wins on overlap)

| Setting | Value | Default | What It Does |
|---------|-------|---------|-------------|
| `vm.min_free_kbytes` | `1572864` (1.5 GB) | `67584` | 1.5 GB reserved for kernel + UI |
| `vm.overcommit_memory` | `0` | `0` | Heuristic overcommit (safe default) |
| `vm.overcommit_ratio` | `95` | `50` | Allow 95% of RAM+swap |

### Network Optimization

**File:** `/etc/sysctl.d/99-ml-performance.conf`

| Setting | Value | Default | What It Does |
|---------|-------|---------|-------------|
| `net.core.default_qdisc` | `fq` | `fq_codel` | Fair Queue — required for BBR |
| `net.ipv4.tcp_congestion_control` | `bbr` | `cubic` | Google BBR — better throughput & latency |
| `net.core.rmem_max` | `16777216` (16 MB) | `212992` | Max receive buffer |
| `net.core.wmem_max` | `16777216` (16 MB) | `212992` | Max send buffer |
| `net.core.rmem_default` | `1048576` (1 MB) | `212992` | Default receive buffer |
| `net.core.wmem_default` | `1048576` (1 MB) | `212992` | Default send buffer |
| `net.ipv4.tcp_rmem` | `4096 87380 16777216` | `4096 131072 6291456` | TCP receive: min/default/max |
| `net.ipv4.tcp_wmem` | `4096 65536 16777216` | `4096 16384 4194304` | TCP send: min/default/max |
| `net.ipv4.tcp_fastopen` | `3` | `1` | TCP Fast Open (client + server) |
| `net.ipv4.tcp_mtu_probing` | `1` | `0` | Auto-discover MTU |
| `net.ipv4.tcp_slow_start_after_idle` | `0` | `1` | Don't reset congestion window |
| `net.core.netdev_max_backlog` | `16384` | `1000` | Larger backlog queue |
| `net.core.somaxconn` | `8192` | `4096` | Max listen backlog |
| `net.ipv4.tcp_max_syn_backlog` | `8192` | `1024` | Max SYN queue |
| `net.ipv4.tcp_window_scaling` | `1` | `1` | Window scaling for high bandwidth |
| `net.ipv4.tcp_timestamps` | `1` | `1` | Better RTT estimation |
| `net.ipv4.tcp_sack` | `1` | `1` | Selective ACKs |
| `net.ipv4.tcp_no_metrics_save` | `1` | `0` | Don't cache TCP metrics |
| `net.ipv4.tcp_tw_reuse` | `1` | `2` | Reuse TIME_WAIT sockets |

### Filesystem & Kernel Tuning

**File:** `/etc/sysctl.d/99-performance.conf`

| Setting | Value | Default | What It Does |
|---------|-------|---------|-------------|
| `fs.inotify.max_user_watches` | `524288` | `65536` | More watches (VS Code, webpack) |
| `fs.inotify.max_user_instances` | `1024` | `128` | More inotify instances |
| `fs.file-max` | `2097152` | `9223372036854775807` | 2M max open files |

**File:** `/etc/sysctl.d/99-ml-performance.conf`

| Setting | Value | Default | What It Does |
|---------|-------|---------|-------------|
| `kernel.sysrq` | `1` | `176` | Enable all SysRq functions |

### AppArmor / Edge Sandbox Fix

**File:** `/etc/sysctl.d/99-edge-sandbox.conf`

| Setting | Value | Default | What It Does |
|---------|-------|---------|-------------|
| `kernel.apparmor_restrict_unprivileged_userns` | `0` | `1` | Allow user namespaces (Edge sandbox + containers) |

**File:** `/etc/apparmor.d/microsoft-edge`

A custom AppArmor profile that grants Edge the `userns` permission, so it works even if the sysctl gets reverted by an Ubuntu update. This eliminates the need for `--no-sandbox`.

### User & Group Changes

| Change | What It Does |
|--------|-------------|
| `usermod -aG docker dmj` | Run `docker` without `sudo` |

### GNOME Tweaks

| Setting | Value | What It Does |
|---------|-------|-------------|
| `org.gnome.SessionManager logout-prompt` | `false` | Shutdown/restart happens immediately — no 60-second countdown dialog |

### Systemd Services

| Service | What It Does |
|---------|-------------|
| `post-install.service` | One-shot: runs `post-install.sh` on first boot, then self-disables and deletes the script |
| `catch-up-updates.service` | Runs missed auto-updates after boot (waits for network, then updates APT + Node.js + snaps) |
| `unattended-upgrades.service` | Daily auto-update of all APT packages from all repos |

### Cron Jobs

| Job | Schedule | What It Does |
|-----|----------|-------------|
| `/etc/cron.daily/update-node-and-npm` | Daily (via anacron if missed) | Updates Node.js to latest + `npm update -g` |

### NetworkManager Hooks

| Hook | When It Fires | What It Does |
|------|--------------|-------------|
| `/etc/NetworkManager/dispatcher.d/99-catch-up-updates` | WiFi/Ethernet connects | Triggers catch-up updates if last update was >6 hours ago |

### Login Banner

Appears on every login until removed:
```
╔══════════════════════════════════════════════════════════════╗
║  ⚠️  DEFAULT PASSWORD IN USE — CHANGE IT NOW:               ║
║     sudo passwd dmj                                        ║
╚══════════════════════════════════════════════════════════════╝
```
Remove: `sudo rm /etc/profile.d/change-password-reminder.sh`

---

## How to Use

### Option A: Ventoy USB (recommended)

[Ventoy](https://www.ventoy.net) lets you boot multiple ISOs from one USB.

1. Install Ventoy on a USB drive
2. Download the [Ubuntu 24.04 Server ISO](https://ubuntu.com/download/server)
3. Copy to USB:

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

1. Download [Rufus](https://rufus.ie) + [Ubuntu 24.04 Server ISO](https://ubuntu.com/download/server)
2. Flash with: **GPT** partition scheme, **UEFI** target, **FAT32**
3. Copy `autoinstall.yaml` to the USB root
4. If read-only after flashing: use **DD mode** or repack the ISO

### Option C: Custom ISO (advanced)

```bash
mkdir /tmp/iso-extract
7z x ubuntu-24.04-live-server-amd64.iso -o/tmp/iso-extract
cp autoinstall.yaml /tmp/iso-extract/
xorriso -as mkisofs -r -V "Ubuntu Auto" \
  --grub2-mbr /tmp/iso-extract/boot/1-Boot-NoEmul.img \
  -partition_offset 16 --mbr-force-bootable \
  -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b \
  /tmp/iso-extract/boot/2-Boot-NoEmul.img \
  -appended_part_as_gpt \
  -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
  -c '/boot.catalog' -b '/boot/1-Boot-NoEmul.img' \
  -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
  -eltorito-alt-boot -e '--interval:appended_partition_2:::' \
  -no-emul-boot -o /tmp/ubuntu-24.04-autoinstall.iso /tmp/iso-extract
```

### Boot and Walk Away

1. Plug in USB, boot from it (F12/F2/Del for boot menu)
2. If Ventoy, select the Ubuntu ISO
3. Installer runs **fully unattended**
4. System reboots when done

### Monitor Progress

Post-install runs on first boot (~10–20 min):

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
| Change username | Replace `dmj` in `autoinstall.yaml` and `post-install.sh` |
| Change password | `openssl passwd -6 'newpass'` → replace hash in `autoinstall.yaml` |
| Skip NVIDIA driver | Remove `${NVIDIA_DRIVER}` line from `post-install.sh` |
| Add to base install | Add to `apt-get install` block in `post-install.sh` |
| Add desktop GUI | Add `apt-get install -y ubuntu-desktop-minimal` to `post-install.sh` |
| Change sysctl values | Edit `cat > /etc/sysctl.d/...` blocks in `post-install.sh` |
| Target specific disk | `match: serial: YOUR_SERIAL` instead of `match: size: largest` |
| Fork for your use | Fork repo, update GitHub URL in `autoinstall.yaml` late-commands |

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Post-install didn't run | `systemctl status post-install.service` + check `/var/log/post-install.log` |
| No internet during install | Connect Ethernet. WiFi may not work during server install. |
| Wrong disk selected | Use `match: serial: YOUR_SERIAL` (find with `lsblk -o NAME,SERIAL`) |
| NVIDIA driver issues | Reboot after post-install. `nvidia-smi`. May need Secure Boot disabled. |
| Edge crashes / needs --no-sandbox | AppArmor fix should handle this. Check `sysctl kernel.apparmor_restrict_unprivileged_userns` = 0 |
| Experiments not mounting | `blkid` to find UUID → update `/etc/fstab` |
| Rufus USB read-only | Use Ventoy or Rufus DD mode |
| Autoinstall not detected | Ensure `autoinstall.yaml` is in USB root |
| Hangs at "Continue with autoinstall?" | Normal — press Enter or wait 30s |
| Auto-updates not running | Check `systemctl status unattended-upgrades` and `/var/log/catch-up-updates.log` |
| Node.js not updating | Check `/var/log/node-auto-update.log` and `crontab -l` |
| System rebooted unexpectedly at 4 AM | Auto-reboot after kernel/driver update. Disable: set `Automatic-Reboot "false"` in `/etc/apt/apt.conf.d/50unattended-upgrades` |

---

## Requirements

- **Disk:** Minimum 224 GB (1 GB EFI + 100 GB root + 100 GB experiments + swap)
- **RAM:** 4 GB minimum, 16+ GB recommended
- **Internet:** Required during installation
- **Boot mode:** UEFI (not legacy BIOS)
- **Architecture:** x86_64 / amd64 only

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## License

MIT License. See [LICENSE](LICENSE).

**Built for Ubuntu 24.04 LTS (Noble Numbat) on x86_64. Future-proofed for 26.04 LTS.**
