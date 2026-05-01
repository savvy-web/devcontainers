#!/usr/bin/env bash
# Scenario: install package-manager with an explicit pnpm version (pnpm@10.20.0).
# node is installed first (declared in features) so corepack is available.

set -e

source dev-container-features-test-lib

check "pnpm is installed" pnpm --version
check "pnpm version is 10.20.0" bash -c "pnpm --version | grep '10.20.0'"

reportResults
