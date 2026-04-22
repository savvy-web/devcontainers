<!-- TODO: Rewrite this file for your package. See the lint-staged repo for a
     good example: https://github.com/savvy-web/lint-staged/blob/main/CONTRIBUTING.md -->

# Contributing

Thank you for your interest in contributing to `@savvy-web/pnpm-module-template`!
This document provides guidelines and instructions for development.

## Using This Template

1. Click **Use this template** on GitHub to create a new repository
2. Update `name`, `description`, `homepage`, and `repository` in `package.json`
3. Replace the demo code in `src/lib/` with your implementation
4. Update `README.md` and `CONTRIBUTING.md` for your package
5. Run `pnpm install && pnpm test` to verify everything works

## Prerequisites

- Node.js 24+
- pnpm 10+

## Development Setup

```bash
# Clone the repository
git clone https://github.com/savvy-web/pnpm-module-template.git
cd pnpm-module-template

# Install dependencies
pnpm install

# Build the package
pnpm run build

# Run tests
pnpm run test
```

## Project Structure

```text
pnpm-module-template/
├── src/                            # Source code
│   ├── index.ts                    # Entry point — re-exports public API
│   └── lib/                        # Implementation code
├── __test__/                       # All test files
│   ├── lib/                        # Mirrors src/lib/ structure
│   └── utils/                      # Shared test helpers (excluded from discovery)
├── lib/
│   └── configs/                    # Shared configuration files
└── dist/                           # Build output
    ├── dev/                        # Development build
    └── npm/                        # Production build for npm
```

## Available Scripts

| Script | Description |
| --- | --- |
| `pnpm run build` | Build all outputs (dev + prod) |
| `pnpm run build:dev` | Build development output only |
| `pnpm run build:prod` | Build production output only |
| `pnpm run test` | Run all tests with coverage |
| `pnpm run test:watch` | Run tests in watch mode |
| `pnpm run lint` | Check code with Biome |
| `pnpm run lint:fix` | Auto-fix lint issues |
| `pnpm run lint:md` | Check markdown with markdownlint |
| `pnpm run typecheck` | Type-check with tsgo |

To run a specific test file:

```bash
pnpm vitest run __test__/index.test.ts
```

## Code Quality

This project uses:

- **Biome** for linting and formatting
- **Commitlint** for enforcing conventional commits
- **Husky** for Git hooks
- **markdownlint-cli2** for markdown linting
- **tsgo** (native TypeScript) for type checking

### Commit Format

All commits must follow the [Conventional Commits](https://conventionalcommits.org)
specification and include a DCO signoff:

```text
feat: add new feature

Signed-off-by: Your Name <your.email@example.com>
```

### Pre-commit Hooks

The following checks run automatically:

- **pre-commit**: Runs lint-staged
- **commit-msg**: Validates commit message format
- **pre-push**: Runs tests

## Testing

Tests use [Vitest](https://vitest.dev) with v8 coverage configured via
`@savvy-web/vitest`.

```bash
# Run all tests
pnpm run test

# Run tests in watch mode
pnpm run test:watch

# Run a specific test file
pnpm vitest run __test__/index.test.ts

# Run tests matching a pattern
pnpm vitest run -t "Greeter"
```

Test files are classified by suffix:

| Suffix | Kind |
| --- | --- |
| `.test.ts` | unit |
| `.e2e.test.ts` | e2e |
| `.int.test.ts` | integration |

## TypeScript

- Uses `tsgo` (native TypeScript) for type checking
- Strict mode enabled
- Import extensions required (`.js` for ESM)

### Import Conventions

```typescript
// Use .js extensions for relative imports (ESM requirement)
import { myFunction } from "./lib/helpers.js";

// Use node: protocol for Node.js built-ins
import { readFileSync } from "node:fs";

// Separate type imports from value imports
import type { MyType } from "./lib/types.js";
import { MyClass } from "./lib/types.js";
```

### TSDoc Requirements

All exported classes, functions, and interfaces must have TSDoc documentation.
See `src/lib/greeter.ts` for a complete example demonstrating:

- `@public` / `@internal` API boundary markers
- `@remarks` and `@privateRemarks` for detailed context
- `@link` and `@see` for cross-references
- `@example` blocks with complete, importable TypeScript programs

## Submitting Changes

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Make your changes
4. Run tests: `pnpm run test`
5. Run linting: `pnpm run lint:fix`
6. Commit with conventional format and DCO signoff
7. Push and open a pull request

## License

By contributing, you agree that your contributions will be licensed under the
MIT License.
