#!/usr/bin/env bash
set -euo pipefail
# Test: Rust toolchain install
rustc --version || { echo "[FAIL] rustc not found" >&2; exit 1; }
cargo --version || { echo "[FAIL] cargo not found" >&2; exit 1; }
echo "[PASS] Rust toolchain install test passed."
