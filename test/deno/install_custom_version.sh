#!/usr/bin/env bash
# Scenario: install a non-default Deno version (denoVersion=2.6.0) and verify
# the installed version matches the requested one.

set -e

source dev-container-features-test-lib

check "deno is installed" deno --version
check "custom deno version is 2.6.0" bash -c "deno --version | grep '2.6.0'"

reportResults
