#!/bin/bash
# bstrap.sh

set -euo pipefail

ALL_PROFILES=("minimal" "server" "desktop")

SCRIPT_DIR="$(dirname "$0")"
YAML="$SCRIPT_DIR/bstrap.yaml"

GIT_REPO="https://github.com/Obbaron/.dotfiles-et-al.git"
BRANCH="main"
SUB_DIR="bstrap" # empty string for no subdir
RAW_URL="${GIT_REPO/github.com/raw.githubusercontent.com}"
RAW_URL="${RAW_URL%.git}/$BRANCH${SUB_DIR:+/$SUB_DIR}"

PKG_MANAGER="" # override automatic distro detection

## PARSE ARG
if [ -n "${1:-}" ]; then
    PROFILE="$1"
else
    for i in "${!ALL_PROFILES[@]}"; do
        echo "$((i+1))) ${ALL_PROFILES[$i]}"
    done
    echo "0) Abort"
    read -rp "Select profile: " PROFILE
fi

PROFILE="${PROFILE,,}" # lowercase

if [ "$PROFILE" = "0" ] || [ "$PROFILE" = "abort" ]; then
    echo "Aborted."
    exit 1
fi

# Input is number: convert to name
if [[ "$PROFILE" =~ ^[0-9]+$ ]]; then
    idx=$((PROFILE - 1))
    if [ "$idx" -lt 0 ] || [ "$idx" -ge "${#ALL_PROFILES[@]}" ]; then
        echo "Invalid selection."
        exit 1
    fi
    PROFILE="${ALL_PROFILES[$idx]}"
else
    valid=false
    for p in "${ALL_PROFILES[@]}"; do
        if [ "$p" = "$PROFILE" ]; then
            valid=true
            break
        fi
    done
    if [ "$valid" = false ]; then
        echo "Unknown profile: $PROFILE"
        exit 1
    fi
fi


## INITIALIZE
if command -v curl &>/dev/null; then
    DOWNLOAD="curl -fsL"
    OUTPUT="-o"
elif command -v wget &>/dev/null; then
    DOWNLOAD="wget -q"
    OUTPUT="-O"
else
    echo "Error: Cannot bootstrap without curl or wget" >&2
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/lib/helpers.sh" ]; then
    mkdir -p "$SCRIPT_DIR/lib"
    curl -fsL "$RAW_URL/lib/helpers.sh" -o "$SCRIPT_DIR/lib/helpers.sh" || \
    wget -q "$RAW_URL/lib/helpers.sh" -O "$SCRIPT_DIR/lib/helpers.sh" || {
        echo "Error: Failed to download helpers.sh" >&2
        exit 1
    }
fi

source "$SCRIPT_DIR/lib/helpers.sh"

assert_not_root || { echo "Error: Do not run bootstrap as root - use a regular user with sudo access" >&2; exit 1; }

if ! build_lib "$SCRIPT_DIR/lib" "$RAW_URL/lib"; then
    rc=$?
    case "$rc" in
        1) error "build_lib failed (invalid args or no downloader found)" ;;
        2) error "build_lib failed (curl error)" ;;
        3) error "build_lib failed (wget error)" ;;
        *) error "build_lib failed (unknown error: $rc)" ;;
    esac
    exit "$rc"
fi

if [ ! -f "$YAML" ]; then
    $DOWNLOAD "$RAW_URL/bstrap.yaml" $OUTPUT "$YAML" || {
        echo "Error: Failed to download bstrap.yaml" >&2
        exit 1
    }
fi


## PARSE YAML
PARSED=$(YAML="$YAML" PROFILE="$PROFILE" DISTRO="$(detect_distro)" python3 - <<'EOF'
import yaml, os

yaml_path = os.environ["YAML"]
profile = os.environ["PROFILE"]
distro = os.environ["DISTRO"]

def expand(path):
    return os.path.expanduser(path)

with open(yaml_path) as f:
    config = yaml.safe_load(f)

packages = []
for category, pkgs in config.get("packages", {}).items():
    for pkg in pkgs:
        if profile in pkg.get("profiles", []):
            distro_map = pkg.get("distro", {})
            name = distro_map.get(distro, pkg["name"])
            packages.append(name)

directories = []
for category, dirs in config.get("directories", {}).items():
    for d in dirs:
        if profile in d.get("profiles", []):
            directories.append(expand(d["path"]))

permissions_raw = [p for p in config.get("permissions", []) if profile in p.get("profiles", [])]
services = [s["name"] for s in config.get("services", []) if profile in s.get("profiles", [])]
dotfiles_raw = [d for d in config.get("dotfiles", []) if profile in d.get("profiles", [])]

def arr(items):
    return "(" + " ".join(f'"{i}"' for i in items) + ")"

print(f"PACKAGES={arr(packages)}")
print(f"DIRECTORIES={arr(directories)}")
print(f"PERMISSIONS_PATH={arr(expand(p['path']) for p in permissions_raw)}")
print(f"PERMISSIONS_MODE={arr(p['mode'] for p in permissions_raw)}")
print(f"SERVICES={arr(services)}")
print(f"DOTFILES_SRC={arr(expand(d['src']) for d in dotfiles_raw)}")
print(f"DOTFILES_DST={arr(expand(d['dst']) for d in dotfiles_raw)}")
EOF
) || fail "Failed to parse bstrap.yaml"

eval "$PARSED"


## APPLY
# 01 packages
if [ "${#PACKAGES[@]}" -gt 0 ]; then
    source "$SCRIPT_DIR/lib/01_packages.sh" "${PACKAGES[@]}"
fi

# 02 directories
if [ "${#DIRECTORIES[@]}" -gt 0 ]; then
    source "$SCRIPT_DIR/lib/02_directories.sh" "${DIRECTORIES[@]}"
fi

# 03 permissions
if [ "${#PERMISSIONS_PATH[@]}" -gt 0 ]; then
    PERM_ARGS=()
    for i in "${!PERMISSIONS_PATH[@]}"; do
        PERM_ARGS+=("${PERMISSIONS_PATH[$i]}:${PERMISSIONS_MODE[$i]}")
    done
    source "$SCRIPT_DIR/lib/03_permissions.sh" --create "${PERM_ARGS[@]}"
fi

# 04 services
if [ "${#SERVICES[@]}" -gt 0 ]; then
    source "$SCRIPT_DIR/lib/04_services.sh" "${SERVICES[@]}"
fi

# 05 dotfiles
if [ "${#DOTFILES_SRC[@]}" -gt 0 ]; then
    DOTFILE_ARGS=()
    for i in "${!DOTFILES_SRC[@]}"; do
        DOTFILE_ARGS+=("${DOTFILES_SRC[$i]}:${DOTFILES_DST[$i]}")
    done
    source "$SCRIPT_DIR/lib/05_dotfiles.sh" "${GIT_REPO}" "${DOTFILE_ARGS[@]}"
fi


_lock() {
    local LOCK_FILE="$SCRIPT_DIR/bstrap.lock"

    info "Writing lock file: $LOCK_FILE"

    mkdir -p "$SCRIPT_DIR"

    {
        echo "# bstrap lock file"
        echo "VERSION=\"1.0.0\""
        echo "PROFILE=\"$PROFILE\""
        echo "PKG_MANAGER=\"${PKG_MANAGER:-}\""
        echo "TIMESTAMP=\"$(date -Iseconds)\""

        echo "PACKAGES=\"$(join_array "${PACKAGES[@]:-}")\""
        echo "DIRECTORIES=\"$(join_array "${DIRECTORIES[@]:-}")\""
        echo "SERVICES=\"$(join_array "${SERVICES[@]:-}")\""
        echo "FILES=\"$(join_array "${DOTFILES_DST[@]:-}")\""
        echo "PERMISSIONS_PATH=\"$(join_array "${PERMISSIONS_PATH[@]:-}")\""
        echo "PERMISSIONS_MODE=\"$(join_array "${PERMISSIONS_MODE[@]:-}")\""

    } > "$LOCK_FILE"
}
