#!/usr/bin/env bash
# This test file is executed against an auto-generated devcontainer that
# installs the 'zig' feature with default options (zigVersion=0.12.0).
#
# Run with:
#   devcontainer features test -f zig --skip-scenarios \
#     -i mcr.microsoft.com/devcontainers/base:ubuntu .

set -e

source dev-container-features-test-lib

check "zig is installed" zig version
check "zig default version is 0.12.0" bash -c "zig version | grep '0.12.0'"

reportResults
