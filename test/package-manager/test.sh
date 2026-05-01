#!/usr/bin/env bash
set -euo pipefail

# Test: Package Manager (corepack) feature

if ! command -v corepack &>/dev/null; then
  echo "[FAIL] corepack not found in PATH" >&2
  exit 1
fi

# Default option is "auto" which may not resolve a spec in the test
# environment (no package.json), so it only enables corepack shims.
# Verify corepack itself is functional.
corepack --version || { echo "[FAIL] corepack not functional" >&2; exit 1; }

echo "[PASS] Package Manager (corepack) feature test passed."
