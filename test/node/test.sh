#!/usr/bin/env bash
set -euo pipefail

# Test: Node.js global install
if ! command -v node &>/dev/null; then
  echo "[FAIL] node not found in PATH" >&2
  exit 1
fi

if ! command -v npm &>/dev/null; then
  echo "[FAIL] npm not found in PATH" >&2
  exit 1
fi

if ! command -v npx &>/dev/null; then
  echo "[FAIL] npx not found in PATH" >&2
  exit 1
fi

if ! command -v corepack &>/dev/null; then
  echo "[FAIL] corepack not found in PATH" >&2
  exit 1
fi

# Pinned default version from devcontainer-feature.json
ACTUAL_VERSION="$(node -v)"
if [[ "$ACTUAL_VERSION" != "v24.11.0" ]]; then
  echo "[FAIL] Node.js version mismatch: expected v24.11.0, got $ACTUAL_VERSION" >&2
  exit 1
fi

echo "[PASS] Node.js global install test passed."
