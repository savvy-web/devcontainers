#!/usr/bin/env bash
set -euo pipefail

# Deno Runtime installer
# Docs: https://docs.deno.com/runtime/getting_started/installation/

# The devcontainer CLI injects feature options uppercased with no separator
# (e.g. denoVersion -> DENOVERSION). Accept both forms for flexibility.
DENO_VERSION="${DENOVERSION:-${DENO_VERSION:-2.7.14}}"
DENO_INSTALL_DIR="/usr/local/deno"

# Idempotency: skip if the correct version is already installed
if command -v deno >/dev/null 2>&1; then
  INSTALLED_VER=$(deno --version 2>/dev/null | awk 'NR==1{print $2}' || true)
  if [[ -n "$INSTALLED_VER" && "$INSTALLED_VER" == "$DENO_VERSION" ]]; then
    echo "[INFO] Deno $DENO_VERSION already installed at $(command -v deno)"
    exit 0
  fi
fi

# Detect platform and architecture
UNAME=$(uname -s)
ARCH=$(uname -m)

if [[ "$UNAME" == "Linux" ]]; then
  PLATFORM="unknown-linux-gnu"
elif [[ "$UNAME" == "Darwin" ]]; then
  PLATFORM="apple-darwin"
else
  echo "[ERROR] Unsupported OS: $UNAME" >&2
  exit 1
fi

if [[ "$ARCH" == "x86_64" ]]; then
  ARCH_PREFIX="x86_64"
elif [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
  ARCH_PREFIX="aarch64"
else
  echo "[ERROR] Unsupported architecture: $ARCH" >&2
  exit 1
fi

DOWNLOAD_URL="https://github.com/denoland/deno/releases/download/v${DENO_VERSION}/deno-${ARCH_PREFIX}-${PLATFORM}.zip"

echo "[INFO] Downloading Deno $DENO_VERSION from $DOWNLOAD_URL"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

curl -fsSL "$DOWNLOAD_URL" -o "$TMPDIR/deno.zip"
unzip -q "$TMPDIR/deno.zip" -d "$TMPDIR/deno-extracted"

# Install to a fixed location and symlink into PATH
rm -rf "$DENO_INSTALL_DIR"
mkdir -p "$DENO_INSTALL_DIR"
cp "$TMPDIR/deno-extracted/deno" "$DENO_INSTALL_DIR/deno"
chmod +x "$DENO_INSTALL_DIR/deno"
ln -sf "$DENO_INSTALL_DIR/deno" /usr/local/bin/deno

# Validate install
if ! command -v deno &>/dev/null; then
  echo "[ERROR] deno not found in PATH after install." >&2
  exit 1
fi

deno --version

echo "[SUCCESS] Deno $DENO_VERSION installed at $DENO_INSTALL_DIR/deno"
