#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=setup/bin/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
for tool in git gh jq curl node npm pi herdr treehouse no-mistakes gh-axi chrome-devtools-axi lavish-axi tasks-axi quota-axi; do
  command -v "$tool"
done
pi --version
herdr --version
treehouse --version
no-mistakes --version
herdr status --json | jq -e '.client | {version, protocol} | select(.protocol >= 14)'
herdr integration status
test -s "$HOME/.pi/agent/extensions/herdr-agent-state.ts"
test -s "$HOME/.codex/herdr-agent-state.sh"
gh auth status
for item in backend crew-harness; do
  cmp "$MATE_ROOT/setup/config/firstmate/$item" "$MATE_HOME/config/$item"
done
FM_HOME="$MATE_HOME" FM_BOOTSTRAP_DETECT_ONLY=1 FM_BOOTSTRAP_NETWORK=skip \
  bash "$MATE_HOME/bin/fm-bootstrap.sh"
echo 'Basic checks completed. Read any bootstrap diagnostics above; it can report problems with exit code 0.'
