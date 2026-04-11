#!/bin/bash
# lib/05_dotfiles.sh

if [ -z "${SCRIPT_DIR:-}" ]; then
    SCRIPT_DIR="$(dirname "$0")/.."
fi

source "${SCRIPT_DIR}/lib/helpers.sh"

SKIP_MISSING=false

while [[ "${1:-}" == -* ]]; do
    case "$1" in
        -s|--skip) SKIP_MISSING=true; shift ;;
        *) fail "Unknown flag: $1" ;;
    esac
done

if [ -z "${1:-}" ]; then
    fail "No dotfiles provided"
fi

# ...
