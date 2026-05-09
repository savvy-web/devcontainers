# Savvy Web Devcontainer Features

Composable [devcontainer features](https://containers.dev/implementors/features/) for Savvy Web repositories. Designed for use with GitHub Codespaces, VS Code Dev Containers, and local Docker environments.

Features are published to the GitHub Container Registry at `ghcr.io/savvy-web/features/<id>`.

## Features

| Feature | Description | Docs |
| ------- | ----------- | ---- |
| `bats` | Installs bats-core, bats-support, bats-assert, and bats-mock for shell script testing | [docs](docs/features/bats.md) |
| `biome` | Installs [Biome](https://biomejs.dev) globally for linting and formatting | [docs](docs/features/biome.md) |
| `claude-code` | Installs the [Claude Code](https://code.claude.com) CLI agent | [docs](docs/features/claude-code.md) |
| `homebrew` | Installs [Homebrew](https://brew.sh) (macOS/Linux) | [docs](docs/features/homebrew.md) |
| `kcov` | Installs [kcov](https://github.com/SimonKagstrom/kcov) (macOS/Linux) | [docs](docs/features/kcov.md) |
| `node` | Installs the Node.js runtime | [docs](docs/features/node.md) |
| `package-manager` | Installs a Node.js package manager (pnpm, yarn, npm) via corepack | [docs](docs/features/package-manager.md) |
| `rust` | Installs the Rust toolchain via rustup | [docs](docs/features/rust.md) |
| `zig` | Installs the [Zig](https://ziglang.org) compiler | [docs](docs/features/zig.md) |

## Usage

Reference a feature in your `devcontainer.json`:

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/savvy-web/biome:0.1.0": {},
    "ghcr.io/savvy-web/node:0.3.0": {},
    "ghcr.io/savvy-web/package-manager:0.1.0": {
      "packageManager": "pnpm@10.33.2"
    }
  }
}
```

Each feature's doc page lists all available options.

## Repository Structure

Features and tests use a flat layout — one directory per feature id. Inter-
feature ordering is expressed via `installsAfter` in
`devcontainer-feature.json`, not via directory scopes.

```text
src/
  <id>/       # one directory per feature, named by feature id

test/
  <id>/       # mirrors src/<id> — test.sh + scenarios.json

docs/
  features/   # one markdown file per feature

scripts/
  test-feature.sh   # run a single feature test locally

.github/
  workflows/
    test.yml                  # CI — runs all feature tests on PRs
    test-feature.yml          # CI — manual single-feature test (workflow_dispatch)
    publish-features.yml      # publishes new/changed features to ghcr.io
```

## Local Feature Testing

Run a feature's scenarios locally without pushing to CI.

**Prerequisites:** Docker running and `@devcontainers/cli` installed globally.

```bash
pnpm add -g @devcontainers/cli
```

Test each feature by its name:

```bash
pnpm feature:test biome
pnpm feature:test rust
pnpm feature:test package-manager

# No argument prints available features
pnpm run feature:test
```

### How it works

`pnpm feature:test` runs `lib/scripts/test-feature.sh`, which delegates to
`.github/scripts/test-feature-isolated.sh`. That script copies `src/` and
`test/` to a scratch directory, strips `ghcr.io/savvy-web/features/*` entries
from `installsAfter` in the manifest copies — the devcontainer CLI rejects
3-segment OCI references it cannot resolve, and our scenarios install
features in isolation anyway — then runs `devcontainer features test -f <id>`
against the scratch tree.

## Contributing

See **[CONTRIBUTING.md](CONTRIBUTING.md)** for development setup, feature authoring conventions and how to submit changes.

## License

[MIT](LICENSE)
