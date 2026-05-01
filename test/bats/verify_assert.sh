#!/usr/bin/env bash
# Scenario: verify that bats-assert functions work after install.
# Writes a temporary .bats file inline and runs it with bats to confirm
# assert_output, assert_success, assert_failure, and refute_output all
# behave correctly.

set -e

source dev-container-features-test-lib

BATS_FILE=$(mktemp --suffix=.bats)
trap 'rm -f "$BATS_FILE"' EXIT

cat > "$BATS_FILE" << 'BATS_EOF'
bats_require_minimum_version 1.5.0

load '/usr/local/lib/bats-support/load'
load '/usr/local/lib/bats-assert/load'

@test "assert_output matches exact string" {
  run echo "hello world"
  assert_output "hello world"
}

@test "assert_success passes for zero exit" {
  run true
  assert_success
}

@test "assert_failure passes for non-zero exit" {
  run false
  assert_failure
}

@test "refute_output passes when output does not match" {
  run echo "hello"
  refute_output "goodbye"
}

@test "assert_output --partial matches substring" {
  run echo "the quick brown fox"
  assert_output --partial "quick brown"
}
BATS_EOF

check "bats-assert: assert_output, assert_success, assert_failure, refute_output all pass" \
  bats "$BATS_FILE"

reportResults
