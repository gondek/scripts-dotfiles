#!/usr/bin/env bash
# per-machine SSH key (passphrase required), also used for git commit signing
source "$(dirname "$0")/utilities.sh"

SSH_CONFIG="$HOME/.ssh/config"
SSH_OPTIONS=("AddKeysToAgent yes")  # ask for the passphrase once per login session, not every use
if [[ "$OS" == macos ]]; then
  SSH_OPTIONS+=("UseKeychain yes")  # and remember it in the macOS keychain
fi

# key_has_passphrase: whether the key needs a passphrase to open. Stops on any other error
# (like bad file permissions), rather than mistaking it for a passphrase.
key_has_passphrase() {
  local output
  if output="$(ssh-keygen -y -P '' -f "$SSH_KEY" 2>&1)"; then
    return 1
  fi
  if [[ "$output" == *"incorrect passphrase"* ]]; then
    return 0
  fi
  say_error "Couldn't read $SSH_KEY: $output"
  exit 1
}

EMAIL="$(git config --global user.email || true)"
if [[ -z "$EMAIL" ]]; then
  say_error "git has no user.email yet. Run the dotfiles stage first: ./setup.sh dotfiles"
  exit 1
fi

if [[ ! -f "$SSH_KEY" ]]; then
  require_terminal "Creating an SSH key"
  mkdir -p -m 700 "$HOME/.ssh"
  say "Generating a new key for this machine. A passphrase is required."
  ssh-keygen -q -t ed25519 -C "$MACHINE_NAME" -f "$SSH_KEY"  # -q: just the passphrase prompts
fi
until key_has_passphrase; do
  require_terminal "Setting the SSH key's passphrase"
  say "$SSH_KEY has no passphrase. Set one now (required)."
  ssh-keygen -p -P '' -f "$SSH_KEY" || true
done

if [[ ! -f "$SSH_KEY.pub" ]]; then
  say_error "$SSH_KEY.pub is missing. Recreate it with: ssh-keygen -y -f $SSH_KEY > $SSH_KEY.pub"
  exit 1
fi

# lets `git log --show-signature` verify commits made with this key
SIGNER="$EMAIL $(cat "$SSH_KEY.pub")"
if ! grep -qxF "$SIGNER" "$HOME/.ssh/allowed_signers" 2>/dev/null; then
  say "Adding the key to ~/.ssh/allowed_signers"
  echo "$SIGNER" >> "$HOME/.ssh/allowed_signers"
fi

# Sign commits with this key. This lives in ~/.gitconfig.local (included by ~/.gitconfig), not
# the shared dotfiles, so git only signs once the key above is ready. Paths are absolute
# because git doesn't expand ~ for every signing operation.
GIT_SIGNING=(
  "gpg.format ssh"
  "user.signingkey $SSH_KEY.pub"
  "gpg.ssh.allowedSignersFile $HOME/.ssh/allowed_signers"
  "commit.gpgsign true"
)
for setting in "${GIT_SIGNING[@]}"; do
  key="${setting%% *}"
  value="${setting#* }"
  if [[ "$(git config --file "$HOME/.gitconfig.local" --get "$key" || true)" != "$value" ]]; then
    say "Setting git's $key to $value in ~/.gitconfig.local"
    git config --file "$HOME/.gitconfig.local" "$key" "$value"
  fi
done

# Global ssh options go at the top of ~/.ssh/config, before any Host block, without touching
# the rest of the file. An option already set anywhere in the file is left alone.
for option in "${SSH_OPTIONS[@]}"; do
  if ! grep -qiE "^[[:space:]]*${option%% *}([[:space:]]|=)" "$SSH_CONFIG" 2>/dev/null; then
    say "Adding '$option' to the top of ~/.ssh/config"
    { echo "$option"; cat "$SSH_CONFIG" 2>/dev/null || true; } > "$WORK_DIR/ssh_config"
    install -m 600 "$WORK_DIR/ssh_config" "$SSH_CONFIG"
  fi
done
