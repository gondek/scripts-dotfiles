#!/usr/bin/env bash
# general apt packages
source "$(dirname "$0")/utilities.sh"
only_on linux

APT_PACKAGES=(
  ack
  audacity
  bat
  curl
  ffmpeg
  file-roller
  fzf
  gcc
  gimp
  git
  gnome-disk-utility
  handbrake
  htop
  jq
  libreoffice
  silversearcher-ag
  software-properties-gtk
  sound-juicer
  tmux
  transmission
  vlc
  wget
  xclip
  xournal
)

apt_install "${APT_PACKAGES[@]}"
