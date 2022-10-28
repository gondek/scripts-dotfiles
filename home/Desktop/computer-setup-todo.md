- Swtich Firefox from snap to deb
- Fish shell setup:
    - PPA: https://launchpad.net/~fish-shell/+archive/ubuntu/release-3
    - Tide prompt: https://github.com/IlanCosman/tide#installation
    - z directory jumping: https://github.com/jethrokuan/z
- XFCE Customizations:
    - `xfconf-query -c xsettings -p /Gtk/DialogsUseHeader -s false`
    - `open ~/.config/xfce4/terminal/accels.scm` and add:
        ```
        (gtk_accel_path "<Actions>/terminal-window/copy" "<Primary>c")
        (gtk_accel_path "<Actions>/terminal-window/paste" "<Primary>v")
        (gtk_accel_path "<Actions>/terminal-window/close-tab" "<Primary>w")
        (gtk_accel_path "<Actions>/terminal-window/new-tab" "<Primary>t")
        ```
- Printer Driver (Dell-1130 / Samsung ML-1915, 2.0.0 / Samsung ML-2525, 2.0.0)
- Activate firewall: `sudo ufw enable`
- Startup configuration:
    - "Software & Updates" > "Updates" > automatically check for updates
- Customization:
    - Add Wallpaper
    - Add picture and full name to profile
    - Configure XFCE Panel: Firefox, Places, Date (format `%I:%M %p - %A %B %d %Y`), Trash, Workspaces, Show-Desktop
- Browsers:
    - Install uBlock origin
