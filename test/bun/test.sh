#!/usr/bin/env bash
# This test file is executed against an auto-generated devcontainer that
# installs the 'bun' feature with default options (bunVersion=1.3.13).
#
# Run with:
#   devcontainer features test -f bun --skip-scenarios \
#     -i mcr.microsoft.com/devcontainers/base:ubuntu .

set -e

source dev-container-features-test-lib

check "bun is installed" bun --version
check "bun default version is 1.3.13" bash -c "bun --version | grep '1.3.13'"

reportResults
