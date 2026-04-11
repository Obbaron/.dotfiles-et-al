#!/bin/bash
# bstrap.sh

set -euo pipefail

ALL_PROFILES=("minimal" "server" "desktop")

SCRIPT_DIR="$(dirname "$0")"
YAML="$SCRIPT_DIR/bstrap.yaml"
BSTRAP_REPO="https://github.com/Obbaron/.bstrap.git"
BRANCH="main"

RAW_URL="${BSTRAP_REPO/github.com/raw.githubusercontent.com}"
RAW_URL="${RAW_URL%.git}/$BRANCH"


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
    # Input is name: find it in array
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
    $DOWNLOAD "$RAW_URL/lib/helpers.sh" $OUTPUT "$SCRIPT_DIR/lib/helpers.sh" || {
        echo "Error: Failed to download helpers.sh" >&2
        exit 1
    }
fi
source "$SCRIPT_DIR/lib/helpers.sh"

assert_not_root

build_lib "$SCRIPT_DIR/lib" "$RAW_URL/lib"

if [ ! -f "$YAML" ]; then
    $DOWNLOAD "$RAW_URL/bstrap.yaml" $OUTPUT "$YAML" || {
        echo "Error: Failed to download bstrap.yaml" >&2
        exit 1
    }
fi


## PYYAML
if ! python3 -c "import yaml" &>/dev/null; then
    if ! command_exists python3; then
        info "python3 not found, installing..."
        install_pkg python3
    fi
    info "python3-yaml not found, installing..."
    case "$(detect_distro)" in
        arch|manjaro|endeavouros|cachyos)
            install_pkg python-yaml
            ;;
        fedora|fedora-asahi-remix|rhel|centos)
            install_pkg python3-pyyaml
            ;;
        ubuntu|debian|linuxmint)
            install_pkg python3-yaml
            ;;
        opensuse-leap|opensuse-tumbleweed)
            install_pkg python3-PyYAML
            ;;
        gentoo)
            install_pkg dev-python/pyyaml
            ;;
        void)
            install_pkg python3-PyYAML
            ;;
        *)
            fail "Don't know how to install PyYAML on $(detect_distro)"
            ;;
    esac
fi

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

directories = [expand(d["path"]) for d in config.get("directories", []) if profile in d.get("profiles", [])]
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


## PIPELINE
# 01 packages
if [ ! -f "$SCRIPT_DIR/lib/01_packages.sh" ]; then
    $DOWNLOAD "$RAW_URL/lib/01_packages.sh" $OUTPUT "$SCRIPT_DIR/lib/01_packages.sh" || fail "Failed to download 01_packages.sh"
fi
if [ "${#PACKAGES[@]}" -gt 0 ]; then
    source "$SCRIPT_DIR/lib/01_packages.sh" "${PACKAGES[@]}"
fi

# 02 directories
if [ ! -f "$SCRIPT_DIR/lib/02_directories.sh" ]; then
    $DOWNLOAD "$RAW_URL/lib/02_directories.sh" $OUTPUT "$SCRIPT_DIR/lib/02_directories.sh" || fail "Failed to download 02_directories.sh"
fi
if [ "${#DIRECTORIES[@]}" -gt 0 ]; then
    source "$SCRIPT_DIR/lib/02_directories.sh" "${DIRECTORIES[@]}"
fi

# 03 permissions
if [ ! -f "$SCRIPT_DIR/lib/03_permissions.sh" ]; then
    $DOWNLOAD "$RAW_URL/lib/03_permissions.sh" $OUTPUT "$SCRIPT_DIR/lib/03_permissions.sh" || fail "Failed to download 03_permissions.sh"
fi
if [ "${#PERMISSIONS_PATH[@]}" -gt 0 ]; then
    PERM_ARGS=()
    for i in "${!PERMISSIONS_PATH[@]}"; do
        PERM_ARGS+=("${PERMISSIONS_PATH[$i]}:${PERMISSIONS_MODE[$i]}")
    done
    source "$SCRIPT_DIR/lib/03_permissions.sh" --create "${PERM_ARGS[@]}"
fi

# 04 services
if [ ! -f "$SCRIPT_DIR/lib/04_services.sh" ]; then
    $DOWNLOAD "$RAW_URL/lib/04_services.sh" $OUTPUT "$SCRIPT_DIR/lib/04_services.sh" || fail "Failed to download 04_services.sh"
fi
if [ "${#SERVICES[@]}" -gt 0 ]; then
    source "$SCRIPT_DIR/lib/04_services.sh" "${SERVICES[@]}"
fi

# 05 dotfiles
