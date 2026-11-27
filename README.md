# scripts / configuration

Scripts and dotfiles for setting up a computer.

Supports both Xubuntu (my usual personal OS), and Apple Silicon macOS (my work machines).

## Usage

1. Get git:
   - Xubuntu: `sudo apt install -y git`
   - macOS: `xcode-select --install`
2. `git clone https://github.com/gondek/scripts-dotfiles.git`
3. Run `./setup.sh` from the repo as a normal (non-root) user.
4. Do the [manual steps](#manual-steps) below

## Manual steps

- Log out and back in (fish becomes the login shell, and docker works without sudo)
- macOS: set the terminal's font to `MesloLGS NF` (setup installs it; on Xubuntu it also sets it in xfce4-terminal)
- Add picture and full name to profile
- Xubuntu:
    - Verify automatic updates are enabled
    - Configure XFCE Panel: Firefox, Places, Date (format `%I:%M %p - %A %B %d %Y`), Trash, Workspaces, Show-Desktop
