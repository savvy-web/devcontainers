#!/usr/bin/env bash
# Auto-generated scenario test for the 'homebrew' feature.
# The base image (mcr.microsoft.com/devcontainers/base:ubuntu) sets
# _REMOTE_USER=vscode, so install.sh runs the Homebrew installer as the
# vscode user. Homebrew is always installed to /home/linuxbrew/.linuxbrew
# on Linux regardless of which user runs the installer.
#
# Run with:
#   devcontainer features test -f homebrew --skip-scenarios \
#     -i mcr.microsoft.com/devcontainers/base:ubuntu .

set -e

source dev-container-features-test-lib

BREW_BIN="/home/linuxbrew/.linuxbrew/bin/brew"

check "brew binary exists" test -x "$BREW_BIN"
check "brew is functional" "$BREW_BIN" --version
check "brew version output includes Homebrew" bash -c "$BREW_BIN --version | grep Homebrew"

reportResults
