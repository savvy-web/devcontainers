#!/usr/bin/env bash
# Scenario: verify that bats-mock stub/unstub work after install.
# Writes a temporary .bats file inline and runs it with bats to confirm
# that stub replaces a command with controlled output and unstub validates
# the expected number of invocations.

set -e

source dev-container-features-test-lib

BATS_FILE=$(mktemp --suffix=.bats)
trap 'rm -f "$BATS_FILE"' EXIT

cat > "$BATS_FILE" << 'BATS_EOF'
bats_require_minimum_version 1.5.0

load '/usr/local/lib/bats-support/load'
load '/usr/local/lib/bats-assert/load'
load '/usr/local/lib/bats-mock/load'

@test "stub intercepts a command and returns controlled output" {
  stub mycmd \
    ": echo 'stub was called'"

  run mycmd
  assert_success
  assert_output "stub was called"

  unstub mycmd
}

@test "stub enforces ordered multi-call expectations" {
  stub mycmd \
    ": echo 'first'" \
    ": echo 'second'"

  run mycmd
  assert_output "first"

  run mycmd
  assert_output "second"

  unstub mycmd
}

@test "stub passes through arguments for matching" {
  stub mycmd \
    "greet : echo 'hello from stub'"

  run mycmd greet
  assert_success
  assert_output "hello from stub"

  unstub mycmd
}
BATS_EOF

check "bats-mock: stub intercepts commands; unstub validates call count" \
  bats "$BATS_FILE"

reportResults
