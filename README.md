# Savvy Web Node.js Module Template

A template repository for bootstrapping single Node.js packages with
the Savvy Web toolchain. Includes a complete build pipeline, testing,
linting, commit validation, and automated releases — ready to go out
of the box.

## What's Included

| Concern | Tool |
| --- | --- |
| Build | [`@savvy-web/rslib-builder`](https://github.com/savvy-web/rslib-builder) — dual dev/npm output via Rslib |
| Testing | [`@savvy-web/vitest`](https://github.com/savvy-web/vitest) — zero-config Vitest with v8 coverage |
| Linting | [`@savvy-web/lint-staged`](https://github.com/savvy-web/lint-staged) — Biome, markdownlint, and more via Husky |
| Commits | [`@savvy-web/commitlint`](https://github.com/savvy-web/commitlint) — conventional commits with DCO signoff |
| Releases | [`@savvy-web/changesets`](https://github.com/savvy-web/changesets) — versioning, changelogs, and dual-registry publishing |
| Tasks | [Turborepo](https://turbo.build) — cached, parallelized task orchestration |

## Prerequisites

- Node.js 24+
- pnpm 10+

## Quick Start

```bash
pnpm install
pnpm test
```

## Documentation

- **[CONTRIBUTING.md](CONTRIBUTING.md)** — Development setup, project
  structure, scripts, and how to submit changes.
- **[CLAUDE.md](CLAUDE.md)** — Detailed architecture and conventions
  for AI-assisted development with Claude Code.

## Copilot Workspace (Cloud Agent) Support

This repository is configured for GitHub Copilot Workspace (cloud agent) with the following files:

- `.copilot/agent.env`: Pins Node.js and pnpm versions for the agent
- `.copilot/agent.yaml`: (Optional) Customizes the agent image and prebuild steps

**Copilot agent environment:**

- Node.js: 24.11.0
- pnpm: 10.20.0

See [GitHub Copilot agent environment docs](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-the-agent-environment) for details.

## License

[MIT](./LICENSE)
