#!/usr/bin/env bash
# ufw with its default policy (deny incoming, allow outgoing)
source "$(dirname "$0")/utilities.sh"
only_on linux

apt_install ufw
# Transmission's peer port, so other peers can connect and seeding works.
# `ufw show added` lists rules whether or not the firewall is on yet.
if ! sudo ufw show added | grep -qF 'ufw allow 51413'; then
  say "Allowing Transmission's peer port (51413) through the firewall"
  sudo ufw allow 51413 comment 'Transmission peer port'
fi
if ! sudo ufw status | grep -q '^Status: active'; then
  say "Enabling firewall"
  sudo ufw enable  # not quietly: over SSH it asks for confirmation, on stdout
fi
