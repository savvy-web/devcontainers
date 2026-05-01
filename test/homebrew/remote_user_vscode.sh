#!/usr/bin/env bash
# Scenario: install Homebrew with remoteUser=vscode (_REMOTE_USER=vscode).
# install.sh installs Homebrew as the vscode user under /home/linuxbrew/.linuxbrew
# and adds it to PATH via /etc/profile.d/homebrew.sh. This test runs as the
# vscode user and verifies brew is functional using the full binary path to
# avoid relying on interactive-shell PATH setup.

set -e

source dev-container-features-test-lib

BREW_BIN="/home/linuxbrew/.linuxbrew/bin/brew"

check "brew binary exists" test -x "$BREW_BIN"
check "brew is functional" "$BREW_BIN" --version
check "brew version output includes Homebrew" bash -c "$BREW_BIN --version | grep Homebrew"

reportResults
