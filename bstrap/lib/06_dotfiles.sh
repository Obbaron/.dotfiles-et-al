#!/bin/bash
# lib/06_dotfiles.sh

if [ -z "${SCRIPT_DIR:-}" ]; then
    SCRIPT_DIR="$(dirname "$0")/.."
fi

source "${SCRIPT_DIR}/lib/helpers.sh"

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

DOTFILE_PAIRS=()
GIT_REPO=""
ROOT_DIR=""

for arg in "$@"; do
    if [[ "$arg" =~ ^https?:// ]]; then
        GIT_REPO="$arg"
    elif [[ "$arg" =~ : ]]; then
        DOTFILE_PAIRS+=("$arg")
    else
        ROOT_DIR="$arg"
    fi
done

if [ -z "${DOTFILE_PAIRS[*]}" ]; then
    fail "No dotfile pairs provided"
fi

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
