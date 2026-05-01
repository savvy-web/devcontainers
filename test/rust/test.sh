#!/usr/bin/env bash
# This test file is executed against an auto-generated devcontainer that
# installs the 'rust' feature with default options (toolchain=stable,
# components=clippy rustfmt).
#
# Run with:
#   devcontainer features test -f rust --skip-scenarios \
#     -i mcr.microsoft.com/devcontainers/base:ubuntu .

set -e

source dev-container-features-test-lib

check "rustc is installed" rustc --version
check "cargo is installed" cargo --version
check "rustup is installed" rustup --version
check "clippy is available" cargo clippy --version
check "rustfmt is available" rustfmt --version

reportResults
