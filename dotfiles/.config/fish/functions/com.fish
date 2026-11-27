function com --description "Switch to origin's default branch"
    set -l ref (git symbolic-ref -q refs/remotes/origin/HEAD)
    or begin
        echo "com: origin/HEAD is not set. Run: git remote set-head origin --auto" >&2
        return 1
    end
    git switch (string replace -- refs/remotes/origin/ '' $ref)
end
