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

# Remember whether git was already present so we don't remove it from the base image later.
# If git is already installed (e.g. mcr.microsoft.com/devcontainers/base:ubuntu ships it),
# skip apt entirely — avoids a network round-trip and DNS failures in CI.
_GIT_PREINSTALLED=false
if dpkg -s git &>/dev/null 2>&1; then
  _GIT_PREINSTALLED=true
else
  # Some CI environments (e.g. GitHub Actions Docker-in-Docker) inject a
  # /etc/resolv.conf that cannot resolve public hostnames. Prepend well-known
  # public nameservers unconditionally so that apt mirrors always resolve.
  { printf 'nameserver 8.8.8.8\nnameserver 1.1.1.1\n'; cat /etc/resolv.conf; } > /tmp/resolv.conf.new
  cp /tmp/resolv.conf.new /etc/resolv.conf
  echo "[INFO] Installing git..."
  apt-get update -y
  apt-get install -y --no-install-recommends git
fi

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

if [[ "$_GIT_PREINSTALLED" == "false" ]]; then
  echo "[INFO] Removing git (installed by this feature, not present in base image)..."
  apt-get purge -y git
fi
# no autoremove — avoids removing transitive runtime libraries from the base image
rm -rf /var/lib/apt/lists/*

# Validate install
if ! command -v bats &>/dev/null; then
  echo "[ERROR] bats not found in PATH after install." >&2
  exit 1
fi

bats --version
echo "[SUCCESS] bats v${BATS_VER} with support libraries installed."
