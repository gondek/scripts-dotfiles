set -x N_PREFIX "$HOME/.n"

set -x PATH $PATH "$N_PREFIX/bin"
set -x PATH $PATH "$HOME/bin"
set -x PATH $PATH "$HOME/.cargo/bin"
set -x PATH $PATH "$HOME/.local/bin"

set -x fish_greeting

alias c="git commit"
alias s="git status"
alias co="git checkout"
alias d="git diff -w"
alias bat="batcat"
alias n="$N_PREFIX/bin/n"