fish_add_path -aP "$HOME/.cargo/bin" "$HOME/.local/bin"  # -P: edit $PATH directly; skips duplicates

# Homebrew (Linux or Apple Silicon macOS) goes last on PATH, so it never overrides system commands
for brew_prefix in /home/linuxbrew/.linuxbrew /opt/homebrew
    if test -d $brew_prefix
        fish_add_path -aP $brew_prefix/bin $brew_prefix/sbin
        set -a fish_complete_path $brew_prefix/share/fish/vendor_completions.d
    end
end

set -g fish_greeting  # no greeting

# XFCE doesn't export the keyring's ssh agent; use it when no other agent is set
if not set -q SSH_AUTH_SOCK; and set -q XDG_RUNTIME_DIR; and test -S $XDG_RUNTIME_DIR/gcr/ssh
    set -gx SSH_AUTH_SOCK $XDG_RUNTIME_DIR/gcr/ssh
end

# Only for interactive shells, so scripts and Tide's background shells skip them
if status is-interactive
    alias c="git commit"
    alias s="git status"
    alias co="git checkout"
    alias d="git diff -w"
    alias dcp="docker compose"

    # Ubuntu installs bat as batcat; elsewhere it's usually bat
    if not command -q bat; and command -q batcat
        alias bat="batcat"
    end

    if command -q fzf
        fzf --fish | source  # Ctrl+R history search, Alt+C cd
    end
end
