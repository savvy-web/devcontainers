#!/usr/bin/env bash
set -euo pipefail

# Test: Outbound firewall block all
iptables -L OUTPUT | grep "DROP" || { echo "[FAIL] Outbound firewall not blocking as expected" >&2; exit 1; }
echo "[PASS] Outbound firewall block all test passed."
