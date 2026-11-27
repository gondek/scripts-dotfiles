# Shared settings for the setup stages. Each stage sources this; it isn't run directly.
# Keep this and the stages compatible with bash 3.2, which is macOS's /bin/bash.
set -euo pipefail
umask 022  # files and dirs created here are writable only by their owner

# Output from these scripts (as opposed to the commands they run) goes through these helpers,
# so it stands out: a prefix always, plus color when writing to a terminal (unless NO_COLOR is set).
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  STAGE_COLOR=$'\033[1;34m' INFO_COLOR=$'\033[36m' OUT_RESET=$'\033[0m'
else
  STAGE_COLOR="" INFO_COLOR="" OUT_RESET=""
fi
if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then
  ERROR_COLOR=$'\033[1;31m' ERR_RESET=$'\033[0m'
else
  ERROR_COLOR="" ERR_RESET=""
fi
say_stage() { printf '%s==> %s%s\n' "$STAGE_COLOR" "$*" "$OUT_RESET"; }
say() { printf '%s -> %s%s\n' "$INFO_COLOR" "$*" "$OUT_RESET"; }
say_error() { printf '%s !! %s%s\n' "$ERROR_COLOR" "$*" "$ERR_RESET" >&2; }

# OS
case "$(uname -s)" in
  Linux) OS=linux ;;
  Darwin) OS=macos ;;
  *)
    say_error "Unsupported OS: $(uname -s)"
    exit 1
    ;;
esac

# only_on <linux|macos>: end this stage early (successfully) on any other OS
only_on() {
  if [[ "$OS" != "$1" ]]; then
    say "Skipping $(basename "$0") ($1 only)"
    exit 0
  fi
}

# require_terminal <what>: stop unless there's a terminal to answer prompts on
require_terminal() {
  if [[ ! -t 0 ]]; then
    say_error "$1 needs a terminal to answer prompts. Run it from a terminal (over ssh, use ssh -t)."
    exit 1
  fi
}

# Scratch space, deleted when the script exits, including on Ctrl+C
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Paths
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SSH_KEY="$HOME/.ssh/id_ed25519"
if [[ "$OS" == linux ]]; then
  BREW_PREFIX=/home/linuxbrew/.linuxbrew
  BREW_REPO="$BREW_PREFIX/Homebrew"
  APT_KEYRINGS=/etc/apt/keyrings
  FONTS_DIR="$HOME/.local/share/fonts"
else
  BREW_PREFIX=/opt/homebrew  # Apple Silicon
  BREW_REPO="$BREW_PREFIX"
  FONTS_DIR="$HOME/Library/Fonts"
fi
BREW="$BREW_PREFIX/bin/brew"

# System info
USER="${USER:-$(id -un)}"
MACHINE_NAME="$USER@$(hostname)"  # labels this machine's SSH key, locally and on GitHub
if [[ "$OS" == linux ]]; then
  ARCH="$(dpkg --print-architecture)"
  UBUNTU_CODENAME="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")"
fi

# Brew-installed tools (like gh) go last on PATH, matching config.fish
case ":$PATH:" in
  *":$BREW_PREFIX/bin:"*) ;;
  *) PATH="$PATH:$BREW_PREFIX/bin:$BREW_PREFIX/sbin" ;;
esac
# Keep Homebrew from sending analytics during setup (the brew stage also turns them off for good)
export HOMEBREW_NO_ANALYTICS=1

# sha256_of <file>: the file's SHA-256 hash (sha256sum on Linux, shasum on macOS)
sha256_of() {
  if command -v sha256sum >/dev/null; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

# latest_tag <git url>: the newest release tag of a remote git repo, by version order
latest_tag() {
  git ls-remote --tags --refs --sort=-version:refname "$1" | sed -n '1s|.*refs/tags/||p'
}

# quietly <command>...: run a command with its output hidden, and show that output only if it
# fails. Not for commands that ask questions: their prompts would be hidden too.
quietly() {
  local log status=0
  log="$(mktemp "$WORK_DIR/quietly.XXXXXX")"
  "$@" >"$log" 2>&1 || status=$?
  if ((status != 0)); then
    cat "$log" >&2
    say_error "Failed (exit $status): $*"
  fi
  rm -f "$log"
  return "$status"
}

# apt_get <arguments>...: apt-get, quietly and without questions. With output hidden, nothing
# may stop to ask: debconf takes its defaults, locally changed config files are kept, and it
# waits up to a minute for another apt run (like automatic updates) to let go of the lock.
apt_get() {
  quietly sudo env DEBIAN_FRONTEND=noninteractive apt-get -y \
    -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold \
    -o DPkg::Lock::Timeout=60 "$@"
}

# is_apt_installed <package>: whether an apt package is installed
is_apt_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'ok installed'
}

# apt_install <package>...: install the given apt packages that aren't installed yet
apt_install() {
  local missing=() pkg
  for pkg in "$@"; do
    if ! is_apt_installed "$pkg"; then
      missing+=("$pkg")
    fi
  done
  if ((${#missing[@]})); then
    say "Installing apt packages: ${missing[*]}"
    apt_get update
    apt_get install "${missing[@]}"
  fi
}

# brew_install <formula>...: install the given brew formulae that aren't installed yet
brew_install() {
  local missing=() pkg
  for pkg in "$@"; do
    if ! "$BREW" list --versions "$pkg" >/dev/null 2>&1; then
      missing+=("$pkg")
    fi
  done
  if ((${#missing[@]})); then
    say "Installing brew packages: ${missing[*]}"
    quietly "$BREW" install "${missing[@]}"
  fi
}
