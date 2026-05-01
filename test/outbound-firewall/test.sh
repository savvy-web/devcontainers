#!/usr/bin/env bash
set -euo pipefail

# Test: Outbound firewall block all
# Re-run install with blockAll=true so the DROP rule is applied
BLOCK_ALL=true bash features/outbound-firewall/install.sh

iptables -L OUTPUT | grep "DROP" || { echo "[FAIL] Outbound firewall not blocking as expected" >&2; exit 1; }
echo "[PASS] Outbound firewall block all test passed."
