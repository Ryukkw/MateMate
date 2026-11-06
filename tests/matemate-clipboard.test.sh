#!/usr/bin/env bash
# Console clipboard regressions; no model prompts or system clipboard changes.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
command -v node >/dev/null || { echo 'skip: node is not installed'; exit 0; }
node --test "$ROOT/tests/matemate-clipboard.test.mjs"
