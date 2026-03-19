#
# ~/.bashrc
#

[[ $- != *i* ]] && return

PS1='[\u@\h \W]\$ '

alias ls='ls --color=auto'
alias grep='grep --color=auto'

alias ls="eza -al --color=always --group-directories-first --icons"
alias la="eza -a --color=always --group-directories-first --icons"
alias ll="eza -l --color=always --group-directories-first --icons"
alias lt="eza -at --color=always --group-directories-first --icons"
alias l.="eza -a | grep -e '^\.'"

alias b='btop'
alias ff='fastfetch'
alias c='clear'
alias q='exit'
alias config="$EDITOR ~/.bashrc"
alias grubup="sudo grub-mkconfig -o /boot/grub/grub.cfg"
alias fixpacman="sudo rm /var/lib/pacman/db.lck"
alias tarhow="tar -acf"
alias untar="tar -zxvf"
alias wget="wget -c"
alias psmem="ps auxf | sort -nr -k 4"
alias psmem10="ps auxf | sort -nr -k 4 | head -10"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."
alias dir="dir --color=auto"
alias vdir="vdir --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto"
alias hw="hwinfo --short"
alias big="expac -H M '%m\t%n' | sort -h | nl"
alias gitpkg="pacman -Q | grep -i '\-git' | wc -l"
alias update="sudo pacman -Syu"
alias jctl="journalctl -p 3 -xb"
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"

function cleanup() {
    sudo pacman -Rns $(pacman -Qtdq)
}

function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

eval "$(starship init bash)"
fastfetch
