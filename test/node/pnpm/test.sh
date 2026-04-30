#!/usr/bin/env bash
set -euo pipefail

# Test Node.js + pnpm feature

if ! command -v pnpm &>/dev/null; then
  echo "[FAIL] pnpm not found in PATH"
  exit 1
fi

pnpm --version
