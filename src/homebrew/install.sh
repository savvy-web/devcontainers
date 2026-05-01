#!/usr/bin/env bash
set -euo pipefail

# Homebrew global install feature
# Installs Homebrew if not already present (macOS/Linux)
# Idempotent: skips install if brew is already available

OS=$(uname -s)
ARCH=$(uname -m)

# Determine the Homebrew prefix based on OS and architecture
if [[ "$OS" == "Darwin" ]]; then
  if [[ "$ARCH" == "arm64" ]]; then
    BREW_PREFIX="/opt/homebrew"
  else
    BREW_PREFIX="/usr/local"
  fi
else
  BREW_PREFIX="/home/linuxbrew/.linuxbrew"
fi

if [[ -x "$BREW_PREFIX/bin/brew" ]]; then
  echo "[INFO] Homebrew is already installed at $BREW_PREFIX/bin/brew"
  # Ensure profile.d entry is present even on idempotent runs
  if [[ "$OS" != "Darwin" ]] && [[ ! -f /etc/profile.d/homebrew.sh ]]; then
    echo "eval \"\$($BREW_PREFIX/bin/brew shellenv)\"" > /etc/profile.d/homebrew.sh
  fi
  exit 0
fi

if [[ "$OS" == "Darwin" ]]; then
  echo "[INFO] Installing Homebrew for macOS..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  # Homebrew on Linux must run as a non-root user and installs to
  # /home/linuxbrew/.linuxbrew. Prefer _REMOTE_USER when set and non-root
  # so the devcontainer user owns the Homebrew prefix and can run
  # `brew install` directly without switching users.
  REMOTE_USER="${_REMOTE_USER:-}"
  if [[ -n "$REMOTE_USER" && "$REMOTE_USER" != "root" ]] && id -u "$REMOTE_USER" >/dev/null 2>&1; then
    BREW_USER="$REMOTE_USER"
  else
    if [[ -n "$REMOTE_USER" && "$REMOTE_USER" != "root" ]]; then
      echo "[INFO] Remote user '${REMOTE_USER}' does not exist in the image; falling back to linuxbrew user." >&2
    fi
    BREW_USER="linuxbrew"
    useradd -m -s /bin/bash "$BREW_USER" 2>/dev/null || true
  fi

  echo "[INFO] Installing Homebrew for Linux as user '${BREW_USER}'..."
  # Ensure /home/linuxbrew exists and is owned by the install user so the
  # Homebrew installer can create the .linuxbrew prefix there regardless of
  # which user is performing the install.
  mkdir -p /home/linuxbrew
  chown "$BREW_USER:" /home/linuxbrew

  # shellcheck disable=SC2016
  su - "$BREW_USER" -s /bin/bash -c \
    'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'

  # Add brew to PATH for interactive shells
  echo "eval \"\$($BREW_PREFIX/bin/brew shellenv)\"" > /etc/profile.d/homebrew.sh
fi

if [[ ! -x "$BREW_PREFIX/bin/brew" ]]; then
  echo "[ERROR] Homebrew binary not found at $BREW_PREFIX/bin/brew after install." >&2
  exit 1
fi

echo "[SUCCESS] Homebrew installation complete."
