#!/usr/bin/env bash
# Homebrew, for CLI tools that apt doesn't carry or keeps outdated.
# Follows the parts of Homebrew's official install.sh that set up a fresh install (directories,
# git checkout, first update), done here directly so no downloaded installer script is run.
source "$(dirname "$0")/utilities.sh"

BREW_GIT_URL=https://github.com/Homebrew/brew
BREW_PACKAGES=(
  gh
  k9s
  kubernetes-cli
)

# Everything below until "fi" is a fresh install; a re-run with brew present skips it.
# Steps up to the git checkout each check their own state, so a run that stopped there can be
# re-run. If only the final `brew update` failed, the next `brew install` updates brew anyway.
if [[ ! -x "$BREW" ]]; then
  say "Installing Homebrew"
  if [[ "$OS" == linux ]]; then
    # Homebrew's dependencies on Linux
    apt_install build-essential procps curl file git
    BREW_GROUP="$(id -gn)"
  else
    if [[ "$(uname -m)" != arm64 ]]; then
      say_error "This setup only supports Homebrew on Apple Silicon Macs."
      exit 1
    fi
    # Homebrew needs the Xcode Command Line Tools (they also provide git)
    if ! xcode-select -p >/dev/null 2>&1; then
      xcode-select --install
      say_error "Finish the Command Line Tools install in the popup, then run this again."
      exit 1
    fi
    # same group choice as install.sh: admin if the user is in that group
    if id -Gn | grep -qw admin; then
      BREW_GROUP=admin
    else
      BREW_GROUP="$(id -gn)"
    fi
  fi

  # Creating the prefix is the only step that needs root; everything inside it is owned by the user
  if [[ ! -d "$BREW_PREFIX" ]]; then
    sudo install -d -o "$USER" -g "$BREW_GROUP" -m 0755 "$BREW_PREFIX"
  fi

  # The directory layout install.sh creates. Group-writable, except the zsh
  # completion dirs, which zsh refuses to read if they're group-writable.
  for dir in bin etc include lib libexec sbin share var opt var/homebrew var/homebrew/linked \
    Cellar Caskroom Frameworks; do
    mkdir -p "$BREW_PREFIX/$dir"
    chmod 775 "$BREW_PREFIX/$dir"
  done
  mkdir -p "$BREW_PREFIX/share/zsh/site-functions"
  chmod 755 "$BREW_PREFIX/share/zsh" "$BREW_PREFIX/share/zsh/site-functions"
  if [[ "$OS" == linux ]]; then
    mkdir -p "$HOME/.cache/Homebrew"
  else
    mkdir -p "$HOME/Library/Caches/Homebrew"
  fi

  # Homebrew itself is a git checkout of its newest release tag, on a branch named "stable".
  # On macOS the checkout is the prefix itself, which already has the dirs above in it,
  # so this uses init + fetch (like install.sh) rather than clone.
  mkdir -p "$BREW_REPO"
  if [[ ! -d "$BREW_REPO/.git" ]]; then
    git -C "$BREW_REPO" -c init.defaultBranch=main init --quiet
    git -C "$BREW_REPO" remote add origin "$BREW_GIT_URL"
  fi
  if [[ "$(git -C "$BREW_REPO" symbolic-ref --short -q HEAD || true)" != "stable" ]]; then
    git -C "$BREW_REPO" fetch --quiet --force --tags origin
    git -C "$BREW_REPO" checkout --quiet --force -B stable "$(latest_tag "$BREW_GIT_URL")"
  fi
  if [[ "$OS" == linux ]]; then
    ln -sfn ../Homebrew/bin/brew "$BREW"  # on macOS, bin/brew is already part of the checkout
  fi

  # Fetches the formula index (and brew's own portable Ruby)
  quietly "$BREW" update
fi
"$BREW" analytics off  # silent, and a no-op if already off

brew_install "${BREW_PACKAGES[@]}"
