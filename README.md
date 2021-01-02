# scripts / configuration

Scripts for computer setup and task automation.

I currently use Xubuntu as my main OS. To finish setting up a fresh installation:
1. `sudo apt install -y ansible git`
2. Install SSH and GPG keys
3. `git clone git@github.com:gondek/scripts-dotfiles.git`
4. Run `ansible-playbook setup.yml -i "localhost," --ask-become-pass` 
