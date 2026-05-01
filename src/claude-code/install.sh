#!/usr/bin/env bash
set -euo pipefail

# Claude Code CLI — native installer
# Docs: https://code.claude.com/docs/en/setup
#
# The native installer writes files under $HOME (.local/bin, .anthropic/, etc.).
# Feature installs always run as root, so we use _REMOTE_USER (e.g. vscode) to
# run the installer as the devcontainer user — the same pattern used by the
# homebrew feature. This ensures the binary is owned by and accessible to the
# user that will be running claude at runtime.
# A symlink in /usr/local/bin makes `claude` available to all users on PATH.

REMOTE_USER="${_REMOTE_USER:-}"

# Use _REMOTE_USER when it's non-root and exists in the image; otherwise fall
# back to a system-wide shared prefix under /usr/local that is world-accessible.
if [[ -n "$REMOTE_USER" && "$REMOTE_USER" != "root" ]] && id -u "$REMOTE_USER" >/dev/null 2>&1; then
  INSTALL_USER="$REMOTE_USER"
  INSTALL_HOME=$(getent passwd "$INSTALL_USER" | cut -d: -f6)
else
  if [[ -n "$REMOTE_USER" && "$REMOTE_USER" != "root" ]]; then
    echo "[INFO] Remote user '${REMOTE_USER}' not found in image; installing to shared prefix."
  fi
  INSTALL_USER="root"
  INSTALL_HOME="/usr/local/lib/claude-code"
  mkdir -p "$INSTALL_HOME"
fi

CLAUDE_BIN="${INSTALL_HOME}/.local/bin/claude"

if [[ -x "$CLAUDE_BIN" ]]; then
  echo "[INFO] Claude Code CLI already installed at ${CLAUDE_BIN}."
  ln -sf "$CLAUDE_BIN" /usr/local/bin/claude 2>/dev/null || true
  exit 0
fi

echo "[INFO] Installing Claude Code CLI as user '${INSTALL_USER}'..."

if [[ "$INSTALL_USER" == "root" ]]; then
  HOME="$INSTALL_HOME" curl -fsSL https://claude.ai/install.sh | bash
  # Make all installed files world-readable/executable so non-root users can run claude.
  chmod -R a+rX "$INSTALL_HOME"
else
  su - "$INSTALL_USER" -s /bin/bash -c 'curl -fsSL https://claude.ai/install.sh | bash'
fi

if [[ ! -x "$CLAUDE_BIN" ]]; then
  echo "[ERROR] Claude Code binary not found at ${CLAUDE_BIN} after install." >&2
  exit 1
fi

ln -sf "$CLAUDE_BIN" /usr/local/bin/claude

if ! command -v claude &>/dev/null; then
  echo "[ERROR] Claude Code CLI not found in PATH after install." >&2
  exit 1
fi

claude --version
echo "[SUCCESS] Claude Code CLI installed."
