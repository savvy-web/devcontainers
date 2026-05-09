#!/usr/bin/env bash
set -euo pipefail

# Test a single devcontainer feature locally using the devcontainer CLI.
#
# Usage:
#   pnpm run feature:test <id>
#   pnpm run feature:test biome
#   pnpm run feature:test package-manager
#
# Requires:
#   - Docker running locally
#   - @devcontainers/cli: npm install -g @devcontainers/cli
#
# Delegates to .github/scripts/test-feature-isolated.sh, which copies the src/
# and test/ trees into a scratch directory, strips savvy-web `installsAfter`
# entries (the CLI rejects unresolvable 3-segment OCI references even though
# scenarios test features in isolation), and runs the devcontainer CLI against
# the scratch copy.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

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
  find "${REPO_ROOT}/src" -mindepth 2 -maxdepth 2 -name "devcontainer-feature.json" \
    | sed "s|${REPO_ROOT}/src/||" \
    | sed 's|/devcontainer-feature.json||' \
    | sort \
    | sed 's|^|  |'
  exit 1
fi

echo "[INFO] Testing feature: ${ID}"
echo ""

REPO_ROOT="$REPO_ROOT" exec bash "${REPO_ROOT}/.github/scripts/test-feature-isolated.sh" "$ID"
