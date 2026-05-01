#!/usr/bin/env bash
set -euo pipefail

# Claude Code CLI — native installer
# Docs: https://code.claude.com/docs/en/setup
#
# Installation via @anthropic-ai/claude-code on npm is deprecated.
# This feature uses the official curl | bash installer instead.

if command -v claude &>/dev/null; then
  echo "[INFO] Claude Code CLI already installed: $(claude --version)"
  exit 0
fi

echo "[INFO] Installing Claude Code CLI via native installer..."
curl -fsSL https://claude.ai/install.sh | bash

# The native installer may place the binary outside the calling shell's PATH
# (e.g. ~/.local/bin). Search known locations and symlink into /usr/local/bin
# when necessary so claude is available to all users.
if ! command -v claude &>/dev/null; then
  for candidate in \
    "/root/.local/bin/claude" \
    "/root/.anthropic/bin/claude" \
    "/usr/local/bin/claude"; do
    if [[ -x "$candidate" ]]; then
      ln -sf "$candidate" /usr/local/bin/claude
      break
    fi
  done
fi

if ! command -v claude &>/dev/null; then
  echo "[ERROR] Claude Code CLI not found in PATH after install." >&2
  exit 1
fi

claude --version
echo "[SUCCESS] Claude Code CLI installed."
