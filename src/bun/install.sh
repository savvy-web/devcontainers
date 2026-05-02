#!/usr/bin/env bash
set -euo pipefail

# Bun Runtime installer
# Docs: https://bun.sh/docs/installation

# The devcontainer CLI injects feature options uppercased with no separator
# (e.g. bunVersion -> BUNVERSION). Accept both forms for flexibility.
BUN_VERSION="${BUNVERSION:-${BUN_VERSION:-1.3.13}}"
BUN_INSTALL_DIR="/usr/local/bun"

# Idempotency: skip if the correct version is already installed
if command -v bun >/dev/null 2>&1; then
  INSTALLED_VER=$(bun --version 2>/dev/null || true)
  if [[ -n "$INSTALLED_VER" && "$INSTALLED_VER" == "$BUN_VERSION" ]]; then
    echo "[INFO] Bun $BUN_VERSION already installed at $(command -v bun)"
    exit 0
  fi
fi

# Detect platform and architecture
UNAME=$(uname -s)
ARCH=$(uname -m)

if [[ "$UNAME" == "Linux" ]]; then
  PLATFORM="linux"
elif [[ "$UNAME" == "Darwin" ]]; then
  PLATFORM="darwin"
else
  echo "[ERROR] Unsupported OS: $UNAME" >&2
  exit 1
fi

if [[ "$ARCH" == "x86_64" ]]; then
  ARCH_SUFFIX="x64"
elif [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
  ARCH_SUFFIX="aarch64"
else
  echo "[ERROR] Unsupported architecture: $ARCH" >&2
  exit 1
fi

DOWNLOAD_URL="https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-${PLATFORM}-${ARCH_SUFFIX}.zip"

echo "[INFO] Downloading Bun $BUN_VERSION from $DOWNLOAD_URL"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

curl -fsSL "$DOWNLOAD_URL" -o "$TMPDIR/bun.zip"
unzip -q "$TMPDIR/bun.zip" -d "$TMPDIR/bun-extracted"

# Install to a fixed location and symlink into PATH
rm -rf "$BUN_INSTALL_DIR"
mkdir -p "$BUN_INSTALL_DIR"
cp "$TMPDIR/bun-extracted/bun-${PLATFORM}-${ARCH_SUFFIX}/bun" "$BUN_INSTALL_DIR/bun"
chmod +x "$BUN_INSTALL_DIR/bun"
ln -sf "$BUN_INSTALL_DIR/bun" /usr/local/bin/bun

# Validate install
if ! command -v bun &>/dev/null; then
  echo "[ERROR] bun not found in PATH after install." >&2
  exit 1
fi

bun --version

echo "[SUCCESS] Bun $BUN_VERSION installed at $BUN_INSTALL_DIR/bun"
