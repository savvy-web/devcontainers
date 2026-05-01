#!/usr/bin/env bash
# This test file is executed against an auto-generated devcontainer that
# installs the 'act' feature with default options (actVersion=0.2.76).
#
# Run with:
#   devcontainer features test -f act --skip-scenarios \
#     -i mcr.microsoft.com/devcontainers/base:ubuntu .

set -e

source dev-container-features-test-lib

check "act is installed" act --version
check "act default version is 0.2.76" bash -c "act --version | grep '0.2.76'"

reportResults
