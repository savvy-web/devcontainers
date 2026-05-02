#!/usr/bin/env bash
# Scenario: install a non-default Bun version (bunVersion=1.2.0) and verify
# the installed version matches the requested one.

set -e

source dev-container-features-test-lib

check "bun is installed" bun --version
check "custom bun version is 1.2.0" bash -c "bun --version | grep '1.2.0'"

reportResults
