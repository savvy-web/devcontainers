#!/usr/bin/env bash
set -euo pipefail


NODE_VERSION=${NODE_VERSION:-24.11.0}
PNPM_VERSION=${PNPM_VERSION:-}


# If PNPM_VERSION is not set, try to detect from package.json
if [[ -z "$PNPM_VERSION" ]]; then
  if [[ -f /workspaces/"$(basename "$(pwd)")"/package.json ]]; then
    PKG_JSON="/workspaces/$(basename "$(pwd)")/package.json"
  elif [[ -f ./package.json ]]; then
    PKG_JSON=./package.json
  else
    PKG_JSON=""
  fi
  if [[ -n "$PKG_JSON" ]]; then
    PM_FIELD=$(grep '"packageManager"' "$PKG_JSON" | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
    if [[ "$PM_FIELD" == pnpm@* ]]; then
      PNPM_VERSION="${PM_FIELD#pnpm@}"
      PNPM_VERSION="${PNPM_VERSION%%[^0-9.]*}"
      echo "[INFO] Detected pnpm version $PNPM_VERSION from package.json."
    elif [[ -n "$PM_FIELD" ]]; then
      echo "[ERROR] packageManager field is present but not pnpm: $PM_FIELD" >&2
      exit 1
    fi
  fi
fi

# If still not set, fallback to latest
if [[ -z "$PNPM_VERSION" ]]; then
  echo "[INFO] No pnpm version specified, no package.json with pnpm found. Installing latest pnpm."
  PNPM_VERSION=latest
fi

# Validate absolute versions (no semver ranges, unless 'latest')
if [[ "$NODE_VERSION" =~ [^0-9\.] ]]; then
  echo "[ERROR] NODE_VERSION must be an absolute version (e.g. 24.11.0)" >&2
  exit 1
fi
if [[ "$PNPM_VERSION" != "latest" && "$PNPM_VERSION" =~ [^0-9\.] ]]; then
  echo "[ERROR] PNPM_VERSION must be an absolute version (e.g. 10.20.0) or 'latest'" >&2
  exit 1
fi

# Install Node.js (tarball, not nvm)
ARCH=$(uname -m)
NODE_DISTRO="linux-x64"
if [[ "$ARCH" == "aarch64" ]]; then
  NODE_DISTRO="linux-arm64"
fi
NODE_URL="https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-$NODE_DISTRO.tar.xz"
NODE_DIR="/usr/local/node-v$NODE_VERSION"

if [[ ! -d "$NODE_DIR" ]]; then
  echo "[INFO] Downloading Node.js $NODE_VERSION..."
  curl -fsSL "$NODE_URL" | tar -xJ -C /usr/local/
  mv "/usr/local/node-v$NODE_VERSION-$NODE_DISTRO" "$NODE_DIR"
fi

export PATH="$NODE_DIR/bin:$PATH"

# Symlink node/npm/npx to /usr/local/bin so they are available in subsequent steps
ln -sf "$NODE_DIR/bin/node" /usr/local/bin/node
ln -sf "$NODE_DIR/bin/npm" /usr/local/bin/npm
ln -sf "$NODE_DIR/bin/npx" /usr/local/bin/npx

# Install pnpm via npm — avoids corepack's interactive download prompts entirely
echo "[INFO] Installing pnpm $PNPM_VERSION..."
npm install -g "pnpm@${PNPM_VERSION}"

# Symlink pnpm to /usr/local/bin so it is available in subsequent steps
ln -sf "$NODE_DIR/bin/pnpm" /usr/local/bin/pnpm

# Validate versions
node -v | grep "$NODE_VERSION" || { echo "[ERROR] Node.js version mismatch" >&2; exit 1; }
pnpm -v | grep "$PNPM_VERSION" || { echo "[ERROR] pnpm version mismatch" >&2; exit 1; }

echo "[SUCCESS] Node.js $NODE_VERSION and pnpm $PNPM_VERSION installed."
