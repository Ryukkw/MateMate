#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=setup/bin/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
[[ -f "$MATE_HOME/AGENTS.md" ]] || { echo "MateMate missing: $MATE_HOME" >&2; exit 1; }
backup_copy "$MATE_ROOT/setup/config/wezterm.lua" "$HOME/.wezterm.lua"
backup_copy "$MATE_ROOT/setup/config/terminal-colors.sh" "$HOME/.config/matemate/terminal-colors.sh"
case "${SHELL:-/bin/zsh}" in
  */bash) MATE_SHELL_RC="$HOME/.bashrc" ;;
  *) MATE_SHELL_RC="$HOME/.zshrc" ;;
esac
# Expanded when the generated shell startup line is executed.
# shellcheck disable=SC2016
MATE_COLOR_SOURCE='[ ! -f "$HOME/.config/matemate/terminal-colors.sh" ] || . "$HOME/.config/matemate/terminal-colors.sh"'
if ! grep -Fqx "$MATE_COLOR_SOURCE" "$MATE_SHELL_RC" 2>/dev/null; then
  if [[ -e "$MATE_SHELL_RC" ]]; then
    cp -p "$MATE_SHELL_RC" "${MATE_SHELL_RC}.matemate-backup-$(date +%Y%m%d-%H%M%S)-$$"
  fi
  printf '\n# MateMate: colors in interactive WezTerm / Herdr shells\n%s\n' "$MATE_COLOR_SOURCE" >> "$MATE_SHELL_RC"
fi
for item in backend crew-harness; do
  backup_copy "$MATE_ROOT/setup/config/firstmate/$item" "$MATE_HOME/config/$item"
done
mkdir -p "$HOME/.local/bin" "$HOME/.pi/agent/extensions"
MATE_LINK="$HOME/.local/bin/matemate"
if [[ -e "$MATE_LINK" || -L "$MATE_LINK" ]]; then
  if [[ -L "$MATE_LINK" && "$(readlink "$MATE_LINK")" = "$MATE_ROOT/bin/matemate" ]]; then
    ln -sfn "$MATE_ROOT/setup/bin/matemate" "$MATE_LINK"
  elif [[ ! -L "$MATE_LINK" || "$(readlink "$MATE_LINK")" != "$MATE_ROOT/setup/bin/matemate" ]]; then
    echo "Existing command left in place: $MATE_LINK" >&2
    exit 1
  fi
else
  ln -s "$MATE_ROOT/setup/bin/matemate" "$MATE_LINK"
fi
herdr integration install pi
herdr integration install codex
if command -v codex >/dev/null 2>&1; then
  bash "$MATE_ROOT/setup/bin/codex-session-setup.sh"
fi
npm ci --prefix "$MATE_ROOT/setup/plugins/clipboard" --ignore-scripts --no-audit --no-fund
herdr plugin link "$MATE_ROOT/setup/plugins/clipboard" --enabled
node "$MATE_ROOT/setup/plugins/clipboard/configure.mjs"
herdr config check
echo "MateMate configured. Launch: matemate"
