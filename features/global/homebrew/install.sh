#!/usr/bin/env bash
set -euo pipefail

# Homebrew global install feature
# Installs Homebrew if not already present (macOS/Linux)
# Idempotent: skips install if brew is already available

BREW_PREFIX="/home/linuxbrew/.linuxbrew"
BREW_USER="linuxbrew"

if [[ -x "$BREW_PREFIX/bin/brew" ]]; then
  echo "[INFO] Homebrew is already installed at $BREW_PREFIX/bin/brew"
  exit 0
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
  echo "[INFO] Installing Homebrew for macOS..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "[INFO] Installing Homebrew for Linux..."
  if [[ $EUID -eq 0 ]]; then
    # Homebrew refuses to install as root; use a dedicated non-root user
    useradd -m -s /bin/bash "$BREW_USER" 2>/dev/null || true
    # shellcheck disable=SC2016
    su - "$BREW_USER" -s /bin/bash -c \
      'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  else
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  # Add brew to PATH for interactive shells
  echo "eval \"\$($BREW_PREFIX/bin/brew shellenv)\"" > /etc/profile.d/homebrew.sh
fi

if [[ ! -x "$BREW_PREFIX/bin/brew" ]]; then
  echo "[ERROR] Homebrew binary not found at $BREW_PREFIX/bin/brew after install." >&2
  exit 1
fi

echo "[SUCCESS] Homebrew installation complete."
