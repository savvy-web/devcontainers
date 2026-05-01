#!/usr/bin/env bash
# This test file is executed against an auto-generated devcontainer that
# installs the 'claude-code' feature with default options (version=latest).
#
# Run with:
#   devcontainer features test -f claude-code --skip-scenarios \
#     -i mcr.microsoft.com/devcontainers/base:ubuntu .

set -e

source dev-container-features-test-lib

check "claude CLI is installed" claude --version

reportResults
