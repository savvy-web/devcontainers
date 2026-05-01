#!/usr/bin/env bash
# This test file is executed against an auto-generated devcontainer that
# installs the 'node' feature with default options (nodeVersion=24.11.0).
#
# Run with:
#   devcontainer features test -f node --skip-scenarios \
#     -i mcr.microsoft.com/devcontainers/base:ubuntu .

set -e

source dev-container-features-test-lib

check "node is installed" node --version
check "npm is installed" npm --version
check "npx is installed" npx --version
check "corepack is installed" corepack --version
check "node default version is 24.11.0" bash -c "node -v | grep 'v24.11.0'"

reportResults
