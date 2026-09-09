#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
[[ -d "$MATE_HOME/.git" ]] || { echo "FirstMate missing: $MATE_HOME" >&2; exit 1; }
backup_copy "$MATE_ROOT/config/wezterm.lua" "$HOME/.wezterm.lua"
for item in backend crew-harness; do
  backup_copy "$MATE_ROOT/config/firstmate/$item" "$MATE_HOME/config/$item"
done
mkdir -p "$HOME/.local/bin" "$HOME/.pi/agent/extensions"
MATE_LINK="$HOME/.local/bin/matemate"
if [[ -e "$MATE_LINK" || -L "$MATE_LINK" ]]; then
  if [[ ! -L "$MATE_LINK" || "$(readlink "$MATE_LINK")" != "$MATE_ROOT/bin/matemate" ]]; then
    echo "Existing command left in place: $MATE_LINK" >&2
    exit 1
  fi
else
  ln -s "$MATE_ROOT/bin/matemate" "$MATE_LINK"
fi
herdr integration install pi
echo "MateMate configured. Launch: matemate"
