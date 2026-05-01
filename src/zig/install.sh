#!/usr/bin/env bash
set -euo pipefail

ZIG_VERSION=${ZIG_VERSION:-0.12.0}
ZIG_ROOT="/usr/local/zig"
ZIG_BIN="$ZIG_ROOT/zig"

# Idempotency: skip if correct version is already installed
if command -v zig >/dev/null 2>&1; then
  INSTALLED_VER=$(zig version | awk '{print $1}')
  if [[ "$ZIG_VERSION" != "master" && "$INSTALLED_VER" == "$ZIG_VERSION" ]]; then
    echo "[INFO] Zig $ZIG_VERSION already installed at $(command -v zig)"
    exit 0
  fi
  if [[ "$ZIG_VERSION" == "master" && "$INSTALLED_VER" == *dev* ]]; then
    echo "[INFO] Zig master/dev build already installed at $(command -v zig)"
    exit 0
  fi
fi

# Detect platform
UNAME=$(uname -s)
ARCH=$(uname -m)
if [[ "$UNAME" == "Linux" ]]; then
  PLATFORM="linux"
elif [[ "$UNAME" == "Darwin" ]]; then
  PLATFORM="macos"
else
  echo "[ERROR] Unsupported OS: $UNAME" >&2
  exit 1
fi

if [[ "$ARCH" == "x86_64" ]]; then
  ARCH_SUFFIX="x86_64"
elif [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
  ARCH_SUFFIX="aarch64"
else
  echo "[ERROR] Unsupported architecture: $ARCH" >&2
  exit 1
fi

# Download URL
if [[ "$ZIG_VERSION" == "master" ]]; then
  ZIG_URL="https://ziglang.org/builds/zig-${PLATFORM}-${ARCH_SUFFIX}-latest.tar.xz"
else
  ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/zig-${PLATFORM}-${ARCH_SUFFIX}-${ZIG_VERSION}.tar.xz"
fi

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Download and extract
curl -fsSL "$ZIG_URL" -o "$TMPDIR/zig.tar.xz"
tar -C "$TMPDIR" -xf "$TMPDIR/zig.tar.xz"

# Find extracted dir
ZIG_EXTRACTED=$(find "$TMPDIR" -maxdepth 1 -type d -name "zig-*" | head -n 1)

# Install (feature scripts run as root; sudo is not needed)
rm -rf "$ZIG_ROOT"
mkdir -p "$ZIG_ROOT"
cp -r "$ZIG_EXTRACTED"/* "$ZIG_ROOT"/
ln -sf "$ZIG_BIN" /usr/local/bin/zig

# Validate
zig version

echo "[SUCCESS] Zig $ZIG_VERSION installed at $ZIG_BIN"
