#!/bin/bash
# lib/01_packages.sh

if [ -z "${SCRIPT_DIR:-}" ]; then
    SCRIPT_DIR="$(dirname "$0")/.."
fi

source "${SCRIPT_DIR}/lib/helpers.sh"

if [ -z "${1:-}" ]; then
    fail "No packages provided"
fi

PACKAGES=("$@")

info "Installing packages: ${PACKAGES[*]}..."
install_pkg "${PACKAGES[@]}"
ok "All packages installed"
