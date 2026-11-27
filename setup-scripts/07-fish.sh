#!/usr/bin/env bash
# fish as the default shell, plus fisher, plugins, and the font Tide's prompt needs
source "$(dirname "$0")/utilities.sh"

FISHER_GIT_URL=https://github.com/jorgebucaran/fisher
FISH_PLUGINS=(
  jorgebucaran/fisher
  IlanCosman/tide@v6
  jethrokuan/z
)
# Tide prompt settings, as `tide configure` would choose them interactively
TIDE_OPTIONS=(
  --style=Rainbow
  --prompt_colors='True color'
  --show_time='12-hour format'
  --rainbow_prompt_separators=Vertical
  --powerline_prompt_heads=Sharp
  --powerline_prompt_tails=Flat
  --powerline_prompt_style='Two lines, character'
  --prompt_connection=Dotted
  --powerline_right_prompt_frame=No
  --prompt_connection_andor_frame_color=Light
  --prompt_spacing=Sparse
  --icons='Few icons'
  --transient=No
)

# Tide's recommended font (MesloLGS NF), pinned to a commit of romkatv/powerlevel10k-media.
# Each file is checked against its SHA-256 before it's installed.
FONT_BASE_URL=https://raw.githubusercontent.com/romkatv/powerlevel10k-media/145eb9fbc2f42ee408dacd9b22d8e6e0e553f83d
FONTS=(
  "MesloLGS NF Regular.ttf d97946186e97f8d7c0139e8983abf40a1d2d086924f2c5dbf1c29bd8f2c6e57d"
  "MesloLGS NF Bold.ttf b6c0199cf7c7483c8343ea020658925e6de0aeb318b89908152fcb4d19226003"
  "MesloLGS NF Italic.ttf 6f357bcbe2597704e157a915625928bca38364a89c22a4ac36e7a116dcd392ef"
  "MesloLGS NF Bold Italic.ttf 56b4131adecec052c4b324efb818dd326d586dbc316fc68f98f1cae2eb8d1220"
)

if [[ "$OS" == linux ]]; then
  apt_install curl  # for the fonts below
  # an enabled PPA entry for this release (a release upgrade leaves the old one disabled)
  # grep without -q, so it reads the whole (long) output: -q stops at the first match, and
  # pipefail would count the SIGPIPE apt-cache then gets as "not found"
  if ! apt-cache policy | grep -F "fish-shell/release-4/ubuntu $UBUNTU_CODENAME/" >/dev/null; then
    say "Adding the fish 4 PPA"
    quietly sudo add-apt-repository -y ppa:fish-shell/release-4
  fi
  apt_install fish
  FISH_PATH=/usr/bin/fish
else
  brew_install fish
  FISH_PATH="$BREW_PREFIX/bin/fish"
fi

# chsh only accepts shells listed in /etc/shells (apt adds fish there; brew doesn't)
if ! grep -qxF "$FISH_PATH" /etc/shells; then
  say "Adding $FISH_PATH to /etc/shells"
  echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
fi
if [[ "$OS" == linux ]]; then
  CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
else
  CURRENT_SHELL="$(dscl . -read "/Users/$USER" UserShell | awk '{print $2}')"
fi
if [[ "$CURRENT_SHELL" != "$FISH_PATH" ]]; then
  say "Making fish the default shell"
  sudo chsh -s "$FISH_PATH" "$USER"
fi

# First run only: check out fisher's newest release and load it for one session,
# so fisher can install itself (as the first entry in FISH_PLUGINS) and manage its own updates.
FISHER_BOOTSTRAP=""
if ! fish -c 'functions -q fisher'; then
  say "Installing fisher"
  git -c advice.detachedHead=false clone --quiet --depth 1 \
    --branch "$(latest_tag "$FISHER_GIT_URL")" "$FISHER_GIT_URL" "$WORK_DIR/fisher"
  FISHER_BOOTSTRAP="$WORK_DIR/fisher/functions/fisher.fish"
fi
FISHER_BOOTSTRAP="$FISHER_BOOTSTRAP" INFO_COLOR="$INFO_COLOR" OUT_RESET="$OUT_RESET" fish -c '
  if test -n "$FISHER_BOOTSTRAP"
    source $FISHER_BOOTSTRAP
  end
  set -l installed (fisher list | string lower)
  for plugin in $argv
    if not contains -- (string lower $plugin) $installed
      printf "%s -> Installing fish plugin %s%s\n" "$INFO_COLOR" $plugin "$OUT_RESET"
      # keep fisher quiet, but show its output if it fails
      set -l output (fisher install $plugin 2>&1)
      or begin
        printf "%s\n" $output >&2
        exit 1
      end
    end
  end
' "${FISH_PLUGINS[@]}"

# Only when TIDE_OPTIONS changed since setup last applied them, so a re-run leaves the prompt
# alone. The record is a universal variable named so Tide's uninstall erases it with its own.
if [[ "$(fish -c 'string join \n -- $_tide_setup_options')" != "$(printf '%s\n' "${TIDE_OPTIONS[@]}")" ]]; then
  say "Configuring the Tide prompt"
  # --auto still clears the screen, so hide its output (errors still show)
  fish -c 'tide configure --auto $argv && set -U _tide_setup_options $argv' -- "${TIDE_OPTIONS[@]}" >/dev/null
fi

FONTS_ADDED=""
for entry in "${FONTS[@]}"; do
  name="${entry% *}"
  hash="${entry##* }"
  if [[ -f "$FONTS_DIR/$name" && "$(sha256_of "$FONTS_DIR/$name")" == "$hash" ]]; then
    continue
  fi
  say "Installing font $name"
  curl -fsSL -o "$WORK_DIR/$name" "$FONT_BASE_URL/${name// /%20}"
  if [[ "$(sha256_of "$WORK_DIR/$name")" != "$hash" ]]; then
    say_error "Checksum mismatch for $name; not installing it."
    exit 1
  fi
  mkdir -p "$FONTS_DIR"
  mv "$WORK_DIR/$name" "$FONTS_DIR/$name"
  FONTS_ADDED=1
done
if [[ -n "$FONTS_ADDED" && "$OS" == linux ]]; then
  fc-cache "$FONTS_DIR"  # make new fonts visible to newly started apps (macOS does this itself)
fi
if [[ -n "$FONTS_ADDED" ]]; then
  # apps already running (like this terminal) don't see new fonts until restarted;
  # xfce4-terminal runs all its windows in one process, so every window has to close
  say "Close every terminal window and reopen the terminal to use the new font."
fi
