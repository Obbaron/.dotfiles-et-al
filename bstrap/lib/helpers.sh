#!/usr/bin/env bash
# lib/helpers.sh

[[ -n "${_HELPERS_SH_LOADED:-}" ]] && return 0
_HELPERS_SH_LOADED=1

_RESET='\033[0m'
_BOLD='\033[1m'
_RED='\033[0;31m'
_GREEN='\033[0;32m'
_YELLOW='\033[0;33m'
_CYAN='\033[0;36m'

info()  { printf "%b\n" "${_CYAN}${_BOLD}[INFO]${_RESET}  $*"; }
ok()    { printf "%b\n" "${_GREEN}${_BOLD}[ OK ]${_RESET}  $*"; }
warn()  { printf "%b\n" "${_YELLOW}${_BOLD}[WARN]${_RESET}  $*"; }
error() { printf "%b\n" "${_RED}${_BOLD}[ERR!]${_RESET}  $*" >&2; }
fail()    { error "$@"; exit 1; }
log_section() { echo ""; }


assert_not_root() {
    [[ "$EUID" -ne 0 ]]
}

command_exists() {
    command -v "$1" &>/dev/null
}

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        fail "Cannot detect distro — /etc/os-release not found"
    fi
}

install_pkg() {
    local distro
    distro="$(detect_distro)"
    case "$distro" in
        arch|manjaro|endeavouros|cachyos)
            sudo pacman -S --noconfirm "$@" || fail "Failed to install package(s): $*"
            ;;
        fedora|fedora-asahi-remix|rhel|centos)
            sudo dnf install -y "$@" || fail "Failed to install package(s): $*"
            ;;
        ubuntu|debian|linuxmint)
            sudo apt install -y "$@" || fail "Failed to install package(s): $*"
            ;;
        opensuse-leap|opensuse-tumbleweed)
            sudo zypper install -y "$@" || fail "Failed to install package(s): $*"
            ;;
        gentoo)
            sudo emerge "$@" || fail "Failed to install package(s): $*"
            ;;
        void)
            sudo xbps-install -y "$@" || fail "Failed to install package(s): $*"
            ;;
        *)
            fail "Unsupported distro: $distro"
            ;;
    esac
}

build_lib() {
    local dest="${1:-}"
    local url="${2:-}"

    if [ -z "$dest" ] || [ -z "$url" ]; then
        fail "build_lib requires 2 arguments: <dest> <url>"
    fi

    local scripts=(
        "helpers.sh"
        "01_packages.sh"
        "02_directories.sh"
        "03_permissions.sh"
        "04_services.sh"
        "05_dotfiles.sh"
    )
    for script in "${scripts[@]}"; do
        if [ ! -f "$dest/$script" ]; then
            if command -v curl &>/dev/null; then
                curl -fsL "$url/$script" -o "$dest/$script" || fail "Failed to download $script"
            elif command -v wget &>/dev/null; then
                wget -q "$url/$script" -O "$dest/$script" || fail "Failed to download $script"
            else
                fail "Cannot download $script — neither curl nor wget found"
            fi
        fi
    done
}
