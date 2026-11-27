#!/usr/bin/env bash
# log in to GitHub with gh, upload the SSH key for auth and signing, switch this repo to ssh
source "$(dirname "$0")/utilities.sh"

GH_SCOPES=(admin:public_key admin:ssh_signing_key)

if [[ ! -f "$SSH_KEY.pub" ]]; then
  say_error "No SSH key at $SSH_KEY. Run the ssh stage first: ./setup.sh ssh"
  exit 1
fi

if ! gh auth status -h github.com >/dev/null 2>&1; then
  require_terminal "Logging in to GitHub"
  say "Logging in to GitHub"
  gh auth login -h github.com -p ssh --web --skip-ssh-key -s "$(IFS=,; echo "${GH_SCOPES[*]}")"
fi
GH_STATUS="$(gh auth status -h github.com 2>&1)"
for scope in "${GH_SCOPES[@]}"; do
  if [[ "$GH_STATUS" != *"'$scope'"* ]]; then
    require_terminal "Asking GitHub for permission to manage SSH keys"
    say "Asking GitHub for permission to manage SSH keys"
    gh auth refresh -h github.com -s "$(IFS=,; echo "${GH_SCOPES[*]}")"
    break
  fi
done
# `gh ssh-key list` (not on a terminal) prints tab-separated rows ending in the key's type
KEY_BODY="$(cut -d' ' -f2 "$SSH_KEY.pub")"
gh ssh-key list > "$WORK_DIR/keys"
for type in authentication signing; do
  if ! awk -F'\t' -v key="$KEY_BODY" -v type="$type" \
    'index($0, key) && $NF == type { found = 1 } END { exit !found }' "$WORK_DIR/keys"; then
    say "Uploading the SSH key to GitHub (for $type)"
    gh ssh-key add "$SSH_KEY.pub" --type "$type" --title "$MACHINE_NAME"
  fi
done

# GitHub's SSH host keys, from GitHub's API (over HTTPS), so the first ssh connection to
# github.com doesn't ask to trust an unknown host
if ! ssh-keygen -F github.com -f "$HOME/.ssh/known_hosts" >/dev/null 2>&1; then
  say "Adding GitHub's SSH host keys to ~/.ssh/known_hosts"
  gh api meta --jq '.ssh_keys[]' | sed 's/^/github.com /' >> "$HOME/.ssh/known_hosts"
fi

# switch this repo's remote from https to ssh, now that GitHub has the key
ORIGIN="$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null || true)"
if [[ "$ORIGIN" == https://github.com/* ]]; then
  say "Switching this repo's remote to ssh"
  git -C "$REPO_DIR" remote set-url origin "git@github.com:${ORIGIN#https://github.com/}"
fi
