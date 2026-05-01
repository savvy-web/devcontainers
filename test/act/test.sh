#!/usr/bin/env bash
set -euo pipefail

act --version || { echo "[FAIL] act not found in PATH" >&2; exit 1; }
act --version | grep "0.2.76" || { echo "[FAIL] act version mismatch" >&2; exit 1; }
echo "[PASS] act install test passed."
