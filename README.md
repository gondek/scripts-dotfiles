# scripts / configuration

Scripts for computer setup and task automation.

`setup.yml` is an [Ansible](http://www.ansible.com/home) playbook. To run:

1. Install Ansible (run `./bootstrap.sh`)
2. Run `ansible-playbook setup.yml -i "localhost," --ask-become-pass`
