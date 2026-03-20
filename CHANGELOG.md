# Changelog

All notable changes to this project are documented here.

## [1.1.0] - 2026-03-20

### Always Latest + Auto-Updates

#### Version auto-detection
- NVIDIA driver auto-detected (latest available in apt, no hardcoded version)
- GCC version auto-detected (latest from Ubuntu Toolchain PPA)
- nvm version auto-fetched from GitHub API releases
- Node.js installs latest (not LTS) via `nvm install node`
- `apt dist-upgrade` runs before package install to pull all latest

#### Build tools added to base
- `build-essential` (gcc, g++, make)
- Latest gcc/g++ from Ubuntu Toolchain PPA, set as default
- Latest CMake from Kitware repo
- `ninja-build`

#### New APT repositories
- Kitware (`apt.kitware.com`) — latest CMake
- Ubuntu Toolchain PPA (`ppa:ubuntu-toolchain-r/test`) — latest GCC/G++

#### Aggressive auto-updates
- `unattended-upgrades` configured for ALL repos (`origin=*`), not just security
- Snap refresh twice daily
- Daily cron for Node.js + npm global updates
- Auto-reboot at 4 AM if kernel/driver update requires it
- Config files preserved on upgrade (`--force-confold`)

#### Catch-up on missed updates
- `catch-up-updates.service` — runs missed updates 60s after boot
- NetworkManager dispatcher hook — triggers updates when WiFi/Ethernet connects (if stale >6h)
- `anacron` installed — re-runs missed cron jobs after boot

#### GNOME tweaks
- Shutdown confirmation dialog disabled (no 60-second countdown)

#### Claude Code configuration
- Agent teams enabled
- 12 official plugins pre-enabled
- Official plugin marketplace pre-configured

#### Future-proofing
- All hardcoded "noble" replaced with `${UBUNTU_CODENAME}` (auto-detected)
- HWE kernel auto-derived from Ubuntu version
- CUDA repo URL auto-derived from version
- `autoinstall.yaml` uses version: 1 (forward-compatible with 26.04)

---

## [1.0.0] - 2026-03-20

### Initial release

#### Base install
- Ubuntu 24.04 LTS autoinstall with GPT partitioning (1GB EFI, 100GB root, 100GB NTFS experiments, remainder swap)
- NVIDIA driver + HWE kernel
- Docker CE (Engine, CLI, Compose, Buildx)
- Microsoft Edge (replaces Firefox)
- Core CLI tools: git (PPA), git-delta, ripgrep, fzf, bat, fd-find, eza, jq, tmux, tree, pipx
- Python 3 (pip, venv)
- VS Code (snap)
- Node.js (via nvm) + Claude Code CLI + VS Code extension
- AppArmor profile for Edge (no --no-sandbox needed)

#### Bloatware removed
- Firefox, LibreOffice, Thunderbird, GNOME games, Rhythmbox, Shotwell, Cheese, Totem, Remmina, Transmission, GNOME apps (Calendar, Contacts, Maps, Weather, Clocks, Todo), yelp, simple-scan, brltty, orca, accessibility themes, update-manager, language-selector, gnome-font-viewer, gnome-logs

#### Kept from Ubuntu defaults
- All snaps (except Firefox), App Center, Software & Updates, Files, Settings, Terminal, Text Editor, Calculator, System Monitor, Utilities, Startup Applications, Disk Usage Analyzer, Document Viewer, Image Viewer, Passwords & Keys, Characters, Power Manager, USB Creator, Speech Dispatcher

#### System tuning
- Memory: swappiness=1, BBR congestion control, 16MB socket buffers
- Network: TCP Fast Open, MTU probing, window scaling, SACK
- Filesystem: 524,288 inotify watches, 2M max open files
- AppArmor: unprivileged userns allowed for containers/browsers

#### On-demand installer
- Interactive colored menu with 20 categories
- Categories: databases, cuda, ml-libs, r-lang, infra, security, build-tools, math-libs, office, email, media, photo, remote, torrent, firefox, scanner, codecs, extras, gnome-apps, accessibility
- Error-resilient: failed packages don't stop others, summary at end
- CLI and interactive modes, supports ranges (1-5) and combinations

#### Auto-fetch from GitHub
- post-install.sh fetched from GitHub during installation
- Only autoinstall.yaml needed on USB
- Update once, deploy everywhere
