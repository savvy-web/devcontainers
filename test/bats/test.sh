#!/usr/bin/env bash
# This test file is executed against an auto-generated devcontainer that
# installs the 'bats' feature with default options (batsVersion=1.13.0).
#
# Run with:
#   devcontainer features test -f bats --skip-scenarios \
#     -i mcr.microsoft.com/devcontainers/base:ubuntu .

set -e

# Import test library provided by the devcontainer CLI
# https://github.com/devcontainers/cli/blob/main/docs/features/test.md
source dev-container-features-test-lib

check "bats is installed" bats --version
check "bats default version is 1.13.0" bash -c "bats --version | grep '1.13.0'"
check "bats-support is installed" test -d /usr/local/lib/bats-support
check "bats-assert is installed" test -d /usr/local/lib/bats-assert
check "bats-mock is installed" test -d /usr/local/lib/bats-mock

reportResults
