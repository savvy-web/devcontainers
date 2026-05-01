#!/usr/bin/env bash
set -euo pipefail

# Claude Code CLI global installer (official npm package)
# Docs: https://docs.anthropic.com/en/docs/claude-code/getting-started

VERSION="${VERSION:-latest}"

if [[ "$VERSION" == "latest" ]]; then
  npm install -g @anthropic-ai/claude-code
else
  npm install -g "@anthropic-ai/claude-code@${VERSION}"
fi

# Validate install
if ! command -v claude &>/dev/null; then
  echo "[ERROR] Claude Code CLI not found in PATH after install." >&2
  exit 1
fi

# Print version
claude --version
echo "[SUCCESS] Claude Code CLI installed."
