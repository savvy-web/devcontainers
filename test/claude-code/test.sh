#!/usr/bin/env bash
set -euo pipefail

# Test Claude Code global feature

if ! command -v claude &>/dev/null; then
  echo "[FAIL] claude CLI not found in PATH"
  exit 1
fi

claude --version

echo "[PASS] Claude Code install test passed."
