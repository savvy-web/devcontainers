#!/usr/bin/env bash
set -euo pipefail

# Test: Homebrew global feature
# Homebrew refuses to run as root; verify via the install user

BREW_PREFIX="/home/linuxbrew/.linuxbrew"

if [[ ! -x "$BREW_PREFIX/bin/brew" ]]; then
  echo "[FAIL] brew binary not found at $BREW_PREFIX/bin/brew" >&2
  exit 1
fi

# Mirror the install.sh user selection: prefer _REMOTE_USER when set and
# non-root, otherwise fall back to the dedicated linuxbrew account.
BREW_USER="${_REMOTE_USER:-}"
if [[ -z "$BREW_USER" || "$BREW_USER" == "root" ]]; then
  BREW_USER="linuxbrew"
fi

# Run brew as the install user (brew refuses to run as root)
su - "$BREW_USER" -s /bin/bash -c "$BREW_PREFIX/bin/brew --version" \
  | grep Homebrew \
  || { echo "[FAIL] brew --version did not output expected Homebrew version string" >&2; exit 1; }

echo "[PASS] Homebrew installed and working."
