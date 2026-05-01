#!/usr/bin/env bash
set -euo pipefail


NODE_VERSION=${NODE_VERSION:-24.11.0}
PNPM_VERSION=${PNPM_VERSION:-}


# If PNPM_VERSION is not set, try to detect from package.json
if [[ -z "$PNPM_VERSION" ]]; then
  if [[ -f /workspaces/$(basename $(pwd))/package.json ]]; then
    PKG_JSON="/workspaces/$(basename $(pwd))/package.json"
  elif [[ -f ./package.json ]]; then
    PKG_JSON=./package.json
  else
    PKG_JSON=""
  fi
  if [[ -n "$PKG_JSON" ]]; then
    PM_FIELD=$(grep '"packageManager"' "$PKG_JSON" | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
    if [[ "$PM_FIELD" == pnpm@* ]]; then
      PNPM_VERSION=$(echo "$PM_FIELD" | sed 's/pnpm@\([0-9.]*\).*/\1/')
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


# Install corepack if needed (Node >= 16.17.0, but only bundled by default in Node >= 16.17.0 and < 25.0.0)
NODE_MAJOR=$(node -v | sed 's/v\([0-9]*\).*/\1/')
NODE_MINOR=$(node -v | sed 's/v[0-9]*\.\([0-9]*\).*/\1/')

if (( NODE_MAJOR < 16 )); then
  echo "[ERROR] Node.js >= 16.17.0 is required for corepack/pnpm support." >&2
  exit 1
fi

# Node >= 25.0.0: corepack is NOT bundled, must install manually
if (( NODE_MAJOR >= 25 )); then
  if ! command -v corepack >/dev/null 2>&1; then
    echo "[INFO] Installing corepack (not bundled in Node >= 25)..."
    npm install -g corepack
  fi
else
  # Node < 25: corepack should be present, but enable if needed
  if ! command -v corepack >/dev/null 2>&1; then
    echo "[ERROR] corepack not found in PATH for Node.js $NODE_VERSION" >&2
    exit 1
  fi
  corepack enable || true
fi


# Now install pnpm with corepack
echo "[INFO] Installing pnpm $PNPM_VERSION..."
corepack prepare pnpm@$PNPM_VERSION --activate

# Validate versions
node -v | grep "$NODE_VERSION" || { echo "[ERROR] Node.js version mismatch" >&2; exit 1; }
pnpm -v | grep "$PNPM_VERSION" || { echo "[ERROR] pnpm version mismatch" >&2; exit 1; }

echo "[SUCCESS] Node.js $NODE_VERSION and pnpm $PNPM_VERSION installed."
