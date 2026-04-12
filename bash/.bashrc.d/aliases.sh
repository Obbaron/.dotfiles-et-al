# aliases.sh
# sourced by ~/.bashrc via ~/.bashrc.d/

[[ $- != *i* ]] && return

alias config="$EDITOR ~/.bashrc"
alias aliases="$EDITOR ~/.bashrc.d/aliases.sh"
alias functions="$EDITOR ~/.bashrc.d/functions.sh"

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
alias jctl="journalctl -p 3 -xb"
