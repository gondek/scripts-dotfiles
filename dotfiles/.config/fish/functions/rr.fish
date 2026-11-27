function rr --description "Hard-reset the current branch to its upstream"
    set -l upstream (git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)
    or begin
        echo "rr: no upstream to reset to" >&2
        return 1
    end
    read -l -P "git reset --hard $upstream ? [y/n] " confirm
    switch $confirm
        case Y y
            git reset --hard $upstream
    end
end
