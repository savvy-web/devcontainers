#!/usr/bin/env bash
# Scenario: install a non-default Zig version (zigVersion=0.13.0) and verify
# the installed version matches the requested one.

set -e

source dev-container-features-test-lib

check "zig is installed" zig version
check "zig version is 0.13.0" bash -c "zig version | grep '0.13.0'"

reportResults
