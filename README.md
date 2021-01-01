# scripts / configuration

Scripts for computer setup and task automation.

I currently use Debian as my main OS. To finish setting up a fresh installation:
1. Add self to sudo:
    1. `su -`
    2. `usermod -aG sudo USERNAME`
2. `sudo apt install -y ansible git smbclient gvfs-backends`
3. Install SSH and GPG keys
4. `git clone git@github.com:gondek/scripts-dotfiles.git`
5. Run `ansible-playbook setup.yml -i "localhost," --ask-become-pass` 
