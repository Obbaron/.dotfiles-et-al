# aliases.sh
# sourced by ~/.bashrc via ~/.bashrc.d/

[[ $- != *i* ]] && return

alias config="$EDITOR ~/.bashrc"
alias aliases="$EDITOR ~/.bashrc.d/aliases.sh"
alias functions="$EDITOR ~/.bashrc.d/functions.sh"

alias reload='source ~/.bashrc'

alias dir="dir --color=auto"
alias vdir="vdir --color=auto"
alias grep="grep --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto"
alias jctl="journalctl -p 3 -xb"
alias psmem="ps auxf | sort -nr -k 4"
alias psmem10="ps auxf | sort -nr -k 4 | head -10"
alias h='history'
alias hg='history | grep'
alias df='df -h'
alias du='du -h'
alias free='free -h'

# alias ls='ls --color=auto'
# alias grep='grep --color=auto'
alias ls="eza -al --color=always --group-directories-first --icons"
alias la="eza -a --color=always --group-directories-first --icons"
alias ll="eza -l --color=always --group-directories-first --icons"
alias lt="eza -at --color=always --group-directories-first --icons"
alias l.="eza -a | grep -e '^\.'"

alias b='btop'
alias ff='fastfetch'
alias c='clear'
alias q='exit'
alias wget="wget -c"

alias ipkg='install_pkg'
alias upkg='update_pkg'

alias bigboi="ssh guggoo@BigBoi"
