#!/bin/bash
# lib/05_dotfiles.sh

if [ -z "${SCRIPT_DIR:-}" ]; then
    SCRIPT_DIR="$(dirname "$0")/.."
fi

source "${SCRIPT_DIR}/lib/helpers.sh"

DOTFILES_SRC="${1:-}"
if [ -z "$DOTFILES_SRC" ]; then
    fail "No source directory or URL provided"
fi
shift

USE_CLONE=false
USE_SKIP=false

while [[ "${1:-}" == -* ]]; do
    case "$1" in
        -c|--clone) USE_CLONE=true; shift ;;
        -s|--skip) USE_SKIP=true; shift;;
        *) fail "Unknown flag: $1" ;;
    esac
done

if [ -z "${1:-}" ]; then
    fail "No dotfiles provided"
fi

if [[ "$DOTFILES_SRC" =~ ^https?:// ]]; then
    if [ "$USE_CLONE" = true ]; then
        info "Cloning dotfiles from $DOTFILES_SRC..."
        # git clone
    else
        info "Downloading dotfiles from $DOTFILES_SRC..."
        # download individual files
    fi
else
    info "Dotfiles source is a local path: $DOTFILES_SRC"
    # handle local path
fi
