#!/usr/bin/env bash
set -euo pipefail

# Test: Biome global install
biome --version | grep "2.4.13" || { echo "[FAIL] Biome version mismatch" >&2; exit 1; }
echo "[PASS] Biome global install test passed."
