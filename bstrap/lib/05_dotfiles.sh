#!/bin/bash
# lib/05_dotfiles.sh
#
# Usage: 05_dotfiles.sh [-c|--copy] <src:dst ...>
#   src:dst   - colon separated source and destination pairs
#   -c|--copy - copy files instead of symlinking

if [ -z "${SCRIPT_DIR:-}" ]; then
    SCRIPT_DIR="$(dirname "$0")/.."
fi

source "${SCRIPT_DIR}/lib/helpers.sh"

GIT_REPO="${GIT_REPO:-}"
ROOT_DIR="${ROOT_DIR:-}"

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

if [ -n "$GIT_REPO" ] && [ -n "$ROOT_DIR" ]; then
    info "Cloning dotfiles from $GIT_REPO..."

    SPARSE_DIRS=()
    for pair in "${DOTFILE_PAIRS[@]}"; do
        src="${pair%%:*}"
        top_dir="${src%%/*}"
        if [[ ! " ${SPARSE_DIRS[*]} " =~ " $top_dir " ]]; then
            SPARSE_DIRS+=("$top_dir")
        fi
    done

    mkdir -p "$ROOT_DIR"
    git clone --no-checkout --depth=1 "$GIT_REPO" "$ROOT_DIR" || fail "Failed to clone $GIT_REPO"
    git -C "$ROOT_DIR" sparse-checkout init --cone
    git -C "$ROOT_DIR" sparse-checkout set "${SPARSE_DIRS[@]}"
    git -C "$ROOT_DIR" checkout || fail "Failed to checkout sparse dirs"
    ok "Cloned dotfiles to $ROOT_DIR"
fi

info "Deploying dotfiles..."
for pair in "${DOTFILE_PAIRS[@]}"; do
    src="${pair%%:*}"
    dst="${pair##*:}"

    [ -n "$ROOT_DIR" ] && src="$ROOT_DIR/$src"

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
