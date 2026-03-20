#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
# On-demand package installer
# Run only the sections you need:  ./on-demand-install.sh databases
# Or run everything:               ./on-demand-install.sh all
# ═══════════════════════════════════════════════════════════════════════
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

usage() {
  echo "Usage: $0 <category> [category...]"
  echo ""
  echo "Categories:"
  echo "  databases     - PostgreSQL, MongoDB 8.0, Redis, SQLite"
  echo "  cuda          - NVIDIA CUDA toolkit (driver already installed)"
  echo "  ml-libs       - OpenBLAS, LAPACK, FFTW3, OpenMPI, gfortran"
  echo "  r-lang        - R programming language (from CRAN)"
  echo "  infra         - Terraform, Ansible"
  echo "  security      - Trivy container scanner"
  echo "  firefox       - Firefox browser (if you want it back)"
  echo "  build-tools   - CMake, Ninja, Shellcheck, pre-commit"
  echo "  extras        - httpie, lynx, stress-ng, xvfb, python3-docx"
  echo "  math-libs     - libgmp, libmpfr, libmpc"
  echo "  codecs        - Ubuntu restricted addons (multimedia codecs)"
  echo "  all           - Install everything above"
  exit 1
}

[[ $# -eq 0 ]] && usage

install_databases() {
  echo "=== Installing databases ==="
  # MongoDB 8.0
  curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
    sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" \
    | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
  sudo apt-get update
  sudo apt-get install -y mongodb-org postgresql postgresql-client postgresql-contrib redis-server redis-tools sqlite3
}

install_cuda() {
  echo "=== Installing CUDA toolkit ==="
  # NVIDIA repo should already be configured from base install
  sudo apt-get update
  sudo apt-get install -y cuda-toolkit
}

install_ml_libs() {
  echo "=== Installing ML/science libraries ==="
  sudo apt-get install -y libopenblas-dev liblapack-dev libfftw3-dev libopenmpi-dev openmpi-bin gfortran
}

install_r_lang() {
  echo "=== Installing R ==="
  curl -fsSL https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | \
    sudo gpg --dearmor -o /usr/share/keyrings/r-project.gpg
  echo "deb [signed-by=/usr/share/keyrings/r-project.gpg] https://cloud.r-project.org/bin/linux/ubuntu noble-cran40/" \
    | sudo tee /etc/apt/sources.list.d/r-project.list
  sudo apt-get update
  sudo apt-get install -y r-base
}

install_infra() {
  echo "=== Installing Terraform & Ansible ==="
  curl -fsSL https://apt.releases.hashicorp.com/gpg | \
    sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com noble main" \
    | sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt-get update
  sudo apt-get install -y terraform ansible
}

install_security() {
  echo "=== Installing Trivy ==="
  curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | \
    sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
  echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb noble main" \
    | sudo tee /etc/apt/sources.list.d/trivy.list
  sudo apt-get update
  sudo apt-get install -y trivy
}

install_firefox() {
  echo "=== Installing Firefox ==="
  sudo snap install firefox
}

install_build_tools() {
  echo "=== Installing build tools ==="
  sudo apt-get install -y cmake ninja-build shellcheck pre-commit
}

install_extras() {
  echo "=== Installing extras ==="
  sudo apt-get install -y httpie lynx stress-ng xvfb python3-docx
}

install_math_libs() {
  echo "=== Installing math libraries ==="
  sudo apt-get install -y libgmp-dev libmpfr-dev libmpc-dev
}

install_codecs() {
  echo "=== Installing multimedia codecs ==="
  sudo apt-get install -y ubuntu-restricted-addons
}

install_all() {
  install_databases
  install_cuda
  install_ml_libs
  install_r_lang
  install_infra
  install_security
  install_firefox
  install_build_tools
  install_extras
  install_math_libs
  install_codecs
}

for category in "$@"; do
  case "$category" in
    databases)    install_databases ;;
    cuda)         install_cuda ;;
    ml-libs)      install_ml_libs ;;
    r-lang)       install_r_lang ;;
    infra)        install_infra ;;
    security)     install_security ;;
    firefox)     install_firefox ;;
    build-tools)  install_build_tools ;;
    extras)       install_extras ;;
    math-libs)    install_math_libs ;;
    codecs)       install_codecs ;;
    all)          install_all ;;
    *)            echo "Unknown category: $category"; usage ;;
  esac
done

echo "=== Done! ==="
