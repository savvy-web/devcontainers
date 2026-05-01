#!/usr/bin/env bash
set -euo pipefail

# bats installer — Bash Automated Testing System with support libraries
# Docs: https://bats-core.readthedocs.io/

BATS_VER="${BATSVERSION:-1.13.0}"
BATS_SUPPORT_VER="${BATSSUPPORTVERSION:-0.3.0}"
BATS_ASSERT_VER="${BATSASSERTVERSION:-2.2.4}"
BATS_MOCK_VER="${BATSMOCKVERSION:-1.2.5}"

# Strip leading 'v' to normalize (accept both '1.13.0' and 'v1.13.0')
BATS_VER="${BATS_VER#v}"
BATS_SUPPORT_VER="${BATS_SUPPORT_VER#v}"
BATS_ASSERT_VER="${BATS_ASSERT_VER#v}"
BATS_MOCK_VER="${BATS_MOCK_VER#v}"

echo "[INFO] Installing git..."
apt-get update -y
apt-get install -y --no-install-recommends git

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Install bats-core
echo "[INFO] Installing bats-core v${BATS_VER}..."
git clone --depth 1 --branch "v${BATS_VER}" \
  https://github.com/bats-core/bats-core.git "$TMPDIR/bats-core"
"$TMPDIR/bats-core/install.sh" /usr/local

# Install bats-support
echo "[INFO] Installing bats-support v${BATS_SUPPORT_VER}..."
git clone --depth 1 --branch "v${BATS_SUPPORT_VER}" \
  https://github.com/bats-core/bats-support.git "$TMPDIR/bats-support"
mkdir -p /usr/local/lib/bats-support
rm -rf "$TMPDIR/bats-support/.git"
cp -r "$TMPDIR/bats-support/." /usr/local/lib/bats-support/

# Install bats-assert
echo "[INFO] Installing bats-assert v${BATS_ASSERT_VER}..."
git clone --depth 1 --branch "v${BATS_ASSERT_VER}" \
  https://github.com/bats-core/bats-assert.git "$TMPDIR/bats-assert"
mkdir -p /usr/local/lib/bats-assert
rm -rf "$TMPDIR/bats-assert/.git"
cp -r "$TMPDIR/bats-assert/." /usr/local/lib/bats-assert/

# Install bats-mock
echo "[INFO] Installing bats-mock v${BATS_MOCK_VER}..."
git clone --depth 1 --branch "v${BATS_MOCK_VER}" \
  https://github.com/jasonkarns/bats-mock.git "$TMPDIR/bats-mock"
mkdir -p /usr/local/lib/bats-mock
for f in stub.bash binstub load.bash; do
  [[ -f "$TMPDIR/bats-mock/$f" ]] && cp "$TMPDIR/bats-mock/$f" /usr/local/lib/bats-mock/
done
[[ -f /usr/local/lib/bats-mock/binstub ]] && chmod +x /usr/local/lib/bats-mock/binstub
if [[ ! -f /usr/local/lib/bats-mock/load.bash ]]; then
  # SC2016: single quotes intentional — literal ${BASH_SOURCE[0]} goes into generated file
  # shellcheck disable=SC2016
  printf 'source "$(dirname "${BASH_SOURCE[0]}")/stub.bash"\n' \
    > /usr/local/lib/bats-mock/load.bash
fi

echo "[INFO] Removing git (build-only dependency)..."
apt-get purge -y git
apt-get autoremove -y
rm -rf /var/lib/apt/lists/*

# Validate install
if ! command -v bats &>/dev/null; then
  echo "[ERROR] bats not found in PATH after install." >&2
  exit 1
fi

bats --version
echo "[SUCCESS] bats v${BATS_VER} with support libraries installed."
