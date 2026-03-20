# Changelog

All notable changes to this project are documented here.

## [1.0.0] - 2026-03-20

### Initial release

#### Base install
- Ubuntu 24.04 LTS autoinstall with GPT partitioning (1GB EFI, 100GB root, 100GB NTFS experiments, remainder swap)
- NVIDIA driver 535 + HWE kernel
- Docker CE (Engine, CLI, Compose, Buildx)
- Microsoft Edge (replaces Firefox)
- Core CLI tools: git (PPA), git-delta, ripgrep, fzf, bat, fd-find, eza, jq, tmux, tree, pipx
- Python 3 (pip, venv)
- VS Code (snap)
- Node.js LTS (via nvm) + Claude Code CLI + VS Code extension
- AppArmor profile for Edge (no --no-sandbox needed)

#### Bloatware removed
- Firefox, LibreOffice, Thunderbird, GNOME games, Rhythmbox, Shotwell, Cheese, Totem, Remmina, Transmission, GNOME apps (Calendar, Contacts, Maps, Weather, Clocks, Todo), yelp, simple-scan, brltty, orca, accessibility themes, update-manager, language-selector, gnome-font-viewer, gnome-logs

#### Kept from Ubuntu defaults
- All snaps (except Firefox), App Center, Software & Updates, Files, Settings, Terminal, Text Editor, Calculator, System Monitor, Utilities, Startup Applications, Disk Usage Analyzer, Document Viewer, Image Viewer, Passwords & Keys, Characters, Power Manager, USB Creator, Speech Dispatcher

#### System tuning
- Memory: swappiness=1, BBR congestion control, 16MB socket buffers
- Network: TCP Fast Open, MTU probing, window scaling, SACK
- Filesystem: 524K inotify watches, 2M max open files
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
