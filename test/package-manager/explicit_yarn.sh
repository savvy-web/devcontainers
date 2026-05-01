#!/usr/bin/env bash
# Scenario: install package-manager with an explicit yarn version (yarn@4.9.0).
# node is installed first (declared in features) so corepack is available.

set -e

source dev-container-features-test-lib

check "yarn is installed" yarn --version
check "yarn version is 4.9.0" bash -c "yarn --version | grep '4.9.0'"

reportResults
