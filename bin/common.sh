#!/usr/bin/env bash
# Shared paths. An existing installation keeps its session and state in place.
set -euo pipefail
MATE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.local/bin:$PATH"
if [[ -n "${MATEMATE_HOME:-}" ]]; then
  MATE_HOME="$MATEMATE_HOME"
elif [[ -d "$HOME/kun-agent-workspace/.git" ]]; then
  MATE_HOME="$HOME/kun-agent-workspace"
else
  MATE_HOME="$HOME/.local/share/matemate/firstmate"
fi
backup_copy() {
  local source=$1 destination=$2
  mkdir -p "$(dirname "$destination")"
  if [[ -e "$destination" || -L "$destination" ]]; then
    cmp -s "$source" "$destination" && return 0
    cp -p "$destination" "${destination}.matemate-backup-$(date +%Y%m%d-%H%M%S)-$$"
  fi
  cp "$source" "$destination"
}
