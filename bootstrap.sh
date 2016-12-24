#!/bin/bash
set -e
sudo apt-get update
sudo apt-get -y install build-essential libssl-dev libffi-dev python-dev git software-properties-common python-pip 
sudo pip install ansible
