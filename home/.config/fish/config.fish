set fish_function_path $fish_function_path "/usr/share/powerline/bindings/fish"

set -x PATH $PATH ~/bin
set -x PATH $PATH ~/.n/bin
set -x PATH $PATH ~/.cargo/bin

set -x fish_greeting

powerline-setup
