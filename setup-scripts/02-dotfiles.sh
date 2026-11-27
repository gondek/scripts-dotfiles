#!/usr/bin/env bash
# copy dotfiles/ into ~ (overwrites changed files; never deletes)
source "$(dirname "$0")/utilities.sh"

DOTFILES="$REPO_DIR/dotfiles"
while IFS= read -r -d '' src; do
  rel="${src#"$DOTFILES"/}"
  dest="$HOME/$rel"
  if ! cmp -s "$src" "$dest"; then
    say "Updating ~/$rel"
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
  fi
done < <(find "$DOTFILES" -type f -print0)
