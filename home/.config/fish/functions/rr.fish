function rr
    set -l current_branch (git branch --show-current)
    read -l -P "git reset --hard origin/$current_branch ? [y/n] " confirm
    switch $confirm
      case Y y
        git reset --hard "origin/$current_branch"
    end
end
