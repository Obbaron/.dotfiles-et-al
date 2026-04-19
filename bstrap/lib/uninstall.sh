#!/bin/bash
# lib/uninstall.sh

set -euo pipefail

if [ -z "${SCRIPT_DIR:-}" ]; then
    SCRIPT_DIR="$(dirname "$0")/.."
fi

LOCK_FILE="$SCRIPT_DIR/bstrap.lock"

PROTECTED_DIRS=(
    "$HOME"
    "$HOME/.config"
    "$HOME/.local"
    "$HOME/.local/share"
    "$HOME/.local/bin"
    "$HOME/Documents"
    "$HOME/Downloads"
    "$HOME/Desktop"
    "$HOME/Pictures"
    "$HOME/Videos"
    "$HOME/Audio"
    "$HOME/.ssh"
)

if [ ! -f "$LOCK_FILE" ]; then
    echo "Error: No lock file found at $LOCK_FILE" >&2
    exit 1
fi

source "$SCRIPT_DIR/lib/helpers.sh"
source "$LOCK_FILE"

assert_not_root || { echo "Error: Do not run as root - use a regular user with sudo access" >&2; exit 1; }

is_protected() {
    local dir="$1"
    for protected in "${PROTECTED_DIRS[@]}"; do
        if [ "$dir" = "$protected" ]; then
            return 0
        fi
    done
    return 1
}

# 05 dotfiles — remove symlinks or files
info "Removing dotfiles..."
IFS="," read -ra FILES_ARR <<< "$FILES"
for dst in "${FILES_ARR[@]}"; do
    if [ -L "$dst" ]; then
        rm "$dst" && ok "Removed symlink: $dst" || warn "Failed to remove symlink: $dst"
    elif [ -f "$dst" ]; then
        rm "$dst" && ok "Removed file: $dst" || warn "Failed to remove file: $dst"
    else
        warn "Not found, skipping: $dst"
    fi
done

# 04 services — stop and disable
info "Stopping and disabling services..."
IFS="," read -ra SERVICES_ARR <<< "$SERVICES"
for svc in "${SERVICES_ARR[@]}"; do
    sudo systemctl stop "$svc" && ok "Stopped $svc" || warn "Failed to stop $svc"
    sudo systemctl disable "$svc" && ok "Disabled $svc" || warn "Failed to disable $svc"
done

# 02 directories — remove if not protected
info "Removing directories..."
IFS="," read -ra DIRECTORIES_ARR <<< "$DIRECTORIES"
for dir in "${DIRECTORIES_ARR[@]}"; do
    if is_protected "$dir"; then
        warn "Skipping protected directory: $dir"
    elif [ -d "$dir" ]; then
        rm -rf "$dir" && ok "Removed directory: $dir" || warn "Failed to remove directory: $dir"
    else
        warn "Directory not found, skipping: $dir"
    fi
done

# 01 packages — uninstall
info "Uninstalling packages..."
IFS="," read -ra PACKAGES_ARR <<< "$PACKAGES"
case "$PKG_MANAGER" in
    pacman)
        sudo pacman -Rns --noconfirm "${PACKAGES_ARR[@]}" || warn "Some packages failed to uninstall"
        ;;
    dnf)
        sudo dnf remove -y "${PACKAGES_ARR[@]}" || warn "Some packages failed to uninstall"
        ;;
    apt)
        sudo apt remove -y "${PACKAGES_ARR[@]}" || warn "Some packages failed to uninstall"
        ;;
    zypper)
        sudo zypper remove -y "${PACKAGES_ARR[@]}" || warn "Some packages failed to uninstall"
        ;;
    emerge)
        sudo emerge --unmerge "${PACKAGES_ARR[@]}" || warn "Some packages failed to uninstall"
        ;;
    xbps-install)
        sudo xbps-remove -y "${PACKAGES_ARR[@]}" || warn "Some packages failed to uninstall"
        ;;
    *)
        warn "Unknown package manager: $PKG_MANAGER — skipping package removal"
        ;;
esac
ok "Packages uninstalled"

# Remove lock file
rm "$LOCK_FILE" && ok "Lock file removed"

ok "Uninstall complete"
