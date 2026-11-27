#!/usr/bin/env bash
# Set up a fresh Xubuntu or macOS installation. Safe to re-run.
# Usage: ./setup.sh             run every stage in setup-scripts/ for this OS, in order
#        ./setup.sh fish xfce   run only the named stages (still in file order)
# Stages named *-linux.sh or *-macos.sh only run on that OS. sudo asks for the password
# when a stage first needs it.
cd "$(dirname "${BASH_SOURCE[0]}")"
source setup-scripts/utilities.sh

if [[ $EUID -eq 0 ]]; then
  say_error "Run this as a normal user, not root. sudo is used where needed."
  exit 1
fi

if [[ "$OS" == linux ]]; then
  OTHER_OS=macos
else
  OTHER_OS=linux
fi

# stage_name <file>: "setup-scripts/09-firewall-linux.sh" -> "firewall"
stage_name() {
  basename "$1" .sh | sed -E 's/^[0-9]+-//; s/-(linux|macos)$//'
}

STAGES=()
for stage in setup-scripts/[0-9]*-*.sh; do
  if [[ "$stage" != *-"$OTHER_OS".sh ]]; then
    STAGES+=("$stage")
  fi
done

if (($#)); then
  for name in "$@"; do
    found=""
    for stage in "${STAGES[@]}"; do
      if [[ "$(stage_name "$stage")" == "$name" ]]; then
        found=1
      fi
    done
    if [[ -z "$found" ]]; then
      say_error "Unknown stage: $name. Available stages on $OS:"
      for stage in "${STAGES[@]}"; do
        echo "  $(stage_name "$stage")" >&2
      done
      exit 1
    fi
  done
  # keep the named stages in file order (so dependencies run first), each once
  SELECTED=()
  for stage in "${STAGES[@]}"; do
    for name in "$@"; do
      if [[ "$(stage_name "$stage")" == "$name" ]]; then
        SELECTED+=("$stage")
        break
      fi
    done
  done
  STAGES=("${SELECTED[@]}")
fi

for stage in "${STAGES[@]}"; do
  say_stage "$(basename "$stage" .sh)"
  bash "$stage"
done

say_stage "Done. Remaining manual steps are in $PWD/README.md"
