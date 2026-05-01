#!/usr/bin/env bash
set -euo pipefail

# act installer — runs GitHub Actions workflows locally
# Docs: https://nektosact.com/installation/index.html

VERSION="${ACT_VERSION:-0.2.76}"
ACT_BIN="/usr/local/bin/act"

ARCH=$(uname -m)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

if [[ "$OS" == "linux" ]]; then
  OS_LABEL="Linux"
elif [[ "$OS" == "darwin" ]]; then
  OS_LABEL="Darwin"
else
  echo "[ERROR] Unsupported OS: $OS" >&2
  exit 1
fi

if [[ "$ARCH" == "x86_64" ]]; then
  ARCH_LABEL="x86_64"
elif [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
  ARCH_LABEL="arm64"
else
  echo "[ERROR] Unsupported architecture: $ARCH" >&2
  exit 1
fi

TARBALL="act_${OS_LABEL}_${ARCH_LABEL}.tar.gz"
DOWNLOAD_URL="https://github.com/nektos/act/releases/download/v${VERSION}/${TARBALL}"

echo "[INFO] Installing act ${VERSION} (${OS_LABEL}/${ARCH_LABEL})"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

curl -fsSL "$DOWNLOAD_URL" -o "$TMPDIR/act.tar.gz"
tar -C "$TMPDIR" -xf "$TMPDIR/act.tar.gz" act

install -m 0755 "$TMPDIR/act" "$ACT_BIN"

# Validate install
if ! command -v act &>/dev/null; then
  echo "[ERROR] act not found in PATH after install." >&2
  exit 1
fi

act --version
echo "[SUCCESS] act ${VERSION} installed at ${ACT_BIN}"
