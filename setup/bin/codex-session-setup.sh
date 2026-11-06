#!/usr/bin/env bash
# Install/check the Herdr-only interactive Codex launcher for the official
# standalone CLI. Native executable and outside-Herdr behavior are preserved.
# Usage: bash setup/bin/codex-session-setup.sh [--check]
# Reapply after reinstalling/updating the Codex CLI if its installer replaces
# ~/.local/bin/codex. Unsupported/custom launchers fail without replacement.
set -euo pipefail
MATE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MATE_DEST="$HOME/.local/bin/codex"
MATE_NATIVE="$HOME/.codex/packages/standalone/current/bin/codex"
MATE_TEMPLATE="$MATE_ROOT/setup/bin/codex-console"
MATE_MARKER='# MateMate: keep interactive Codex sessions local to their Herdr pane.'
case "${1:-}" in
  --check)
    if [[ ! -x "$MATE_NATIVE" || ! -x "$MATE_DEST" ]] || ! cmp -s "$MATE_TEMPLATE" "$MATE_DEST"; then
      echo 'MateMate: Codex session launcher is missing or was replaced; reapply console setup.' >&2
      exit 1
    fi
    exit 0 ;;
  '') ;;
  *) echo 'Usage: codex-session-setup.sh [--check]' >&2; exit 2 ;;
esac
[[ -x "$MATE_NATIVE" ]] || { echo 'MateMate: official standalone Codex is required for the session launcher.' >&2; exit 1; }
if ! "$MATE_NATIVE" --help | grep -q -- '--no-daemon'; then
  echo 'MateMate: update Codex first; this CLI does not support --no-daemon.' >&2
  exit 1
fi
if [[ -L "$MATE_DEST" ]]; then
  [[ "$MATE_DEST" -ef "$MATE_NATIVE" ]] || { echo 'MateMate: unknown Codex symlink left unchanged.' >&2; exit 1; }
elif [[ -e "$MATE_DEST" ]]; then
  if [[ ! -f "$MATE_DEST" ]] || ! grep -Fqx "$MATE_MARKER" "$MATE_DEST"; then
    echo 'MateMate: custom Codex launcher left unchanged.' >&2
    exit 1
  fi
fi
mkdir -p "$HOME/.local/bin" "$HOME/.config/matemate"
if [[ -e "$MATE_DEST" || -L "$MATE_DEST" ]]; then
  cmp -s "$MATE_TEMPLATE" "$MATE_DEST" && exit 0
  cp -Pp "$MATE_DEST" "${MATE_DEST}.matemate-backup-$(date +%Y%m%d-%H%M%S)-$$"
fi
MATE_TEMP=$(mktemp "$HOME/.local/bin/.codex-matemate.XXXXXX")
trap 'rm -f "$MATE_TEMP"' EXIT
cp "$MATE_TEMPLATE" "$MATE_TEMP"
chmod 755 "$MATE_TEMP"
mv -f "$MATE_TEMP" "$MATE_DEST"
echo 'MateMate: interactive Codex inside Herdr now preserves per-pane session context.'
