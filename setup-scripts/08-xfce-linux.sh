#!/usr/bin/env bash
# XFCE settings and terminal shortcuts
source "$(dirname "$0")/utilities.sh"
only_on linux

apt_install xfce4-screenshooter  # for the screenshot shortcut below (Xubuntu usually has it)

TERMINAL_FONT="MesloLGS NF"  # Tide's recommended font, installed by the fish stage

# xfconf settings need a running XFCE session; without one they're left for a later run
if command -v xfconf-query >/dev/null && [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
  if [[ "$(xfconf-query -c xsettings -p /Gtk/DialogsUseHeader 2>/dev/null || true)" != "false" ]]; then
    say "Turning off header bars in dialogs"
    xfconf-query -c xsettings -p /Gtk/DialogsUseHeader -n -t bool -s false
  fi

  # terminal font, at the size the terminal already uses
  CURRENT_FONT="$(xfconf-query -c xfce4-terminal -p /font-name 2>/dev/null || true)"
  USE_SYSTEM_FONT="$(xfconf-query -c xfce4-terminal -p /font-use-system 2>/dev/null || true)"
  if [[ "$CURRENT_FONT" != "$TERMINAL_FONT "* || "$USE_SYSTEM_FONT" == "true" ]]; then
    SIZE="${CURRENT_FONT##* }"
    if [[ ! "$SIZE" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
      SIZE=11
    fi
    say "Setting the terminal font to $TERMINAL_FONT $SIZE"
    xfconf-query -c xfce4-terminal -p /font-name -n -t string -s "$TERMINAL_FONT $SIZE"
    xfconf-query -c xfce4-terminal -p /font-use-system -n -t bool -s false
  fi

  # Ctrl+Shift+4: select a region and copy it straight to the clipboard, like macOS's
  # Ctrl+Cmd+Shift+4. XFCE names the key after its shifted symbol ($ on a US layout).
  SCREENSHOT_KEY='/commands/custom/<Primary><Shift>dollar'
  SCREENSHOT_COMMAND='xfce4-screenshooter -r -c'
  if [[ "$(xfconf-query -c xfce4-keyboard-shortcuts -p "$SCREENSHOT_KEY" 2>/dev/null || true)" != "$SCREENSHOT_COMMAND" ]]; then
    say "Setting screenshot shortcut: Ctrl+Shift+4 = select a region, copy to the clipboard"
    xfconf-query -c xfce4-keyboard-shortcuts -p "$SCREENSHOT_KEY" -n -t string -s "$SCREENSHOT_COMMAND"
  fi
fi

# terminal shortcuts
ACCELS="$HOME/.config/xfce4/terminal/accels.scm"
mkdir -p "$(dirname "$ACCELS")"
if [[ ! -e "$ACCELS" ]]; then
  : > "$ACCELS"
fi
ACCELS_CHANGED=""
set_accel() {  # set_accel <action> <key>: replace any existing binding for the action
  local action="$1" line="(gtk_accel_path \"<Actions>/terminal-window/$1\" \"$2\")"
  if ! grep -qxF "$line" "$ACCELS"; then
    say "Setting terminal shortcut: $action = $2"
    sed -i "\|^(gtk_accel_path \"<Actions>/terminal-window/$action\"|d" "$ACCELS"
    echo "$line" >> "$ACCELS"
    ACCELS_CHANGED=1
  fi
}
set_accel close-tab '<Primary>w'
set_accel new-tab '<Primary>t'
set_accel paste '<Primary>v'  # copy stays Ctrl+Shift+C, so Ctrl+C still interrupts
if [[ -n "$ACCELS_CHANGED" ]]; then
  # xfce4-terminal runs all its windows in one process, and reads shortcuts when it starts
  say "Close every terminal window and reopen the terminal to use the new shortcuts."
fi
