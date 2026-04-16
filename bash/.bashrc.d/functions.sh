# functions.sh
# sourced by ~/.bashrc via ~/.bashrc.d/

[[ $- != *i* ]] && return


# Networking
pubip() { curl -s https://icanhazip.com; }

isup() { ping -c1 "$1" &>/dev/null && echo "up" || echo "down"; }

ports () {
  if [ -n "${1}" ]; then
    ss -tulnp | grep -i -- "${1}"
  else
    ss -tulnp
  fi
}


# Navigation
mkcd() {
  [ -z "${1}" ] && { echo "Usage: mkcd <dir>"; return 1; }
  mkdir -p -- "${1}" && cd -- "${1}"
}

f () {
  local dir
  dir="$(find . -type d | fzf)" || return
  [ -n "${dir}" ] && cd -- "${dir}"
}

up() {
  local n="${1:-1}"
  cd "$(printf '../%.0s' $(seq 1 "${n}"))" || return
}

y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        command yazi "$@" --cwd-file="$tmp"
        IFS= read -r -d '' cwd < "$tmp"
        [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
        rm -f -- "$tmp"
}


# File managment
backup () {
  [ -z "${1}" ] && { echo "Usage: backup <file>"; return 1; }
  [ ! -e "${1}" ] && { echo "Error: file not found"; return 1; }

  cp -- "${1}" "${1}.$(date +%Y%m%d%H%M%S).bak"
}

extract () {
  [ -f "${1}" ] || { echo "Error: file not found"; return 1; }

  case "${1}" in
    *.tar.gz) tar -xzf "${1}" ;;
    *.tar.bz2) tar -xjf "${1}" ;;
    *.zip) unzip "${1}" ;;
    *.rar) unrar x "${1}" ;;
    *) echo "Unknown format" ;;
  esac
}

gut () {
  force=false

  while [ $# -gt 0 ]; do
    case "$1" in
      --force)
        force=true
        shift
        ;;
      *)
        break
        ;;
    esac
  done

  dir="${1}"

  if [ -z "${dir}" ]; then
    echo "Error: missing directory"
    echo "Usage: gut [--force] <directory>"
    return 1
  fi

  if [ ! -d "${dir}" ]; then
    echo "Error: '${dir}' is not a directory"
    return 1
  fi

  dir="$(cd "${dir}" 2>/dev/null && pwd)"

  if [ -z "${dir}" ]; then
    echo "Error: could not resolve directory"
    return 1
  fi

  if [ "${dir}" = "/" ]; then
    echo "Refusing to operate on /"
    return 1
  fi

  echo "About to delete ALL contents of:"
  echo "  ${dir}"
  echo

  if [ "${force}" != true ]; then
    read -p "Are you sure? (y/N): " confirm
    case "${confirm}" in
      y|Y) ;;
      *) echo "Aborted."; return 1 ;;
    esac
  fi

  find "${dir}" -mindepth 1 -delete
  echo "Done."
}
