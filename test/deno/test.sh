#!/usr/bin/env bash
# This test file is executed against an auto-generated devcontainer that
# installs the 'deno' feature with default options (denoVersion=2.7.14).
#
# Run with:
#   devcontainer features test -f deno --skip-scenarios \
#     -i mcr.microsoft.com/devcontainers/base:ubuntu .

set -e

source dev-container-features-test-lib

check "deno is installed" deno --version
check "deno default version is 2.7.14" bash -c "deno --version | grep '2.7.14'"

reportResults
