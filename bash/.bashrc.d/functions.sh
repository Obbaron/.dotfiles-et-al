# functions.sh
# sourced by ~/.bashrc via ~/.bashrc.d/

[[ $- != *i* ]] && return


# Networking
pubip() { curl -s https://icanhazip.com; }

isup() { ping -c1 "$1" &>/dev/null && echo "up" || echo "down"; }

ports() { ss -tulanp; }


# Navigation
up() { cd $(printf '../%.0s' $(seq 1 "$1")); }

mkcd() { mkdir -p "$1" && cd "$1"; }

y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        command yazi "$@" --cwd-file="$tmp"
        IFS= read -r -d '' cwd < "$tmp"
        [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
        rm -f -- "$tmp"
}
