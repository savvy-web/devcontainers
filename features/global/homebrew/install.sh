#!/usr/bin/env bash
set -euo pipefail

# Homebrew global install feature
# Installs Homebrew if not already present (macOS/Linux)
# Idempotent: skips install if brew is already available

BREW_PREFIX="/home/linuxbrew/.linuxbrew"

if command -v brew >/dev/null 2>&1; then
  echo "[INFO] Homebrew is already installed at $(command -v brew)"
  exit 0
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
  echo "[INFO] Installing Homebrew for macOS..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "[INFO] Installing Homebrew for Linux..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for Linux
  if ! grep -q "$BREW_PREFIX/bin" <<< "$PATH"; then
    echo "[INFO] Adding Homebrew to PATH..."
    echo 'eval "$($BREW_PREFIX/bin/brew shellenv)"' >> /etc/profile.d/homebrew.sh
    eval "$($BREW_PREFIX/bin/brew shellenv)"
  fi
fi

echo "[INFO] Homebrew installation complete."
