# .bashrc

PS1='\[\e[32m\]\u\[\e[2;32m\]@\h\[\e[0m\]:\[\e[32m\]\w\[\e[0m\]\$ '

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# History
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend
shopt -s checkwinsize
shopt -s cdspell

# User aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc
