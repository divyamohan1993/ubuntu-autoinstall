# Ubuntu 24.04 LTS — Automated System Setup

Fully automated, unattended Ubuntu 24.04 installation with pre-configured disk partitioning, 80+ packages, performance-tuned kernel settings, and development tooling — ready to deploy on any machine with a USB stick and an internet connection.

> **⚠️ SECURITY NOTICE:** Default credentials are **`dmj` / `dmj`** (intentionally public for quick setup).
> **Change your password immediately** after installation: `sudo passwd dmj`

---

## Table of Contents

- [What This Does](#what-this-does)
- [Files in This Repo](#files-in-this-repo)
- [Disk Partitioning](#disk-partitioning)
- [What Gets Installed](#what-gets-installed)
  - [Base Packages (during OS install)](#base-packages-installed-during-os-installation)
  - [External APT Repositories Added](#external-apt-repositories-added)
  - [Full Package List (post-install)](#full-package-list-installed-via-post-install)
  - [Snap Packages](#snap-packages)
  - [Node.js (via nvm)](#nodejs-via-nvm)
- [System Settings Changed](#system-settings-changed)
  - [Memory & Swap Tuning](#memory--swap-tuning)
  - [Network Optimization](#network-optimization)
  - [Filesystem & Kernel Tuning](#filesystem--kernel-tuning)
  - [Security Settings](#security-settings)
  - [Filesystem Mounts (fstab)](#filesystem-mounts-fstab)
  - [User & Group Changes](#user--group-changes)
  - [Systemd Services](#systemd-services)
- [How to Use](#how-to-use)
  - [Option A: Ventoy USB (recommended)](#option-a-ventoy-usb-recommended)
  - [Option B: Rufus USB](#option-b-rufus-usb)
  - [Boot and Walk Away](#boot-and-walk-away)
  - [Monitor Progress](#monitor-progress)
  - [Reboot and Secure](#reboot-and-secure)
- [How the Auto-Fetch Works](#how-the-auto-fetch-works)
- [Customization Guide](#customization-guide)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## What This Does

In one unattended installation, this setup:

1. **Partitions your disk** — EFI, root, experiments (NTFS), and swap
2. **Installs Ubuntu 24.04 LTS** with SSH server enabled
3. **Fetches the post-install script from this GitHub repo** (no extra files needed on USB)
4. **On first boot**, automatically:
   - Adds 9 external APT repositories (Docker, NVIDIA CUDA, MongoDB, etc.)
   - Installs 80+ packages (dev tools, databases, ML libraries, containers, etc.)
   - Applies kernel/network/memory performance optimizations
   - Installs VS Code and Node.js
   - Adds user to the Docker group

---

## Files in This Repo

| File | Purpose | When It Runs |
|------|---------|--------------|
| [`autoinstall.yaml`](autoinstall.yaml) | Ubuntu autoinstall configuration — disk layout, locale, identity, base packages, and late-commands that fetch the post-install script | During OS installation (read by Ubuntu's Subiquity installer) |
| [`post-install.sh`](post-install.sh) | Post-installation script — adds repos, installs all packages, applies sysctl optimizations | On first boot (via a one-shot systemd service) |
| [`README.md`](README.md) | This documentation | — |

---

## Disk Partitioning

The installer targets the **largest disk** on the system and creates this layout:

| Partition | Size | Filesystem | Mount Point | Purpose |
|-----------|------|------------|-------------|---------|
| Part 1 | 1 GB | FAT32 (EFI) | `/boot/efi` | UEFI boot partition |
| Part 2 | 100 GB | ext4 | `/` | Root filesystem (Ubuntu OS) |
| Part 3 | 100 GB | NTFS | `/mnt/experiments` | Data partition (cross-compatible with Windows) |
| Part 4 | Remainder (~22 GB on a 224 GB disk) | swap | `[SWAP]` | Swap space |

Additional mounts configured in `/etc/fstab`:
- `/tmp` → `tmpfs` (4 GB, RAM-backed, `noatime,nosuid,nodev`)

> **Note:** The experiments partition uses NTFS so it can be read/written from both Linux and Windows if you dual-boot.

---

## What Gets Installed

### Base Packages (installed during OS installation)

These are installed by the Ubuntu installer itself (before first boot):

| Package | What It Is |
|---------|-----------|
| `git` | Version control |
| `curl` | HTTP client |
| `jq` | JSON processor |
| `tmux` | Terminal multiplexer |
| `tree` | Directory listing |
| `fzf` | Fuzzy finder |
| `ripgrep` | Fast code search (`rg`) |
| `bat` | `cat` with syntax highlighting |
| `fd-find` | Fast file finder (`fdfind`) |
| `httpie` | User-friendly HTTP client |
| `lynx` | Terminal web browser |
| `shellcheck` | Shell script linter |
| `cmake` | Build system generator |
| `ninja-build` | Fast build system |
| `sqlite3` | Lightweight SQL database |
| `stress-ng` | System stress tester |
| `pipx` | Install Python CLI tools in isolation |
| `python3-pip` | Python package manager |
| `python3-venv` | Python virtual environments |
| `xvfb` | Virtual framebuffer (headless X11) |
| `ntfs-3g` | NTFS filesystem support |

### External APT Repositories Added

The post-install script adds these third-party repositories:

| Repository | Source URL | What It Provides |
|------------|-----------|-----------------|
| **Docker CE** | `download.docker.com/linux/ubuntu` | Docker Engine, CLI, Compose, Buildx |
| **NVIDIA CUDA** | `developer.download.nvidia.com/compute/cuda/repos/ubuntu2404` | CUDA toolkit, GPU drivers |
| **MongoDB 8.0** | `repo.mongodb.org/apt/ubuntu` | MongoDB server and tools |
| **HashiCorp** | `apt.releases.hashicorp.com` | Terraform |
| **Microsoft Edge** | `packages.microsoft.com/repos/edge` | Edge browser |
| **R Project (CRAN)** | `cloud.r-project.org/bin/linux/ubuntu` | R language and base packages |
| **Trivy** | `aquasecurity.github.io/trivy-repo` | Container security scanner |
| **eza** | `deb.gierens.de` | Modern `ls` replacement |
| **Git PPA** | `ppa:git-core/ppa` | Latest Git version |

### Full Package List (installed via post-install)

#### Development Tools
| Package | What It Is |
|---------|-----------|
| `git` | Version control (latest from PPA) |
| `git-delta` | Beautiful git diffs |
| `cmake` | Build system |
| `ninja-build` | Fast parallel builds |
| `pre-commit` | Git pre-commit hook framework |
| `shellcheck` | Shell script linter |

#### Containers & Infrastructure
| Package | What It Is |
|---------|-----------|
| `docker-ce` | Docker Engine |
| `docker-ce-cli` | Docker CLI |
| `containerd.io` | Container runtime |
| `docker-compose-plugin` | Docker Compose v2 |
| `docker-buildx-plugin` | Docker Buildx (multi-platform builds) |
| `docker-ce-rootless-extras` | Rootless Docker support |
| `terraform` | Infrastructure as Code |
| `ansible` | Configuration management |
| `trivy` | Container vulnerability scanner |

#### Databases
| Package | What It Is |
|---------|-----------|
| `mongodb-org` | MongoDB 8.0 server + tools |
| `postgresql` | PostgreSQL server |
| `postgresql-client` | PostgreSQL CLI client |
| `postgresql-contrib` | PostgreSQL extensions |
| `redis-server` | Redis server |
| `redis-tools` | Redis CLI tools |
| `sqlite3` | SQLite database |

#### GPU / Machine Learning
| Package | What It Is |
|---------|-----------|
| `nvidia-driver-535` | NVIDIA GPU driver |
| `cuda-toolkit` | NVIDIA CUDA development toolkit |
| `libopenblas-dev` | Optimized BLAS library |
| `liblapack-dev` | Linear algebra library |
| `libfftw3-dev` | Fast Fourier Transform library |
| `libopenmpi-dev` | MPI for distributed computing |
| `openmpi-bin` | MPI runtime |

#### Languages & Runtimes
| Package | What It Is |
|---------|-----------|
| `python3-pip` | Python package manager |
| `python3-venv` | Python virtual environments |
| `python3-docx` | Python DOCX library |
| `pipx` | Isolated Python CLI tools |
| `r-base` | R programming language |
| `gfortran` | GNU Fortran compiler |

#### Math / Science Libraries
| Package | What It Is |
|---------|-----------|
| `libgmp-dev` | GNU Multiple Precision arithmetic |
| `libmpfr-dev` | Multiple-precision floating-point |
| `libmpc-dev` | Complex number arithmetic |

#### CLI Tools
| Package | What It Is |
|---------|-----------|
| `eza` | Modern `ls` replacement (colors, git integration) |
| `ripgrep` | Fast grep (`rg`) |
| `fzf` | Fuzzy finder |
| `bat` | `cat` with syntax highlighting |
| `fd-find` | Fast `find` alternative |
| `httpie` | User-friendly `curl` alternative |
| `jq` | JSON processor |
| `tmux` | Terminal multiplexer |
| `tree` | Directory tree listing |
| `lynx` | Terminal web browser |

#### Browsers & GUI
| Package | What It Is |
|---------|-----------|
| `microsoft-edge-stable` | Microsoft Edge browser |
| `ubuntu-restricted-addons` | Multimedia codecs |
| `xvfb` | Virtual framebuffer |

#### Other
| Package | What It Is |
|---------|-----------|
| `linux-generic-hwe-24.04` | Hardware Enablement kernel (latest hardware support) |
| `stress-ng` | System stress testing |

### Snap Packages

| Package | What It Provides |
|---------|-----------------|
| `code --classic` | Visual Studio Code |

### Node.js (via nvm)

- **nvm** v0.40.3 (Node Version Manager) is installed for the `dmj` user
- Latest **LTS version** of Node.js is installed and set as default
- Available immediately on login via `~/.nvm/nvm.sh`

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

> **Note:** `99-performance.conf` loads after `99-ml-performance.conf` (alphabetical order), so where settings overlap (e.g. `vm.min_free_kbytes`), the `99-performance.conf` value wins.

### Network Optimization

**File:** `/etc/sysctl.d/99-ml-performance.conf`

| Setting | Value | Default | What It Does |
|---------|-------|---------|-------------|
| `net.core.default_qdisc` | `fq` | `fq_codel` | Fair Queue scheduler — required for BBR |
| `net.ipv4.tcp_congestion_control` | `bbr` | `cubic` | Google's BBR congestion control — higher throughput, lower latency |
| `net.core.rmem_max` | `16777216` (16 MB) | `212992` | Maximum receive socket buffer |
| `net.core.wmem_max` | `16777216` (16 MB) | `212992` | Maximum send socket buffer |
| `net.core.rmem_default` | `1048576` (1 MB) | `212992` | Default receive buffer |
| `net.core.wmem_default` | `1048576` (1 MB) | `212992` | Default send buffer |
| `net.ipv4.tcp_rmem` | `4096 87380 16777216` | `4096 131072 6291456` | TCP receive buffer: min / default / max |
| `net.ipv4.tcp_wmem` | `4096 65536 16777216` | `4096 16384 4194304` | TCP send buffer: min / default / max |
| `net.ipv4.tcp_fastopen` | `3` | `1` | Enable TCP Fast Open for both client and server |
| `net.ipv4.tcp_mtu_probing` | `1` | `0` | Auto-discover optimal MTU size |
| `net.ipv4.tcp_slow_start_after_idle` | `0` | `1` | Don't reset congestion window after idle — faster resumption |
| `net.core.netdev_max_backlog` | `16384` | `1000` | Larger network device backlog queue |
| `net.core.somaxconn` | `8192` | `4096` | Maximum socket listen backlog |
| `net.ipv4.tcp_max_syn_backlog` | `8192` | `1024` | Maximum SYN queue |
| `net.ipv4.tcp_window_scaling` | `1` | `1` | Enable TCP window scaling (for high-bandwidth connections) |
| `net.ipv4.tcp_timestamps` | `1` | `1` | Enable TCP timestamps (better RTT estimation) |
| `net.ipv4.tcp_sack` | `1` | `1` | Selective acknowledgments (faster recovery from packet loss) |
| `net.ipv4.tcp_no_metrics_save` | `1` | `0` | Don't cache TCP metrics between connections |
| `net.ipv4.tcp_tw_reuse` | `1` | `2` | Reuse TIME_WAIT sockets (reduces port exhaustion) |

### Filesystem & Kernel Tuning

**File:** `/etc/sysctl.d/99-performance.conf`

| Setting | Value | Default | What It Does |
|---------|-------|---------|-------------|
| `fs.inotify.max_user_watches` | `524288` | `65536` | Allow more inotify watches (needed for large projects in VS Code, webpack, etc.) |
| `fs.inotify.max_user_instances` | `1024` | `128` | More inotify instances |
| `fs.file-max` | `2097152` | `9223372036854775807` | System-wide max open files (2 million) |
| `kernel.sysrq` | `1` | `176` | Enable all Magic SysRq key functions (emergency kernel debugging) |

### Security Settings

**File:** `/etc/sysctl.d/99-edge-sandbox.conf`

| Setting | Value | Default | What It Does |
|---------|-------|---------|-------------|
| `kernel.apparmor_restrict_unprivileged_userns` | `0` | `1` | Allow unprivileged user namespaces (required for Chromium/Edge sandbox and some containers) |

### Filesystem Mounts (fstab)

| Mount | Filesystem | Options | Purpose |
|-------|------------|---------|---------|
| `/` | ext4 | `noatime,errors=remount-ro` | Root — `noatime` avoids unnecessary disk writes |
| `/boot/efi` | vfat | `umask=0077` | EFI boot partition |
| `/mnt/experiments` | ntfs3 | `noatime,uid=1000,gid=1000,nofail` | Data partition — owned by first user, won't block boot if missing |
| `/tmp` | tmpfs | `noatime,nosuid,nodev,size=4G` | RAM-backed temp directory — faster, auto-cleared on reboot |

### User & Group Changes

| Change | What It Does |
|--------|-------------|
| `usermod -aG docker dmj` | Allows running `docker` commands without `sudo` |

### Systemd Services

| Service | What It Does |
|---------|-------------|
| `post-install.service` | One-shot service that runs `post-install.sh` on first boot, then disables and removes itself |

### Login Banner

A password-change reminder is shown on every login until removed:
```
╔══════════════════════════════════════════════════════════════╗
║  ⚠️  DEFAULT PASSWORD IN USE — CHANGE IT NOW:               ║
║     sudo passwd dmj                                        ║
╚══════════════════════════════════════════════════════════════╝
```
File: `/etc/profile.d/change-password-reminder.sh` — delete it after changing your password.

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
3. After flashing, the USB will have an ISO filesystem. Mount or open the USB and place `autoinstall.yaml` in one of these locations:
   - **Root of the USB:** Simply copy `autoinstall.yaml` to the top-level directory of the drive
   - **Or** create a directory called `autoinstall/` and place it inside as `user-data`
4. If the USB filesystem is read-only after flashing (ISO9660), you have two options:
   - **Recommended:** Use Rufus in **DD mode** instead of ISO mode, then mount the resulting partition and copy the file
   - **Alternative:** Repack the ISO with `autoinstall.yaml` baked in (see [Custom ISO](#custom-iso-advanced) below)

> **Tip:** Ventoy is generally easier for autoinstall setups because it doesn't modify the ISO and lets you simply drop files on the USB as a normal drive.

### Option C: Custom ISO (advanced)

If you want a single ISO file with everything baked in (no separate files needed):

```bash
# Extract the ISO
mkdir /tmp/iso-extract
7z x ubuntu-24.04-live-server-amd64.iso -o/tmp/iso-extract

# Copy autoinstall.yaml into the ISO root
cp autoinstall.yaml /tmp/iso-extract/

# Repack the ISO (requires xorriso)
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

Then flash the custom ISO with Rufus or `dd`.

### Boot and Walk Away

1. Plug in USB → Boot from it (you may need to press F12/F2/Del to select boot device)
2. If using Ventoy, select the Ubuntu ISO from the menu
3. The installer runs **fully unattended** — no user interaction needed
4. It partitions the disk, installs the OS, and configures first-boot setup
5. The system reboots automatically when done

### Monitor Progress

After the first reboot, the post-install script runs automatically. This can take **15–45 minutes** depending on your internet speed (it downloads ~2–5 GB of packages).

```bash
# Watch live:
journalctl -u post-install.service -f

# Or check the log file:
tail -f /var/log/post-install.log
```

### Reboot and Secure

```bash
# Reboot to load NVIDIA drivers and new kernel
sudo reboot

# CHANGE THE DEFAULT PASSWORD!
sudo passwd dmj

# Remove the login reminder after changing password
sudo rm /etc/profile.d/change-password-reminder.sh
```

---

## How the Auto-Fetch Works

The `autoinstall.yaml` `late-commands` section runs during installation:

```yaml
late-commands:
  - curtin in-target -- curl -fsSL \
      https://raw.githubusercontent.com/divyamohan1993/ubuntu-autoinstall/main/post-install.sh \
      -o /root/post-install.sh
```

This means:
- **Only `autoinstall.yaml` is needed on the USB** — nothing else
- **`post-install.sh` is always fetched fresh** from this GitHub repo at install time
- **Update once, deploy everywhere** — edit `post-install.sh` here and every future install gets the latest version
- **Requires internet** during installation (the installer already needs it for package downloads)

---

## Customization Guide

| Want to... | Do this |
|------------|---------|
| Change disk sizes | Edit `size:` values under `storage.config` in `autoinstall.yaml` |
| Change username | Replace `dmj` in both `autoinstall.yaml` and `post-install.sh` |
| Change password | Run `openssl passwd -6 'newpass'` and replace the hash in `autoinstall.yaml` |
| Skip NVIDIA/CUDA | Remove `nvidia-driver-535` and `cuda-toolkit` from `post-install.sh` |
| Skip a database | Remove `mongodb-org`, `postgresql*`, or `redis-*` lines from `post-install.sh` |
| Add packages | Add to the `apt-get install` block in `post-install.sh` |
| Add desktop GUI | Add `apt-get install -y ubuntu-desktop-minimal` to `post-install.sh` |
| Change sysctl values | Edit the `cat > /etc/sysctl.d/...` blocks in `post-install.sh` |
| Target a specific disk | Change `match: size: largest` to `match: serial: YOUR_DISK_SERIAL` in `autoinstall.yaml` |
| Fork for your own use | Fork this repo, update the GitHub raw URL in `autoinstall.yaml` to point to your fork |

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Post-install didn't run | Check: `systemctl status post-install.service` and `/var/log/post-install.log` |
| No internet during install | The installer and post-install both need internet. Connect Ethernet before booting. WiFi may not work during server install. |
| Wrong disk selected | Change `match: size: largest` in `autoinstall.yaml` to target a specific disk by serial number (`lsblk -o NAME,SERIAL`) |
| NVIDIA driver issues | Reboot after post-install. Check `nvidia-smi`. May need to disable Secure Boot in BIOS. |
| Experiments partition not mounting | Run `blkid` to find the UUID, then update `/etc/fstab` with the correct UUID |
| Rufus USB is read-only | Use Ventoy instead, or flash with Rufus in DD mode |
| Autoinstall not detected | Ensure `autoinstall.yaml` is in the root of the USB (not inside a subfolder) |
| Installation hangs at "Continue with autoinstall?" | This is normal — press Enter or wait 30 seconds, it auto-continues |

---

## Requirements

- **Disk:** Minimum 224 GB (1 GB EFI + 100 GB root + 100 GB experiments + swap)
- **RAM:** 4 GB minimum, 16+ GB recommended (for ML workloads)
- **Internet:** Required during installation (to fetch post-install script and packages)
- **Boot mode:** UEFI (not legacy BIOS)
- **Architecture:** x86_64 / amd64 only

---

## License

This configuration is provided as-is for personal and educational use. No warranty. Use at your own risk.

**Built for Ubuntu 24.04 LTS (Noble Numbat) on x86_64.**
