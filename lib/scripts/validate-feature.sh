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
  find "${REPO_ROOT}/src" -mindepth 2 -maxdepth 2 -name "devcontainer-feature.json" \
    | sed "s|${REPO_ROOT}/src/||" \
    | sed 's|/devcontainer-feature.json||' \
    | sort \
    | sed 's|^|  |'
  exit 1
fi

FEATURE_DIR="${REPO_ROOT}/src/${ID}"
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
  fail "devcontainer-feature.json not found at: src/${ID}/devcontainer-feature.json"
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
  fail "install.sh not found at: src/${ID}/install.sh"
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
  # Executable bits are not stored in git (100644). They are applied by the
  # Husky post-checkout/post-merge hooks locally and by CI workflows before
  # running scripts. Report as informational only — not a hard failure.
  if [[ -x "$INSTALL_FILE" ]]; then
    pass "install.sh is executable"
  else
    echo "[INFO] install.sh is not executable on disk (expected — bits are set by Husky/CI, not git)"
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
  # Executable bits are not stored in git (100644). See install.sh note above.
  if [[ -x "$TEST_SH" ]]; then
    pass "test.sh is executable"
  else
    echo "[INFO] test.sh is not executable on disk (expected — bits are set by Husky/CI, not git)"
  fi

  FIRST_LINE=$(head -1 "$TEST_SH")
  if [[ "$FIRST_LINE" == "#!/usr/bin/env bash" ]]; then
    pass "test.sh shebang is correct"
  else
    fail "test.sh first line must be '#!/usr/bin/env bash', got: ${FIRST_LINE}"
  fi

  if grep -Eq '^[[:space:]]*set[[:space:]]+-euo[[:space:]]+pipefail' "$TEST_SH"; then
    fail "test.sh must use 'set -e' specifically; found 'set -euo pipefail' which enables '-u' (the test lib uses unset variables internally)"
  elif grep -Eq '^[[:space:]]*set[[:space:]]+-e[[:space:]]*$' "$TEST_SH"; then
    pass "test.sh has 'set -e'"
  else
    fail "test.sh is missing 'set -e'"
  fi

  if grep -q "source dev-container-features-test-lib" "$TEST_SH"; then
    pass "test.sh sources dev-container-features-test-lib"
  else
    fail "test.sh must source dev-container-features-test-lib"
  fi

  if grep -q "reportResults" "$TEST_SH"; then
    pass "test.sh calls reportResults"
  else
    fail "test.sh is missing a reportResults call"
  fi
fi

# ── scenarios.json structural checks ─────────────────────────────────────────

if [[ -f "$SCENARIOS_FILE" ]]; then
  if node -e "
    const j = JSON.parse(require('fs').readFileSync('${SCENARIOS_FILE}', 'utf8'));
    if (!j || typeof j !== 'object' || Array.isArray(j)) process.exit(1);
  " 2>/dev/null; then
    pass "scenarios.json is a valid object"
  else
    fail "scenarios.json must be a JSON object (not an array or primitive) — keys are scenario names"
  fi

  # Verify each scenario key has a matching .sh assertion script
  SCENARIO_KEYS=$(node -e "
    const j = JSON.parse(require('fs').readFileSync('${SCENARIOS_FILE}', 'utf8'));
    process.stdout.write(Object.keys(j).join('\n'));
  " 2>/dev/null)
  while IFS= read -r key; do
    [[ -z "$key" ]] && continue
    SCENARIO_SH="${TEST_DIR}/${key}.sh"
    if [[ -f "$SCENARIO_SH" ]]; then
      pass "scenario '${key}' has assertion script: test/${ID}/${key}.sh"
    else
      fail "scenario '${key}' is missing assertion script: test/${ID}/${key}.sh"
    fi
  done <<< "$SCENARIO_KEYS"
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
