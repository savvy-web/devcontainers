#!/usr/bin/env bash
set -euo pipefail

# Test a single devcontainer feature locally using act.
#
# Usage:
#   pnpm run test:feature <id>
#   pnpm run test:feature biome
#   pnpm run test:feature package-manager
#
# Requires act: https://nektosact.com
# Install with the act devcontainer feature or via: https://github.com/nektos/act

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

ID="${1:-}"

if [[ -z "$ID" ]]; then
  echo "Usage: $0 <id>"
  echo ""
  echo "Examples:"
  echo "  $0 biome"
  echo "  $0 rust"
  echo "  $0 package-manager"
  echo ""
  echo "Available features:"
  find "${REPO_ROOT}/features" -mindepth 2 -maxdepth 2 -name "devcontainer-feature.json" \
    | sed "s|${REPO_ROOT}/features/||" \
    | sed 's|/devcontainer-feature.json||' \
    | sort \
    | sed 's|^|  |'
  exit 1
fi

FEATURE_DIR="${REPO_ROOT}/features/${ID}"
TEST_DIR="${REPO_ROOT}/test/${ID}"

if [[ ! -f "${FEATURE_DIR}/devcontainer-feature.json" ]]; then
  echo "[ERROR] Feature not found: features/${ID}" >&2
  echo "        Run '$0' without arguments to see available features." >&2
  exit 1
fi

if [[ ! -f "${TEST_DIR}/test.sh" ]]; then
  echo "[ERROR] Test script not found: test/${ID}/test.sh" >&2
  exit 1
fi

if ! command -v act &>/dev/null; then
  echo "[ERROR] act is not installed." >&2
  echo "        Install it with: https://nektosact.com/installation/index.html" >&2
  echo "        Or add the act devcontainer feature to your devcontainer.json:" >&2
  echo "        \"ghcr.io/savvy-web/act:0.1.0\": {}" >&2
  exit 1
fi

echo "[INFO] Testing feature: ${ID}"
echo ""

cd "${REPO_ROOT}"

act workflow_dispatch \
  --input id="${ID}" \
  -W .github/workflows/test-feature.yml \
  --rm
