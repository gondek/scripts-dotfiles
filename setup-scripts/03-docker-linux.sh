#!/usr/bin/env bash
# Docker Engine, Compose, and Buildx from Docker's apt repo
# Used instead of Ubuntu's `docker.io` package, as that lags behind quite a bit
source "$(dirname "$0")/utilities.sh"
only_on linux

# Ubuntu's own packages conflict with Docker's
CONFLICTING=(docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc)
DOCKER_PACKAGES=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)

apt_install curl jq  # used below

KEY="$APT_KEYRINGS/docker.asc"
SOURCES=/etc/apt/sources.list.d/docker.sources
SOURCES_CONTENT="Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $UBUNTU_CODENAME
Components: stable
Architectures: $ARCH
Signed-By: $KEY"
if [[ ! -s "$KEY" || "$(cat "$SOURCES" 2>/dev/null)" != "$SOURCES_CONTENT" ]]; then
  say "Adding Docker's apt repo"
  # download as the normal user; only installing the file needs root
  curl -fsSL -o "$WORK_DIR/docker.asc" https://download.docker.com/linux/ubuntu/gpg
  sudo install -d -m 755 "$APT_KEYRINGS"
  sudo install -m 644 "$WORK_DIR/docker.asc" "$KEY"
  echo "$SOURCES_CONTENT" | sudo tee "$SOURCES" >/dev/null
fi

INSTALLED=()
for pkg in "${CONFLICTING[@]}"; do
  if is_apt_installed "$pkg"; then
    INSTALLED+=("$pkg")
  fi
done
if ((${#INSTALLED[@]})); then
  say "Removing conflicting Ubuntu packages: ${INSTALLED[*]}"
  apt_get remove "${INSTALLED[@]}"
fi

apt_install "${DOCKER_PACKAGES[@]}"

# Docker's published ports (`-p 8080:80`) bypass ufw. Default them to localhost only, so
# containers aren't reachable from the network unless asked for (`-p 0.0.0.0:8080:80`).
# (read without sudo: this script installs the file world-readable; if it isn't, it gets rewritten)
DAEMON_JSON=/etc/docker/daemon.json
if [[ "$(jq -r '.ip // empty' "$DAEMON_JSON" 2>/dev/null || true)" != "127.0.0.1" ]]; then
  say "Making Docker's published ports local-only by default (127.0.0.1)"
  if sudo test -f "$DAEMON_JSON"; then
    sudo cat "$DAEMON_JSON" > "$WORK_DIR/daemon.json"
  else
    echo '{}' > "$WORK_DIR/daemon.json"
  fi
  jq '.ip = "127.0.0.1"' "$WORK_DIR/daemon.json" > "$WORK_DIR/daemon.json.new"
  sudo install -d -m 755 /etc/docker
  sudo install -m 644 "$WORK_DIR/daemon.json.new" "$DAEMON_JSON"
  quietly sudo systemctl restart docker
fi

if ! id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
  say "Adding $USER to the docker group"
  sudo usermod -aG docker "$USER"
  say "Log out and back in to use docker without sudo."
fi
