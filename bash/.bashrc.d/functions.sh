# functions.sh
# sourced by ~/.bashrc via ~/.bashrc.d/

[[ $- != *i* ]] && return

PROTECTED_ROOTS=(/ /home /usr /etc /bin /sbin /lib /lib64 /boot /var)

is_protected_root() {
  local target="${1}"

  for root in "${PROTECTED_ROOTS[@]}"; do
    if [ "${target}" = "${root}" ]; then
      return 0
    fi
  done

  return 1
}

# File ops
backup () {
  [ -z "${1}" ] && { echo "Usage: backup <file>"; return 1; }
  [ ! -e "${1}" ] && { echo "Error: file not found" >&2; return 1; }

  cp -- "${1}" "${1}.$(date +%Y%m%d%H%M%S).bak"
}

extract () {
  [ -f "${1}" ] || { echo "Error: file not found" >&2; return 1; }

  case "${1}" in
    *.tar.gz) tar -xzf "${1}" ;;
    *.tar.bz2) tar -xjf "${1}" ;;
    *.zip) unzip "${1}" ;;
    *.rar) unrar x "${1}" ;;
    *) echo "Unknown format" >&2; return 1 ;;
  esac
}

gut () {
  force=false
  dry_run=false

  while [ $# -gt 0 ]; do
    case "$1" in
      -f|--force)
        force=true
        shift
        ;;
      -n|--dry-run)
        dry_run=true
        shift
        ;;
      --)
        shift
        break
        ;;
      -*)
        echo "Unknown option: $1" >&2
        return 1
        ;;
      *)
        break
        ;;
    esac
  done

  local dir="${1:-}"

  if [ -z "${dir}" ]; then
    echo "Error: missing directory" >&2
    echo "Usage: gut [-f|--force] [-n|--dry-run] <directory>" >&2
    return 1
  fi

  if [ ! -d "${dir}" ]; then
    echo "Error: '${dir}' is not a directory" >&2
    return 1
  fi

  dir="$(cd "${dir}" 2>/dev/null && pwd)" || return 1

  if [ -z "${dir}" ]; then
    echo "Error: could not resolve directory" >&2
    return 1
  fi

  if is_protected_root "${dir}"; then
    echo "Refusing to operate on protected root directory: ${dir}" >&2
    return 1
  fi

  echo "Target directory:"
  echo "  ${dir}"
  echo

  if [ "${dry_run}" = true ]; then
    echo "[DRY RUN] Would delete:"
    find "${dir}" -mindepth 1
    return 0
  fi

  if [ "${force}" != true ]; then
    printf "Are you sure? (y/N): "
    IFS= read -r confirm

    case "${confirm}" in
      y|Y) ;;
      *) echo "Aborted." >&2; return 1 ;;
    esac
  fi

  find "${dir}" -mindepth 1 -delete
  echo "Done."
}

# Navigation
mkcd() {
  [ -z "${1}" ] && { echo "Usage: mkcd <dir>"; return 1; }
  mkdir -p -- "${1}" && cd -- "${1}"
}

f () {
  command -v fzf >/dev/null 2>&1 || {
    echo "Error: fzf not installed" >&2
    return 1
  }

  local dir
  dir="$(find . -type d | fzf)" || return
  [ -n "${dir}" ] && cd -- "${dir}"
}

up() {
  local n="${1:-1}"

  [[ "${n}" =~ ^-?[0-9]+$ ]] || {
    echo "Usage: up <integer>" >&2
    return 1
  }

  (( n < 1 )) && n=1

  cd "$(printf '../%.0s' $(seq 1 "${n}"))" || return
}

y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        command yazi "$@" --cwd-file="$tmp"
        IFS= read -r -d '' cwd < "$tmp"
        [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
        rm -f -- "$tmp"
}

# Networking
pubip() { curl -s https://icanhazip.com; }

isup() {
  [ -z "$1" ] && { echo "Usage: isup <host>" >&2; return 1; }

  if ping -c1 "$1" >/dev/null 2>&1; then
    echo "up"
  else
    echo "down"
  fi
}

ports () {
  [ -n "${1}" ] || { ss -tulnp; return; }

  ss -tulnp | grep -F -i -- "${1}"
}
