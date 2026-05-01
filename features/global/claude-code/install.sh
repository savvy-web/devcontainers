#!/usr/bin/env bash
set -euo pipefail

# Claude Code CLI global installer (official native method)
# Docs: https://code.claude.com/docs/en/overview

VERSION="${VERSION:-latest}"

if [[ "$VERSION" == "latest" ]]; then
  INSTALL_SCRIPT_URL="https://code.claude.com/install.sh"
else
  INSTALL_SCRIPT_URL="https://code.claude.com/install.sh?version=$VERSION"
fi

# Download and run the official installer
curl -fsSL "$INSTALL_SCRIPT_URL" | bash

# Validate install
if ! command -v claude &>/dev/null; then
  echo "[ERROR] Claude Code CLI not found in PATH after install." >&2
  exit 1
fi

# Print version
claude --version
