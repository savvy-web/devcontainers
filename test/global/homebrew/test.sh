#!/usr/bin/env bash
set -euo pipefail

# Test: Homebrew global feature

if ! command -v brew >/dev/null 2>&1; then
  echo "[FAIL] brew not found after install"
  exit 1
fi

brew --version | grep Homebrew && echo "[PASS] Homebrew installed and working"
