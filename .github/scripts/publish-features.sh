#!/usr/bin/env bash
# Iterates topo-order.js output and tests + publishes each feature whose
# current version is not yet in the registry. Publishing in topological order
# means a dependent feature's `installsAfter` references are already
# resolvable from the registry by the time it is tested.
#
# Env:
#   DRY_RUN              "true" to skip the actual publish (default "false").
#   OCI_REGISTRY         OCI registry hostname (default "ghcr.io").
#   FEATURES_NAMESPACE   Namespace under the registry (default
#                        "savvy-web/features").
#   ORDER_JSON           Path to topo-order.js JSON output (default
#                        /tmp/order.json).
#
# Exit code:
#   0 on success, non-zero if any feature failed test or publish.

set -euo pipefail

DRY_RUN="${DRY_RUN:-false}"
OCI_REGISTRY="${OCI_REGISTRY:-ghcr.io}"
FEATURES_NAMESPACE="${FEATURES_NAMESPACE:-savvy-web/features}"
ORDER_JSON="${ORDER_JSON:-/tmp/order.json}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [[ ! -f "$ORDER_JSON" ]]; then
  echo "[ERROR] Order file not found: $ORDER_JSON" >&2
  exit 1
fi

ANY_PUBLISHED=0

# Read from FD 3 so the inner devcontainer/docker subprocesses (which inherit
# stdin) cannot consume the rest of the loop's input.
while IFS= read -r entry <&3; do
  ID=$(jq -r .id <<<"$entry")
  VERSION=$(jq -r .version <<<"$entry")
  PUBLISH=$(jq -r .publish <<<"$entry")

  if [[ "$PUBLISH" != "true" ]]; then
    echo "::group::⏭️  ${ID}@${VERSION} — already published"
    echo "Skipping: image exists in registry"
    echo "::endgroup::"
    continue
  fi

  echo "::group::🧪 Test ${ID}@${VERSION}"
  REPO_ROOT="$REPO_ROOT" bash "${SCRIPT_DIR}/test-feature-isolated.sh" "$ID"
  echo "::endgroup::"

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "::group::🔍 Dry run — would publish ${ID}@${VERSION}"
    devcontainer features package "${REPO_ROOT}/src/${ID}" \
      --output-folder "/tmp/pkg-${ID}" \
      --force-clean-output-folder
    echo "::endgroup::"
    continue
  fi

  echo "::group::🚀 Publish ${ID}@${VERSION}"
  devcontainer features publish "${REPO_ROOT}/src/${ID}" \
    --namespace "${FEATURES_NAMESPACE}" \
    --registry "${OCI_REGISTRY}"
  ANY_PUBLISHED=1
  echo "::endgroup::"
done 3< <(jq -c '.[]' "$ORDER_JSON")

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "any_published=${ANY_PUBLISHED}" >> "$GITHUB_OUTPUT"
fi
