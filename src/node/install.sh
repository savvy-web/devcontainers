#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

# Devcontainer features expose option keys as uppercased env vars, so the
# `nodeVersion` option becomes `NODEVERSION`. Accept the legacy `NODE_VERSION`
# env var as a fallback for direct script invocation.
NODE_VERSION="${NODEVERSION:-${NODE_VERSION:-24.11.0}}"

# Validate absolute versions (no semver ranges)
if [[ "$NODE_VERSION" =~ [^0-9\.] ]]; then
  echo "[ERROR] NODE_VERSION must be an absolute version (e.g. 24.11.0)" >&2
  exit 1
fi

# Resolve target architecture
case "$(uname -m)" in
  x86_64)        NODE_DISTRO="linux-x64" ;;
  aarch64|arm64) NODE_DISTRO="linux-arm64" ;;
  *) echo "[ERROR] Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

NODE_TARBALL="node-v$NODE_VERSION-$NODE_DISTRO.tar.xz"
NODE_URL="https://nodejs.org/dist/v$NODE_VERSION/$NODE_TARBALL"
NODE_SHASUMS_URL="https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt"
NODE_DIR="/usr/local/node-v$NODE_VERSION"

if [[ ! -d "$NODE_DIR" ]]; then
  echo "[INFO] Downloading Node.js $NODE_VERSION..."
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT

  curl -fsSL -o "$TMP_DIR/$NODE_TARBALL" "$NODE_URL"

  echo "[INFO] Verifying SHA256 checksum..."
  curl -fsSL "$NODE_SHASUMS_URL" -o "$TMP_DIR/SHASUMS256.txt"
  (
    cd "$TMP_DIR"
    grep " $NODE_TARBALL\$" SHASUMS256.txt | sha256sum -c -
  )

  tar -xJf "$TMP_DIR/$NODE_TARBALL" -C "$TMP_DIR"
  mv "$TMP_DIR/node-v$NODE_VERSION-$NODE_DISTRO" "$NODE_DIR"

  rm -rf "$TMP_DIR"
  trap - EXIT
fi

export PATH="$NODE_DIR/bin:$PATH"

# Symlink node/npm/npx to /usr/local/bin so they are available in subsequent
# feature install steps and login/non-login shells alike.
ln -sf "$NODE_DIR/bin/node" /usr/local/bin/node
ln -sf "$NODE_DIR/bin/npm" /usr/local/bin/npm
ln -sf "$NODE_DIR/bin/npx" /usr/local/bin/npx

# Node.js 25+ no longer bundles corepack; install it explicitly via npm so
# downstream features (e.g. pnpm) that depend on corepack continue to work.
# Major version is the segment before the first '.', safe because NODE_VERSION
# was already validated against [0-9.]+.
NODE_MAJOR="${NODE_VERSION%%.*}"
if [[ ! -x "$NODE_DIR/bin/corepack" ]]; then
  if (( NODE_MAJOR >= 25 )); then
    echo "[INFO] Node.js $NODE_MAJOR no longer bundles corepack; installing via npm..."
    npm install -g corepack
  else
    echo "[ERROR] Expected bundled corepack at $NODE_DIR/bin/corepack but it is missing" >&2
    exit 1
  fi
fi
ln -sf "$NODE_DIR/bin/corepack" /usr/local/bin/corepack

# Ensure globally installed npm binaries are on PATH for non-login shells.
cat >/etc/profile.d/node.sh <<EOF
export PATH="$NODE_DIR/bin:\$PATH"
EOF
chmod 0644 /etc/profile.d/node.sh

# Validate version exactly (avoid substring false positives like 4.11.0 ⊂ 24.11.0)
ACTUAL_VERSION="$(node -v)"
if [[ "$ACTUAL_VERSION" != "v$NODE_VERSION" ]]; then
  echo "[ERROR] Node.js version mismatch: expected v$NODE_VERSION, got $ACTUAL_VERSION" >&2
  exit 1
fi

echo "[SUCCESS] Node.js $NODE_VERSION installed."
