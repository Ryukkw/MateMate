#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
for tool in git gh jq curl node npm; do
  command -v "$tool" >/dev/null || { echo "Install prerequisite: $tool" >&2; exit 1; }
done
mkdir -p "$HOME/.local/bin"
npm config set prefix "$HOME/.local"
MATE_PACKAGES=()
while IFS= read -r package; do
  [[ -z "$package" ]] || MATE_PACKAGES+=("$package")
done < "$MATE_ROOT/setup/config/npm-packages.txt"
npm install -g --ignore-scripts "${MATE_PACKAGES[@]}"
# Current official binary installers. Re-run verify.sh after their releases change.
MATE_TEMP="$(mktemp -d)"
trap 'rm -rf "$MATE_TEMP"' EXIT
curl -fsSL https://herdr.dev/install.sh -o "$MATE_TEMP/herdr.sh"
curl -fsSL https://kunchenguid.github.io/treehouse/install.sh -o "$MATE_TEMP/treehouse.sh"
curl -fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh -o "$MATE_TEMP/no-mistakes.sh"
sh "$MATE_TEMP/herdr.sh"
sh "$MATE_TEMP/treehouse.sh"
sh "$MATE_TEMP/no-mistakes.sh"
bash "$MATE_ROOT/setup/bin/apply.sh"
gh-axi setup hooks
chrome-devtools-axi setup hooks
lavish-axi setup hooks
echo 'Add ~/.local/bin to PATH in your shell config if needed.'
bash "$MATE_ROOT/setup/bin/verify.sh"
