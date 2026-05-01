#!/usr/bin/env bash
# This test file is executed against an auto-generated devcontainer that
# installs the 'biome' feature with default options (biomeVersion=2.4.13).
#
# Run with:
#   devcontainer features test -f biome --skip-scenarios \
#     -i mcr.microsoft.com/devcontainers/base:ubuntu .

set -e

# Import test library provided by the devcontainer CLI
# https://github.com/devcontainers/cli/blob/main/docs/features/test.md
source dev-container-features-test-lib

check "biome is installed" biome --version
check "biome default version is 2.4.13" bash -c "biome --version | grep '2.4.13'"

reportResults
