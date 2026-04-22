# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Project Status

This is a **base template repository** for a single Node.js package. The
design documentation system (`.claude/` skills and agents) is included but
no design docs exist yet. To begin planning and documenting architecture
decisions, run `/design-init` to create your first design document.

## Claude Code Plugins

This repo has several Claude Code plugins pre-installed:

- **workflow@savvy-web-claude-tools** — Provides workflow skills and
  agents that guide you through linting, testing, typechecking, and
  other common tasks using the integrated toolchain. Prefer its
  commands over running tools manually.
- **changesets@savvy-web-systems** — Skills and agents for creating
  and managing changesets. See [Releases](#releases-changesets).
- **vitest-agent-reporter@spencerbeggs** — MCP tools for running and
  querying test results. See [MCP Tools](#mcp-tools-vitest-agent-reporter).

## Architecture

### Single Package

This is **not a monorepo**. The root `package.json` is the published
package. pnpm workspaces is configured with `packages: ["."]` to enable
the `@savvy-web/vitest` discovery pipeline and Turbo task orchestration
on the root package.

- **Package Manager**: pnpm with workspaces (single root package)
- **Build Orchestration**: Turbo for caching and task dependencies
- **Shared Configs**: Located in `lib/configs/`

### Build Pipeline

Rslib with dual output via `@savvy-web/rslib-builder`:

1. `dist/dev/` — Development build with source maps (used for local linking)
2. `dist/npm/` — Production build for npm publishing

The source `package.json` has `"private": true` — the builder transforms
this during build based on `publishConfig.access`. Do not remove it.

### Task Orchestration (Turborepo)

Turborepo orchestrates build, typecheck, and test tasks via
`turbo.json`. It handles caching, task dependencies, and
parallelization. Run tasks through pnpm scripts (e.g.
`pnpm run build`), which delegate to `turbo run` under the hood.

Task dependencies: `build:dev` and `build:prod` depend on
`types:check` completing first.

### Code Quality

- **Biome**: Unified linting and formatting (replaces ESLint + Prettier).
  Config extends `@savvy-web/lint-staged/biome/silk.jsonc`.
- **Husky** hooks integrate with the tools below.

### Git Hooks (Husky + lint-staged + commitlint)

Husky runs three hooks via `@savvy-web/lint-staged` and
`@savvy-web/commitlint`:

- **pre-commit**: `@savvy-web/lint-staged` runs Biome (format + lint),
  markdownlint, package.json sorting, and shell script permission
  checks on staged files. Failures block the commit.
- **commit-msg**: `@savvy-web/commitlint` validates conventional commit
  format with DCO signoff. Uses auto-detection for workspace scopes.
- **post-checkout / post-merge**: Ensures shell script permissions.

Valid commit types: `feat`, `fix`, `chore`, `docs`, `ci`, `build`,
`test`, `refactor`, `perf`, `style`, `revert`, `ai`, `release`.

All commits require DCO signoff:
`Signed-off-by: Name <email>`

### Releases (changesets)

Versioning and changelogs are managed by `@savvy-web/changesets`.
Changesets are markdown files in `.changeset/` that describe
user-facing changes. The CI release workflow consumes them to bump
versions, update `CHANGELOG.md`, and publish.

The `@savvy-web/changesets` Claude Code plugin is pre-installed. Use
its skills and agents (e.g. `/changeset`) to create, validate, and
manage changesets — do not write them manually. Each changeset
specifies a bump type (patch, minor, major) and organizes content
under section headings (Features, Bug Fixes, Breaking Changes, etc.).

### TypeScript Configuration

- Strict mode enabled
- Import extensions required (`.js` for ESM)
- `node:` protocol for Node.js built-ins
- Separate type imports: `import type { Foo } from './bar.js'`

### Source Structure

```text
src/
  index.ts          # Entry point — re-exports public API
  lib/              # Implementation code lives here
    greeter.ts      # Example module
```

`src/index.ts` is the sole entry point. It re-exports the minimal set
of types and values that consumers need. Avoid re-exporting entire
modules — be explicit about what is public.

Implementation code lives in `src/lib/`. The entry point imports from
`src/lib/` and re-exports only the public surface.

### Documentation (TSDoc + API Extractor)

`@savvy-web/rslib-builder` generates API documentation via API Extractor.
Write robust TSDoc comments to produce accurate docs.

**Rules:**

- Only entry points (`src/index.ts`) use `@packageDocumentation`.
- Mark items `@public` or `@internal` to define the public/private API
  boundary. API Extractor uses these to generate separate doc rollups.
- Use `@remarks` for detailed explanations beyond the summary line.
- Use `@privateRemarks` for gotchas, hacks, and implementation notes
  that developers and agents may stumble upon (stripped from output).
- Use `@link` and `@see` to cross-reference between entities.
- Use `@example` blocks with complete TypeScript programs. Each example
  must import all values and types it uses. Import types and values
  separately:

```typescript
/**
 * @example Basic usage
 * ```typescript
 * import type { Greeting } from "@savvy-web/pnpm-module-template";
 * import { Greeter } from "@savvy-web/pnpm-module-template";
 *
 * const greeter = new Greeter();
 * const result: Greeting = greeter.greet("World");
 * ```
 */
```

## Testing

### Framework

Vitest with v8 coverage, configured via `@savvy-web/vitest`. The
`vitest.config.ts` calls `VitestConfig.create()` which auto-discovers
the package, classifies test files by filename convention, and injects
`vitest-agent-reporter` for structured agent output.

### Directory Structure

```text
__test__/             # All test files
  index.test.ts       # Tests for the public API (src/index.ts)
  lib/                # Mirrors src/lib/ structure
    greeter.test.ts   # Tests for internal implementation
  utils/              # Excluded from discovery — shared helpers
    mocks.ts          # Test mocks and stubs
    test-types.ts     # Shared type definitions for tests
vitest.setup.ts       # Global test setup (auto-detected)
vitest.config.ts      # VitestConfig.create() — zero config
```

Tests live in `__test__/` (not `src/`). The `__test__/utils/` directory
is automatically excluded from test discovery — use it for shared mocks,
fixtures, and type helpers.

### Test File Classification

Classification is based entirely on the filename suffix, not directory:

| Suffix | Kind | Example |
| :--- | :--- | :--- |
| `.test.ts` | unit | `__test__/parser.test.ts` |
| `.e2e.test.ts` | e2e | `__test__/api.e2e.test.ts` |
| `.int.test.ts` | integration | `__test__/db.int.test.ts` |

When a package has only one test kind, the project name is the bare
package name. When multiple kinds exist, suffixes are added
(`:unit`, `:e2e`, `:int`).

### Coverage

Always enabled with v8. Thresholds default to `"strict"`:
lines 80, branches 75, functions 80, statements 80.

### MCP Tools (vitest-agent-reporter)

The `vitest-agent-reporter` plugin provides MCP tools for test
interaction. **Prefer these over raw `pnpm vitest` commands** — they
return structured data and persist results to a local SQLite database
for history tracking.

#### Running Tests

Use `run_tests` to execute tests. It accepts optional `files` and
`project` filters:

- Run all tests: `run_tests()`
- Run one file: `run_tests({ files: ["__test__/index.test.ts"] })`
- Run one project: `run_tests({ project: "@scope/pkg:unit" })`

#### Checking Status (no re-run)

Use these tools to query the last run without re-executing tests:

- `test_status` — one-line pass/fail per project (quick heartbeat)
- `test_overview` — pass/fail/skip counts per project
- `test_errors` — detailed errors with diffs and stack traces for a
  project (requires `project` param)

#### Coverage and Trends

- `test_coverage` — coverage gap analysis against thresholds
- `test_trends` — per-metric coverage trajectory with sparklines
  (requires `project` param)

#### History and Debugging

- `test_history` — flaky, persistent, and recovered test
  classifications (requires `project` param)
- `test_for_file` — find which test modules cover a source file

#### Workflow

1. **After writing code:** call `run_tests()` to validate
2. **On failure:** call `test_errors({ project: "..." })` for diffs
3. **After fixing:** call `run_tests()` again to confirm
4. **Before finishing:** call `test_coverage()` to check for gaps
5. **When investigating flakiness:** call `test_history({ project: "..." })`

Do not parse test output manually — use the MCP tools to query
structured results from the database.

## Publishing

Publishes to both GitHub Packages and npm with provenance.
See [Releases (changesets)](#releases-changesets) for the versioning
workflow.
