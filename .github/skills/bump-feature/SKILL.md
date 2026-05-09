---
name: bump-feature
allowed-tools: read_file, write_file, list_files
description: >-
  Use when asked to bump the version of a devcontainer feature. Triggers for
  prompts like "bump version for X", "release a new version of the X feature",
  "update the X feature version", or "the X feature changed and needs a
  version bump".
---

# Bump Devcontainer Feature Version

Bumps a feature version atomically — ensuring that every place the version or
pinned default appears is updated together. A partial bump causes the publish
workflow to either skip the feature or publish it with mismatched metadata.

## When to Use

Bump the feature version whenever:

- The install script behavior changes (new tool version default, new option,
  changed download URL)
- The feature options change (new option added, option default changed)
- A bug in `install.sh` is fixed
- The `devcontainer-feature.json` metadata changes (name, description,
  `installsAfter`, `platforms`, `customizations`)

**Do not** bump the version for:

- Changes to `test.sh` that don't affect feature behavior
- Changes to `src/<id>/README.md` that don't reflect a behavior change
- Formatting or comment-only changes to `install.sh`

## Workflow

### Step 1 — Check whether a bump is actually needed

Read `src/<id>/devcontainer-feature.json` to find the current version (e.g.
`0.2.0`). Then check whether that version already exists in the OCI registry:

```bash
docker manifest inspect ghcr.io/savvy-web/features/<id>:<version> 2>/dev/null \
  && echo "published" || echo "not published"
```

**If "not published":** the feature already has a pending (unreleased) version
bump. **Do not bump again** — add your changes on top of the existing version.
A second bump would create a version gap in the published history and waste a
registry slot.

**If "published":** the current version is live. Proceed with the bump.

### Step 2 — Identify the feature

Ask the user which feature to bump if not already specified.

### Step 3 — Determine the new version

Apply standard semver rules:

| Change type | Bump | Example |
| :---------- | :--- | :------ |
| Bug fix in `install.sh`, no behavior change | `patch` | `0.1.0` → `0.1.1` |
| New option added (backward-compatible) | `minor` | `0.1.0` → `0.2.0` |
| Option removed, renamed, or semantics changed | `major` | `0.1.0` → `1.0.0` |
| Default version of installed tool updated | `patch` | `0.1.0` → `0.1.1` |

If the feature is pre-1.0 (`0.x.y`), breaking changes may use `minor` instead
of `major` at the author's discretion — document the decision.

Confirm the new version with the user before proceeding.

### Step 4 — Update all version references

Update every file that contains the old version. The full set to check:

#### `src/<id>/devcontainer-feature.json`

Update the `"version"` field:

```json
"version": "<new-version>"
```

#### `test/<id>/test.sh`

Update any `grep "<old-version>"` assertions that check the pinned default
tool version. Only update the version being bumped — leave other version
strings alone.

#### `test/<id>/scenarios.json`

Update step descriptions that mention the old version string.

#### `src/<id>/README.md`

Update the options table default value and the version in the example usage
block:

```json
"ghcr.io/savvy-web/features/<id>:<major>": {}
```

Only the major version appears in the usage block (e.g. `0` from `0.2.0`).

### Step 5 — Update `install.sh` defaults (when the pinned tool version changed)

If the reason for the bump is a new pinned tool version (e.g. Biome `2.4.12` →
`2.5.0`), update the option default in `devcontainer-feature.json`:

```json
"biomeVersion": {
  "type": "string",
  "default": "2.5.0",
  ...
}
```

This default flows into `test.sh` assertions and the README — update them too.

### Step 6 — Verify consistency

After all edits, run a final consistency check:

1. `version` in `devcontainer-feature.json` matches the new version
2. All `grep "<version>"` assertions in `test.sh` use the new pinned defaults
3. `src/<id>/README.md` options table reflects the new default
4. `documentationURL` still points to `src/<id>/README.md` (it should never change)

Run the validation script to catch anything missed:

```bash
pnpm run feature:validate <id>
```

## Completion Checklist

- [ ] Checked registry — current version is published (bump is needed)
- [ ] `devcontainer-feature.json` `"version"` updated
- [ ] `test/<id>/test.sh` version assertions updated (if tool default changed)
- [ ] `test/<id>/scenarios.json` step descriptions updated (if version mentioned)
- [ ] `src/<id>/README.md` options table and usage snippet updated
- [ ] `install.sh` option defaults updated (if pinned tool version changed)
- [ ] `pnpm run feature:validate <id>` passes

## Common Mistakes

- **Bumping when version is already pending** — if `devcontainer-feature.json`
  says `0.2.0` but the registry only has `0.1.0`, a bump to `0.3.0` creates a
  version gap. Always check the registry first.
- **Bumping version but not test assertions** — if you changed the default
  Biome version from `2.4.12` to `2.5.0` but left `grep "2.4.12"` in
  `test.sh`, the test will fail on the new default
- **Not bumping version after changing install behavior** — the publish
  workflow skips features whose `id:version` image already exists in the
  registry. If the version is not bumped, the change will never be published
- **Forgetting the README options table** — the `## Options` table in
  `src/<id>/README.md` lists default values; if not updated, users will see
  stale defaults in the generated documentation
