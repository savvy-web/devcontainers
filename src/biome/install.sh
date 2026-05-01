#!/usr/bin/env bash
set -euo pipefail

# Biome global installer (official binary method)
# Docs: https://biomejs.dev/guides/manual-installation/

VERSION="${BIOMEVERSION:-${BIOME_VERSION:-2.4.13}}"
BIOME_BIN="/usr/local/bin/biome"

if [[ "$VERSION" == "latest" ]]; then
  # Get latest version from GitHub API; tag format is "@biomejs/biome@2.x.x"
  TAG=$(curl -fsSL https://api.github.com/repos/biomejs/biome/releases/latest \
    | grep '"tag_name"' \
    | sed -E 's/.*"([^"]+)".*/\1/')
  VERSION=$(echo "$TAG" | sed 's|^@biomejs/biome@||' | sed 's|^cli/v||' | sed 's|^v||')
fi

ARCH=$(uname -m)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

if [[ "$ARCH" == "x86_64" ]]; then
  ARCH="x64"
elif [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
  ARCH="arm64"
else
  echo "[ERROR] Unsupported architecture: $ARCH" >&2
  exit 1
fi

BIOME_URL="https://github.com/biomejs/biome/releases/download/%40biomejs%2Fbiome%40${VERSION}/biome-${OS}-${ARCH}"

echo "[INFO] Downloading Biome ${VERSION} from ${BIOME_URL}..."
# Download and install
curl -fsSL "$BIOME_URL" -o "$BIOME_BIN"
chmod +x "$BIOME_BIN"

# Validate install
if ! command -v biome &>/dev/null; then
  echo "[ERROR] Biome not found in PATH after install." >&2
  exit 1
fi

# Print version
biome --version
echo "[SUCCESS] Biome ${VERSION} installed."
