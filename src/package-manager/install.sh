#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

# Devcontainer features expose option keys as uppercased env vars, so the
# `packageManager` option becomes `PACKAGEMANAGER`.
PACKAGEMANAGER="${PACKAGEMANAGER:-auto}"

# ── Helpers ──────────────────────────────────────────────────────────────────

# Strip leading range operators (^, ~, >=, >, <=, <, =, v) from a version
# string so that corepack receives an exact pin. If the result is empty or
# still contains range syntax, return empty (caller treats as unusable).
strip_range() {
  local v="${1:-}"
  # Remove leading v
  v="${v#v}"
  # Remove leading range operators (^, ~, >=, >, <=, <, =)
  v="${v#^}"
  v="${v#\~}"
  v="${v#>=}"
  v="${v#>}"
  v="${v#<=}"
  v="${v#<}"
  v="${v#=}"
  # Remove leading v again (e.g. ">=v10.33.2")
  v="${v#v}"
  # If what remains contains any non-[0-9.] characters, it's still a range
  if [[ "$v" =~ [^0-9\.] ]]; then
    echo ""
    return
  fi
  echo "$v"
}

# ── Validate the option value ─────────────────────────────────────────────────

if [[ "$PACKAGEMANAGER" == "auto" ]]; then
  : # resolved below
elif [[ "$PACKAGEMANAGER" =~ ^(pnpm|yarn|npm)@[0-9][^[:space:]]*$ ]]; then
  : # valid explicit spec like pnpm@10.33.2 or pnpm@10.33.2+sha512.abc123
else
  echo "[ERROR] PACKAGEMANAGER must be 'auto' or a corepack spec like 'pnpm@10.33.2'" >&2
  echo "        Got: $PACKAGEMANAGER" >&2
  exit 1
fi

# ── Ensure corepack is available ──────────────────────────────────────────────

if ! command -v corepack &>/dev/null; then
  echo "[ERROR] corepack not found on PATH. The 'node' feature must be installed first." >&2
  exit 1
fi

# ── Resolve the package manager spec ──────────────────────────────────────────

PM_SPEC=""

if [[ "$PACKAGEMANAGER" == "auto" ]]; then
  # Search for package.json in likely workspace locations.
  # devcontainer CLI sets CONTAINER_WORKSPACE_FOLDER when the workspace is
  # mounted at install time. Otherwise fall back to /workspaces/<name> (the
  # Codespaces / VS Code convention) and finally the CWD.
  PKG_JSON=""
  for candidate in \
    "${CONTAINER_WORKSPACE_FOLDER:-/dev/null}/package.json" \
    /workspaces/"$(basename "$(pwd)")"/package.json \
    ./package.json; do
    if [[ -f "$candidate" ]]; then
      PKG_JSON="$candidate"
      break
    fi
  done

  if [[ -n "$PKG_JSON" ]]; then
    echo "[INFO] Found package.json at $PKG_JSON"

    # 1. Try devEngines.packageManager (name + version)
    DE_NAME=$(node -e "
      const j = JSON.parse(require('fs').readFileSync('$PKG_JSON','utf8'));
      process.stdout.write(j?.devEngines?.packageManager?.name || '');
    " 2>/dev/null || echo "")
    DE_VERSION=$(node -e "
      const j = JSON.parse(require('fs').readFileSync('$PKG_JSON','utf8'));
      process.stdout.write(j?.devEngines?.packageManager?.version || '');
    " 2>/dev/null || echo "")

    if [[ -n "$DE_NAME" && -n "$DE_VERSION" ]]; then
      EXACT_VERSION="$(strip_range "$DE_VERSION")"
      if [[ -n "$EXACT_VERSION" ]]; then
        PM_SPEC="${DE_NAME}@${EXACT_VERSION}"
        echo "[INFO] Resolved from devEngines.packageManager: $PM_SPEC"
      else
        echo "[INFO] devEngines.packageManager.version '$DE_VERSION' is a range; falling through to top-level packageManager." >&2
      fi
    fi

    # 2. Fall back to top-level "packageManager" field
    if [[ -z "$PM_SPEC" ]]; then
      PM_FIELD=$(node -e "
        const j = JSON.parse(require('fs').readFileSync('$PKG_JSON','utf8'));
        process.stdout.write(j?.packageManager || '');
      " 2>/dev/null || echo "")

      if [[ -n "$PM_FIELD" ]]; then
        # packageManager values look like: pnpm@10.33.2 or pnpm@10.33.2+sha512.abc...
        # The integrity hash (after +) is preserved for corepack verification.
        PM_SPEC="$PM_FIELD"
        echo "[INFO] Resolved from packageManager: $PM_SPEC"
      fi
    fi
  else
    echo "[INFO] No package.json found in workspace; auto-detection skipped."
  fi

  # 3. If nothing resolved, do a soft no-op: enable corepack shims only.
  if [[ -z "$PM_SPEC" ]]; then
    echo "[INFO] auto: no resolvable package manager spec found. Enabling corepack shims only."
    COREPACK_ENABLE_DOWNLOAD_PROMPT=0 corepack enable
    echo "[SUCCESS] corepack shims installed (no specific package manager activated)."
    exit 0
  fi
else
  PM_SPEC="$PACKAGEMANAGER"
fi

# ── Activate the package manager via corepack ──────────────────────────────────

# Disable corepack's interactive download prompt so installs work in
# non-interactive CI / devcontainer builds.
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0

echo "[INFO] Enabling corepack..."
corepack enable

echo "[INFO] Preparing $PM_SPEC..."
corepack prepare "$PM_SPEC" --activate

# ── Validate ──────────────────────────────────────────────────────────────────

# Extract the PM name from the spec (before the @).
PM_NAME="${PM_SPEC%%@*}"

if ! command -v "$PM_NAME" &>/dev/null; then
  echo "[ERROR] $PM_NAME not found on PATH after corepack prepare" >&2
  exit 1
fi

echo "[SUCCESS] Package manager $PM_SPEC installed and activated."
