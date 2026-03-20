#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
# On-Demand Package Installer
# Interactive menu or CLI: ./on-demand-install.sh [category ...]
# ═══════════════════════════════════════════════════════════════════════

export DEBIAN_FRONTEND=noninteractive

# ─── Auto-detect Ubuntu version ───────────────────────────────────────
UBUNTU_CODENAME=$(lsb_release -cs 2>/dev/null || echo "noble")
UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "24.04")

# ─── Colors & formatting ─────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

ok()    { echo -e "  ${GREEN}✓${NC} $1"; }
fail()  { echo -e "  ${RED}✗${NC} $1"; }
info()  { echo -e "  ${BLUE}→${NC} $1"; }
warn()  { echo -e "  ${YELLOW}!${NC} $1"; }
header(){ echo -e "\n${BOLD}${CYAN}═══ $1 ═══${NC}\n"; }

# ─── Error handling ───────────────────────────────────────────────────
FAILED=()
SUCCEEDED=()

run_install() {
  local name="$1"
  shift
  if "$@"; then
    SUCCEEDED+=("$name")
    ok "$name installed successfully"
  else
    FAILED+=("$name")
    fail "$name failed — continuing with remaining installs"
  fi
}

apt_install() {
  sudo apt-get install -y "$@" 2>&1 | tail -1
}

apt_update_once() {
  if [[ -z "${APT_UPDATED:-}" ]]; then
    info "Updating package lists..."
    sudo apt-get update -qq
    APT_UPDATED=1
  fi
}

add_repo_key() {
  local url="$1" keyfile="$2"
  if [[ ! -f "$keyfile" ]]; then
    curl -fsSL "$url" | sudo gpg --dearmor -o "$keyfile" 2>/dev/null
  fi
}

print_summary() {
  echo ""
  echo -e "${BOLD}───────────────────────────────────────${NC}"
  if [[ ${#SUCCEEDED[@]} -gt 0 ]]; then
    echo -e "${GREEN}${BOLD}Installed (${#SUCCEEDED[@]}):${NC}"
    for s in "${SUCCEEDED[@]}"; do echo -e "  ${GREEN}✓${NC} $s"; done
  fi
  if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo ""
    echo -e "${RED}${BOLD}Failed (${#FAILED[@]}):${NC}"
    for f in "${FAILED[@]}"; do echo -e "  ${RED}✗${NC} $f"; done
    echo ""
    warn "To retry failed installs, run:"
    echo -e "  ${DIM}sudo apt-get update && sudo apt-get install -y <package>${NC}"
  fi
  if [[ ${#SUCCEEDED[@]} -eq 0 && ${#FAILED[@]} -eq 0 ]]; then
    info "Nothing was installed."
  fi
  echo -e "${BOLD}───────────────────────────────────────${NC}"
}

# ─── Category definitions ─────────────────────────────────────────────
# Each category: number, id, label, description

CATEGORIES=(
  "databases:Databases:PostgreSQL, MongoDB 8.0, Redis, SQLite"
  "cuda:CUDA Toolkit:NVIDIA CUDA development toolkit (driver already installed)"
  "ml-libs:ML / Science Libraries:OpenBLAS, LAPACK, FFTW3, OpenMPI, gfortran"
  "r-lang:R Language:R programming language from CRAN"
  "infra:Infrastructure Tools:Terraform, Ansible"
  "security:Security Scanner:Trivy container vulnerability scanner"
  "build-tools:Build Tools:CMake, Ninja, Shellcheck, pre-commit"
  "math-libs:Math Libraries:libgmp, libmpfr, libmpc (precision arithmetic)"
  "office:Office Suite:LibreOffice (Writer, Calc, Impress, Draw)"
  "email:Email Client:Thunderbird"
  "media:Media Players:Totem video player, Rhythmbox music player"
  "photo:Photo Tools:Shotwell photo manager, Cheese webcam"
  "remote:Remote Desktop:Remmina remote desktop client"
  "torrent:Torrent Client:Transmission"
  "firefox:Firefox Browser:Firefox (if you want it alongside Edge)"
  "scanner:Scanner:Simple Scan"
  "codecs:Multimedia Codecs:Ubuntu restricted addons (MP3, H.264, etc.)"
  "extras:CLI Extras:httpie, lynx, stress-ng, xvfb, python3-docx"
  "gnome-apps:GNOME Apps:Calendar, Contacts, Maps, Weather, Clocks, Todo"
  "accessibility:Accessibility:Orca screen reader, accessibility themes"
)

# ─── Install functions ────────────────────────────────────────────────

do_install() {
  local cat_id="$1"
  apt_update_once

  case "$cat_id" in
    databases)
      header "Databases"
      # MongoDB repo
      add_repo_key "https://www.mongodb.org/static/pgp/server-8.0.asc" \
        "/usr/share/keyrings/mongodb-server-8.0.gpg"
      echo "deb [arch=amd64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/ubuntu ${UBUNTU_CODENAME}/mongodb-org/8.0 multiverse" \
        | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list >/dev/null
      sudo apt-get update -qq
      run_install "PostgreSQL" apt_install postgresql postgresql-client postgresql-contrib
      run_install "MongoDB 8.0" apt_install mongodb-org
      run_install "Redis" apt_install redis-server redis-tools
      run_install "SQLite" apt_install sqlite3
      ;;

    cuda)
      header "CUDA Toolkit"
      run_install "CUDA Toolkit" apt_install cuda-toolkit
      ;;

    ml-libs)
      header "ML / Science Libraries"
      run_install "OpenBLAS" apt_install libopenblas-dev
      run_install "LAPACK" apt_install liblapack-dev
      run_install "FFTW3" apt_install libfftw3-dev
      run_install "OpenMPI" apt_install libopenmpi-dev openmpi-bin
      run_install "gfortran" apt_install gfortran
      ;;

    r-lang)
      header "R Language"
      add_repo_key "https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc" \
        "/usr/share/keyrings/r-project.gpg"
      echo "deb [signed-by=/usr/share/keyrings/r-project.gpg] https://cloud.r-project.org/bin/linux/ubuntu ${UBUNTU_CODENAME}-cran40/" \
        | sudo tee /etc/apt/sources.list.d/r-project.list >/dev/null
      sudo apt-get update -qq
      run_install "R base" apt_install r-base
      ;;

    infra)
      header "Infrastructure Tools"
      add_repo_key "https://apt.releases.hashicorp.com/gpg" \
        "/usr/share/keyrings/hashicorp-archive-keyring.gpg"
      echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${UBUNTU_CODENAME} main" \
        | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
      sudo apt-get update -qq
      run_install "Terraform" apt_install terraform
      run_install "Ansible" apt_install ansible
      ;;

    security)
      header "Security Scanner"
      add_repo_key "https://aquasecurity.github.io/trivy-repo/deb/public.key" \
        "/usr/share/keyrings/trivy.gpg"
      echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb ${UBUNTU_CODENAME} main" \
        | sudo tee /etc/apt/sources.list.d/trivy.list >/dev/null
      sudo apt-get update -qq
      run_install "Trivy" apt_install trivy
      ;;

    build-tools)
      header "Build Tools"
      run_install "CMake" apt_install cmake
      run_install "Ninja" apt_install ninja-build
      run_install "Shellcheck" apt_install shellcheck
      run_install "pre-commit" apt_install pre-commit
      ;;

    math-libs)
      header "Math Libraries"
      run_install "libgmp" apt_install libgmp-dev
      run_install "libmpfr" apt_install libmpfr-dev
      run_install "libmpc" apt_install libmpc-dev
      ;;

    office)
      header "Office Suite"
      run_install "LibreOffice" apt_install libreoffice
      ;;

    email)
      header "Email Client"
      run_install "Thunderbird" apt_install thunderbird
      ;;

    media)
      header "Media Players"
      run_install "Totem (video)" apt_install totem totem-plugins
      run_install "Rhythmbox (music)" apt_install rhythmbox
      ;;

    photo)
      header "Photo Tools"
      run_install "Shotwell" apt_install shotwell
      run_install "Cheese (webcam)" apt_install cheese
      ;;

    remote)
      header "Remote Desktop"
      run_install "Remmina" apt_install remmina
      ;;

    torrent)
      header "Torrent Client"
      run_install "Transmission" apt_install transmission-gtk
      ;;

    firefox)
      header "Firefox Browser"
      run_install "Firefox" sudo snap install firefox
      ;;

    scanner)
      header "Scanner"
      run_install "Simple Scan" apt_install simple-scan
      ;;

    codecs)
      header "Multimedia Codecs"
      run_install "Ubuntu Restricted Addons" apt_install ubuntu-restricted-addons
      ;;

    extras)
      header "CLI Extras"
      run_install "httpie" apt_install httpie
      run_install "lynx" apt_install lynx
      run_install "stress-ng" apt_install stress-ng
      run_install "xvfb" apt_install xvfb
      run_install "python3-docx" apt_install python3-docx
      ;;

    gnome-apps)
      header "GNOME Apps"
      run_install "Calendar" apt_install gnome-calendar
      run_install "Contacts" apt_install gnome-contacts
      run_install "Maps" apt_install gnome-maps
      run_install "Weather" apt_install gnome-weather
      run_install "Clocks" apt_install gnome-clocks
      run_install "Todo" apt_install gnome-todo
      ;;

    accessibility)
      header "Accessibility"
      run_install "Orca (screen reader)" apt_install orca
      run_install "Accessibility Themes" apt_install gnome-accessibility-themes
      ;;

    *)
      fail "Unknown category: $cat_id"
      return 1
      ;;
  esac
}

# ─── Interactive menu ─────────────────────────────────────────────────

show_menu() {
  clear
  echo -e "${BOLD}${CYAN}"
  echo "  ┌──────────────────────────────────────────────┐"
  echo "  │       On-Demand Package Installer            │"
  echo "  │       Ubuntu ${UBUNTU_VERSION} LTS                       │"
  echo "  └──────────────────────────────────────────────┘"
  echo -e "${NC}"
  echo -e "  ${DIM}Select categories to install (space-separated numbers)${NC}"
  echo -e "  ${DIM}or type 'all' to install everything.${NC}"
  echo ""

  local i=1
  echo -e "  ${BOLD}#   Category                 Packages${NC}"
  echo -e "  ${DIM}──  ────────────────────────  ──────────────────────────────────${NC}"
  for entry in "${CATEGORIES[@]}"; do
    IFS=':' read -r id label desc <<< "$entry"
    printf "  ${YELLOW}%-3s${NC} %-25s ${DIM}%s${NC}\n" "$i" "$label" "$desc"
    ((i++))
  done

  echo ""
  echo -e "  ${YELLOW}A${NC}   ${BOLD}Install ALL${NC}              ${DIM}Everything listed above${NC}"
  echo -e "  ${YELLOW}Q${NC}   ${BOLD}Quit${NC}"
  echo ""
  echo -ne "  ${BOLD}Enter choices (e.g. 1 3 5):${NC} "
}

parse_selection() {
  local input="$1"
  local selected=()

  # Handle 'all' or 'a'
  if [[ "${input,,}" == "all" || "${input,,}" == "a" ]]; then
    for entry in "${CATEGORIES[@]}"; do
      IFS=':' read -r id _ _ <<< "$entry"
      selected+=("$id")
    done
    echo "${selected[*]}"
    return
  fi

  # Handle 'q' or 'quit'
  if [[ "${input,,}" == "q" || "${input,,}" == "quit" ]]; then
    echo "QUIT"
    return
  fi

  # Parse space/comma separated numbers
  for token in $input; do
    token="${token//,/}"  # strip commas
    if [[ "$token" =~ ^[0-9]+$ ]] && (( token >= 1 && token <= ${#CATEGORIES[@]} )); then
      local entry="${CATEGORIES[$((token-1))]}"
      IFS=':' read -r id _ _ <<< "$entry"
      selected+=("$id")
    elif [[ "$token" =~ ^[0-9]+-[0-9]+$ ]]; then
      # Handle ranges like 1-5
      local start="${token%-*}" end="${token#*-}"
      for (( n=start; n<=end && n<=${#CATEGORIES[@]}; n++ )); do
        local entry="${CATEGORIES[$((n-1))]}"
        IFS=':' read -r id _ _ <<< "$entry"
        selected+=("$id")
      done
    else
      # Try as category name directly
      for entry in "${CATEGORIES[@]}"; do
        IFS=':' read -r id _ _ <<< "$entry"
        if [[ "$id" == "$token" ]]; then
          selected+=("$id")
          break
        fi
      done
    fi
  done

  echo "${selected[*]}"
}

# ─── Main ─────────────────────────────────────────────────────────────

main() {
  # If arguments provided, run in CLI mode (non-interactive)
  if [[ $# -gt 0 ]]; then
    if [[ "$1" == "all" ]]; then
      for entry in "${CATEGORIES[@]}"; do
        IFS=':' read -r id _ _ <<< "$entry"
        do_install "$id"
      done
    elif [[ "$1" == "--help" || "$1" == "-h" ]]; then
      echo -e "${BOLD}Usage:${NC}"
      echo "  $0                     Interactive menu"
      echo "  $0 <cat> [cat ...]     Install specific categories"
      echo "  $0 all                 Install everything"
      echo "  $0 --list              List all categories"
      echo ""
      echo -e "${BOLD}Categories:${NC}"
      for entry in "${CATEGORIES[@]}"; do
        IFS=':' read -r id label desc <<< "$entry"
        printf "  ${YELLOW}%-15s${NC} %s\n" "$id" "$desc"
      done
      exit 0
    elif [[ "$1" == "--list" ]]; then
      for entry in "${CATEGORIES[@]}"; do
        IFS=':' read -r id _ _ <<< "$entry"
        echo "$id"
      done
      exit 0
    else
      for cat_id in "$@"; do
        do_install "$cat_id"
      done
    fi
    print_summary
    exit 0
  fi

  # Interactive mode
  while true; do
    show_menu
    read -r selection

    local parsed
    parsed=$(parse_selection "$selection")

    if [[ "$parsed" == "QUIT" ]]; then
      echo -e "\n  ${DIM}Bye!${NC}\n"
      exit 0
    fi

    if [[ -z "$parsed" ]]; then
      warn "Invalid selection. Try again."
      sleep 1
      continue
    fi

    echo ""
    echo -e "  ${BOLD}Installing:${NC} $parsed"
    echo ""
    read -rp "  Proceed? [Y/n] " confirm
    if [[ "${confirm,,}" == "n" ]]; then
      continue
    fi

    FAILED=()
    SUCCEEDED=()

    for cat_id in $parsed; do
      do_install "$cat_id"
    done

    print_summary

    echo ""
    read -rp "  Install more? [y/N] " again
    if [[ "${again,,}" != "y" ]]; then
      echo -e "\n  ${DIM}Done!${NC}\n"
      exit 0
    fi
  done
}

main "$@"
