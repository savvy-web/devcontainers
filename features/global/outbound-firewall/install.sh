#!/usr/bin/env bash
set -euo pipefail

BLOCK_ALL=${BLOCK_ALL:-false}
ALLOWLIST=${ALLOWLIST:-""}

# Only run as root
if [[ $EUID -ne 0 ]]; then
  echo "[ERROR] Outbound firewall feature must be run as root." >&2
  exit 1
fi

# Flush existing rules
iptables -F OUTPUT

if [[ "$BLOCK_ALL" == "true" ]]; then
  echo "[INFO] Blocking all outbound traffic except allowlist..."
  iptables -A OUTPUT -j DROP
  IFS="," read -ra ALLOWED <<< "$ALLOWLIST"
  for entry in "${ALLOWED[@]}"; do
    if [[ -n "$entry" ]]; then
      iptables -I OUTPUT -d "$entry" -j ACCEPT
    fi
  done
else
  echo "[INFO] No outbound firewall rules applied."
fi

echo "[SUCCESS] Outbound firewall rules configured."
