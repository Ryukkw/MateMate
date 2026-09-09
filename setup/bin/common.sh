#!/usr/bin/env bash
# MateMate's checkout is both the code root and the default operational home.
set -euo pipefail
MATE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PATH="$HOME/.local/bin:$PATH"
MATE_HOME="$MATE_ROOT"
backup_copy() {
  local source=$1 destination=$2
  mkdir -p "$(dirname "$destination")"
  if [[ -e "$destination" || -L "$destination" ]]; then
    cmp -s "$source" "$destination" && return 0
    cp -p "$destination" "${destination}.matemate-backup-$(date +%Y%m%d-%H%M%S)-$$"
  fi
  cp "$source" "$destination"
}
