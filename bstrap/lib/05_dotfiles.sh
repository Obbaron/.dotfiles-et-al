#!/bin/bash
# lib/05_dotfiles.sh
#
# Usage: 05_dotfiles.sh [-c|--copy] <src:dst ...>
#   src:dst   - colon separated source and destination pairs
#   -c|--copy - copy files instead of symlinking
#
# Optional environment variables:
#   GIT_REPO      - git repo URL to sparse clone from
#   DOTFILES_ROOT - local path to clone repo into

if [ -z "${SCRIPT_DIR:-}" ]; then
    SCRIPT_DIR="$(dirname "$0")/.."
fi

source "${SCRIPT_DIR}/lib/helpers.sh"

GIT_REPO="${GIT_REPO:-}"
DOTFILES_ROOT="${DOTFILES_ROOT:-}"

USE_COPY=false

while [[ "${1:-}" == -* ]]; do
    case "$1" in
        -c|--copy) USE_COPY=true; shift ;;
        *) fail "Unknown flag: $1" ;;
    esac
done

if [ -z "${1:-}" ]; then
    fail "No dotfiles provided"
fi

DOTFILE_PAIRS=("$@")

# Git sparse clone if GIT_REPO and DOTFILES_ROOT are set
if [ -n "$GIT_REPO" ] && [ -n "$DOTFILES_ROOT" ]; then
    info "Cloning dotfiles from $GIT_REPO..."

    # Extract unique top-level dirs from src paths
    SPARSE_DIRS=()
    for pair in "${DOTFILE_PAIRS[@]}"; do
        src="${pair%%:*}"
        relative="${src#$DOTFILES_ROOT/}"
        top_dir="${relative%%/*}"
        if [[ ! " ${SPARSE_DIRS[*]} " =~ " $top_dir " ]]; then
            SPARSE_DIRS+=("$top_dir")
        fi
    done

    mkdir -p "$DOTFILES_ROOT"
    git clone --no-checkout --depth=1 "$GIT_REPO" "$DOTFILES_ROOT" || fail "Failed to clone $GIT_REPO"
    git -C "$DOTFILES_ROOT" sparse-checkout init --cone
    git -C "$DOTFILES_ROOT" sparse-checkout set "${SPARSE_DIRS[@]}"
    git -C "$DOTFILES_ROOT" checkout || fail "Failed to checkout sparse dirs"
    ok "Cloned dotfiles to $DOTFILES_ROOT"
fi

# Deploy dotfiles
info "Deploying dotfiles..."
for pair in "${DOTFILE_PAIRS[@]}"; do
    src="${pair%%:*}"
    dst="${pair##*:}"

    if [ ! -f "$src" ]; then
        fail "Source file does not exist: $src"
    fi

    mkdir -p "$(dirname "$dst")"

    if [ "$USE_COPY" = true ]; then
        cp "$src" "$dst" || fail "Failed to copy $src -> $dst"
        ok "Copied $src -> $dst"
    else
        ln -sf "$src" "$dst" || fail "Failed to symlink $src -> $dst"
        ok "Linked $src -> $dst"
    fi
done
ok "All dotfiles deployed"
