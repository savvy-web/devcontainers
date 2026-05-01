#!/usr/bin/env bash
# This test file is executed against an auto-generated devcontainer that
# installs the 'homebrew' feature as root (_REMOTE_USER=root). In that
# case, install.sh creates a dedicated 'linuxbrew' account and installs
# Homebrew under /home/linuxbrew/.linuxbrew.
#
# Run with:
#   devcontainer features test -f homebrew --skip-scenarios \
#     -i mcr.microsoft.com/devcontainers/base:ubuntu .

set -e

source dev-container-features-test-lib

BREW_BIN="/home/linuxbrew/.linuxbrew/bin/brew"

check "brew binary exists" test -x "$BREW_BIN"
check "brew runs via linuxbrew user" bash -c "su - linuxbrew -s /bin/bash -c '/home/linuxbrew/.linuxbrew/bin/brew --version' | grep Homebrew"

reportResults
