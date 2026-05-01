#!/usr/bin/env bash
set -euo pipefail

# Test Node.js + pnpm feature

if ! command -v pnpm &>/dev/null; then
  echo "[FAIL] pnpm not found in PATH" >&2
  exit 1
fi

node --version | grep "24.11.0" || { echo "[FAIL] Node.js version mismatch" >&2; exit 1; }
pnpm --version | grep "10.20.0" || { echo "[FAIL] pnpm version mismatch" >&2; exit 1; }

echo "[PASS] Node.js + pnpm install test passed."
