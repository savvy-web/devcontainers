#!/usr/bin/env bash
set -euo pipefail

# Test: Homebrew global feature
# Homebrew refuses to run as root; verify via the linuxbrew user

BREW_PREFIX="/home/linuxbrew/.linuxbrew"

if [[ ! -x "$BREW_PREFIX/bin/brew" ]]; then
  echo "[FAIL] brew binary not found at $BREW_PREFIX/bin/brew" >&2
  exit 1
fi

# Run brew as the linuxbrew user (brew refuses to run as root)
su - linuxbrew -s /bin/bash -c "$BREW_PREFIX/bin/brew --version" \
  | grep Homebrew \
  || { echo "[FAIL] brew --version did not output expected Homebrew version string" >&2; exit 1; }

echo "[PASS] Homebrew installed and working."
