#!/usr/bin/env bash
# Scenario: install a non-default biome version (biomeVersion=2.4.12)
# and verify the installed version matches the requested one.

set -e

source dev-container-features-test-lib

check "biome is installed" biome --version
check "custom biome version is 2.4.12" bash -c "biome --version | grep '2.4.12'"

reportResults
