#!/usr/bin/env bash
set -euo pipefail

# Test: Zig compiler install
zig version | grep "0.12.0" || { echo "[FAIL] Zig version mismatch" >&2; exit 1; }

echo "[PASS] Zig install test passed."
