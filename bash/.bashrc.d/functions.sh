# functions.sh
# sourced by ~/.bashrc via ~/.bashrc.d/

[[ $- != *i* ]] && return


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

gut() {
    local dir=""
    local force=0

    for arg in "$@"; do
        case "$arg" in
            -f|--force)
                force=1
                ;;
            *)
                dir="$arg"
                ;;
        esac
    done

    if [ -z "$dir" ]; then
        echo "Usage: gut [-f|--force] /path/to/directory"
        return 1
    fi

    if [ "$dir" = "/" ]; then
        echo "Cannot gut root."
        return 1
    fi

    if [ "$force" -eq 1 ]; then
        find "$dir" -mindepth 1 -delete
        echo "Directory gutted (forced): $dir"
    else
        echo "About to delete ALL contents of: $dir"
        read -p "Are you sure? (y/N): " confirm

        # Param expansion (bash-only)
        confirm=${confirm,,}

        # Subshell version (posix)
        # confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')

        if [ "$confirm" = "y" ] || [ "$confirm" = "yes" ]; then
            find "$dir" -mindepth 1 -delete
            echo "Directory gutted."
        else
            echo "Cancelled."
        fi
    fi
}

pack () {
  [ -z "${1}" ] && { echo "Error: no output file specified" >&2; return 1; }
  [ "${#}" -lt 2 ] && { echo "Error: no input files specified" >&2; return 1; }

  local output="${1}"
  shift

  case "${output}" in
    *.tar)     tar -cvf  "${output}" "$@" ;;
    *.tar.gz)  tar -cvzf "${output}" "$@" ;;
    *.tar.bz2) tar -cvjf "${output}" "$@" ;;
    *.tar.xz)  tar -cvJf "${output}" "$@" ;;
    *.zip)     zip -r    "${output}" "$@" ;;
    *.rar)     rar a     "${output}" "$@" ;;
    *) echo "Unknown format" >&2; return 1 ;;
  esac
}


# Navigation
mkcd() {
  [ -z "${1}" ] && { echo "Usage: mkcd <dir>"; return 1; }
  mkdir -p -- "${1}" && cd -- "${1}"
}

f () {
  local dir
  dir="$(find . -type d | fzf)"

  local output=$?
  if [ $output -eq 130 ]; then
    echo "Cancelled" >&2
    return 130
  elif [ $output -ne 0 ]; then
    echo "Error: fzf failed" >&2
    return $output
  fi

  [ -z "${dir}" ] && {
    echo "No directory selected" >&2
    return 1
  }

  cd -- "${dir}" || return
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

tsip() { tailscale ip -4; }

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
