#!/usr/bin/env bash
set -euo pipefail

# kcov installer — code coverage for bash/shell scripts and binaries
# Docs: https://simonkagstrom.github.io/kcov/

VERSION="${KCOVVERSION:-${KCOV_VERSION:-43}}"

# Strip leading 'v' to normalize (accept both '43' and 'v43')
VERSION="${VERSION#v}"

if [[ "$VERSION" == "latest" ]]; then
  echo "[INFO] Detecting latest stable kcov release..."
  TAG=$(curl -fsSL "https://api.github.com/repos/SimonKagstrom/kcov/tags?per_page=100" \
    | grep '"name"' \
    | sed -E 's/.*"([^"]+)".*/\1/' \
    | grep -E '^v[0-9]+$' \
    | sort -t'v' -k2 -n \
    | tail -1)
  if [[ -z "$TAG" ]]; then
    echo "[ERROR] Could not detect latest stable kcov version from GitHub." >&2
    exit 1
  fi
  VERSION="${TAG#v}"
  echo "[INFO] Latest stable kcov version: ${VERSION}"
fi

BUILD_DEPS=(
  cmake gcc g++ git python3
  libssl-dev binutils-dev libdw-dev libcurl4-openssl-dev
  zlib1g-dev pkg-config
)

echo "[INFO] Installing kcov ${VERSION} build dependencies..."
# If apt-get update fails (e.g. transient DNS failure inside Docker), prepend
# public DNS to /etc/resolv.conf and retry once before giving up.
if ! apt-get update -y; then
  echo "[WARN] apt-get update failed; adding public DNS fallback (8.8.8.8) and retrying..."
  { printf 'nameserver 8.8.8.8\nnameserver 1.1.1.1\n'; cat /etc/resolv.conf; } > /tmp/resolv.conf.new
  cp /tmp/resolv.conf.new /etc/resolv.conf
  apt-get update -y
fi
apt-get install -y --no-install-recommends "${BUILD_DEPS[@]}"

echo "[INFO] Building kcov v${VERSION} from source..."
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

git clone --depth 1 --branch "v${VERSION}" \
  https://github.com/SimonKagstrom/kcov.git "$TMPDIR/kcov"

mkdir "$TMPDIR/kcov/build"
cd "$TMPDIR/kcov/build"
cmake ..
make -j"$(nproc)"
make install

echo "[INFO] Cleaning apt metadata..."
# Do not purge BUILD_DEPS here: some packages in the list may already exist in
# the base image (for example git or python3), and removing them can break
# user expectations or other layered features. Clean apt lists only.
rm -rf /var/lib/apt/lists/*

# Validate install
if ! command -v kcov &>/dev/null; then
  echo "[ERROR] kcov not found in PATH after install." >&2
  exit 1
fi

kcov --version
echo "[SUCCESS] kcov v${VERSION} installed."
