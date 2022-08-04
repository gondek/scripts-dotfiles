function com
    git checkout (git rev-parse --abbrev-ref origin/HEAD | cut -c8-)
end