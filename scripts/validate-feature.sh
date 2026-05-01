#!/usr/bin/env bash
set -euo pipefail

# Validate a devcontainer feature's five-file completeness and structural
# correctness.
#
# Usage:
#   pnpm run validate-feature <id>
#   pnpm run validate-feature biome
#   pnpm run validate-feature package-manager
#
# Exit codes:
#   0 — all checks passed
#   1 — one or more checks failed

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
DOC_FILE="${REPO_ROOT}/docs/features/${ID}.md"
JSON_FILE="${FEATURE_DIR}/devcontainer-feature.json"
INSTALL_FILE="${FEATURE_DIR}/install.sh"
TEST_SH="${TEST_DIR}/test.sh"
SCENARIOS_FILE="${TEST_DIR}/scenarios.json"

ERRORS=0

fail() {
  echo "[FAIL] $1" >&2
  ERRORS=$((ERRORS + 1))
}

pass() {
  echo "[PASS] $1"
}

echo "Validating feature: ${ID}"
echo ""

# ── Five-file completeness ────────────────────────────────────────────────────

if [[ -f "$JSON_FILE" ]]; then
  pass "devcontainer-feature.json exists"
else
  fail "devcontainer-feature.json not found at: features/${ID}/devcontainer-feature.json"
fi

# Derive the feature id and doc file path from the JSON.
# The doc filename must match the feature id (e.g. claude-code.md for id=claude-code).
if [[ -f "$JSON_FILE" ]]; then
  FEATURE_JSON_ID=$(node -e "const j=JSON.parse(require('fs').readFileSync('${JSON_FILE}','utf8')); process.stdout.write(j.id||'')" 2>/dev/null)
  DOC_URL_FOR_PATH=$(node -e "const j=JSON.parse(require('fs').readFileSync('${JSON_FILE}','utf8')); process.stdout.write(j.documentationURL||'')" 2>/dev/null)
  DOC_REL_FROM_URL=$(echo "$DOC_URL_FOR_PATH" | sed 's|.*/blob/main/||')
  if [[ -n "$DOC_REL_FROM_URL" ]]; then
    DOC_FILE="${REPO_ROOT}/${DOC_REL_FROM_URL}"
  else
    DOC_FILE="${REPO_ROOT}/docs/features/${FEATURE_JSON_ID}.md"
  fi
else
  FEATURE_JSON_ID="$ID"
fi

if [[ -f "$INSTALL_FILE" ]]; then
  pass "install.sh exists"
else
  fail "install.sh not found at: features/${ID}/install.sh"
fi

if [[ -f "$TEST_SH" ]]; then
  pass "test.sh exists"
else
  fail "test.sh not found at: test/${ID}/test.sh"
fi

if [[ -f "$SCENARIOS_FILE" ]]; then
  pass "scenarios.json exists"
else
  fail "scenarios.json not found at: test/${ID}/scenarios.json"
fi

if [[ -f "$DOC_FILE" ]]; then
  pass "documentation file exists: ${DOC_REL_FROM_URL:-docs/features/${FEATURE_JSON_ID}.md}"
else
  fail "${DOC_REL_FROM_URL:-docs/features/${FEATURE_JSON_ID}.md} not found"
fi

# ── install.sh structural checks ─────────────────────────────────────────────

if [[ -f "$INSTALL_FILE" ]]; then
  if [[ -x "$INSTALL_FILE" ]]; then
    pass "install.sh is executable"
  else
    fail "install.sh is not executable (run: chmod +x ${INSTALL_FILE})"
  fi

  FIRST_LINE=$(head -1 "$INSTALL_FILE")
  if [[ "$FIRST_LINE" == "#!/usr/bin/env bash" ]]; then
    pass "install.sh shebang is correct"
  else
    fail "install.sh first line must be '#!/usr/bin/env bash', got: ${FIRST_LINE}"
  fi

  if grep -q "set -euo pipefail" "$INSTALL_FILE"; then
    pass "install.sh has 'set -euo pipefail'"
  else
    fail "install.sh is missing 'set -euo pipefail'"
  fi
fi

# ── devcontainer-feature.json structural checks ───────────────────────────────

if [[ -f "$JSON_FILE" ]]; then
  # Validate JSON syntax
  if node -e "JSON.parse(require('fs').readFileSync('${JSON_FILE}','utf8'))" 2>/dev/null; then
    pass "devcontainer-feature.json is valid JSON"
  else
    fail "devcontainer-feature.json is not valid JSON"
  fi

  # Check required fields
  for field in id version name description documentationURL; do
    VALUE=$(node -e "const j=JSON.parse(require('fs').readFileSync('${JSON_FILE}','utf8')); process.stdout.write(j['${field}']||'')" 2>/dev/null)
    if [[ -n "$VALUE" ]]; then
      pass "devcontainer-feature.json has required field: ${field}"
    else
      fail "devcontainer-feature.json is missing required field: ${field}"
    fi
  done

  # Check version is valid semver (major.minor.patch)
  VERSION=$(node -e "const j=JSON.parse(require('fs').readFileSync('${JSON_FILE}','utf8')); process.stdout.write(j.version||'')" 2>/dev/null)
  if [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    pass "version is valid semver: ${VERSION}"
  else
    fail "version is not valid semver (expected major.minor.patch): ${VERSION}"
  fi

  # Check documentationURL points to a file that actually exists in the repo
  DOC_URL=$(node -e "const j=JSON.parse(require('fs').readFileSync('${JSON_FILE}','utf8')); process.stdout.write(j.documentationURL||'')" 2>/dev/null)
  # Extract the path after the main branch ref
  DOC_REL_PATH=$(echo "$DOC_URL" | sed 's|.*/blob/main/||')
  if [[ -n "$DOC_REL_PATH" && -f "${REPO_ROOT}/${DOC_REL_PATH}" ]]; then
    pass "documentationURL points to an existing file: ${DOC_REL_PATH}"
  else
    fail "documentationURL points to a file that does not exist: ${DOC_URL}"
  fi

  # Check feature id is non-empty
  if [[ -n "$FEATURE_JSON_ID" ]]; then
    pass "feature id is set: ${FEATURE_JSON_ID}"
  else
    fail "feature id is empty in devcontainer-feature.json"
  fi
fi

# ── test.sh structural checks ─────────────────────────────────────────────────

if [[ -f "$TEST_SH" ]]; then
  if [[ -x "$TEST_SH" ]]; then
    pass "test.sh is executable"
  else
    fail "test.sh is not executable (run: chmod +x ${TEST_SH})"
  fi

  FIRST_LINE=$(head -1 "$TEST_SH")
  if [[ "$FIRST_LINE" == "#!/usr/bin/env bash" ]]; then
    pass "test.sh shebang is correct"
  else
    fail "test.sh first line must be '#!/usr/bin/env bash', got: ${FIRST_LINE}"
  fi

  if grep -q "set -euo pipefail" "$TEST_SH"; then
    pass "test.sh has 'set -euo pipefail'"
  else
    fail "test.sh is missing 'set -euo pipefail'"
  fi

  if grep -q "\[PASS\]" "$TEST_SH"; then
    pass "test.sh has a [PASS] marker"
  else
    fail "test.sh is missing a [PASS] marker at the end"
  fi
fi

# ── scenarios.json structural checks ─────────────────────────────────────────

if [[ -f "$SCENARIOS_FILE" ]]; then
  if node -e "
    const j = JSON.parse(require('fs').readFileSync('${SCENARIOS_FILE}', 'utf8'));
    if (!Array.isArray(j) || j.length === 0) process.exit(1);
  " 2>/dev/null; then
    pass "scenarios.json is a non-empty array"
  else
    fail "scenarios.json must be a non-empty JSON array"
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
if [[ $ERRORS -eq 0 ]]; then
  echo "[SUCCESS] All checks passed for ${ID}."
  exit 0
else
  echo "[FAIL] ${ERRORS} check(s) failed for ${ID}." >&2
  exit 1
fi
