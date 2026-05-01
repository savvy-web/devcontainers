#!/usr/bin/env bash
# This test file is executed against an auto-generated devcontainer that
# installs the 'kcov' feature with default options (kcovVersion=43).
#
# Run with:
#   devcontainer features test -f kcov --skip-scenarios \
#     -i mcr.microsoft.com/devcontainers/base:ubuntu .

set -e

# Import test library provided by the devcontainer CLI
# https://github.com/devcontainers/cli/blob/main/docs/features/test.md
source dev-container-features-test-lib

check "kcov is installed" bash -c "command -v kcov"
check "kcov default version is 43" bash -c "kcov --version 2>&1 | grep -E 'v?43'"

reportResults
