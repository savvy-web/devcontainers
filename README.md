# Savvy Web Devcontainer Features

Composable [devcontainer features](https://containers.dev/implementors/features/)
for Savvy Web repositories. Designed for use with GitHub Codespaces, VS Code
Dev Containers, and local Docker environments.

Features are published to the GitHub Container Registry at
`ghcr.io/savvy-web/<id>`.

## Features

| Feature | Description | Docs |
| ------- | ----------- | ---- |
| `act` | Installs [act](https://nektosact.com) for running GitHub Actions locally | [docs](docs/features/act.md) |
| `biome` | Installs [Biome](https://biomejs.dev) globally for linting and formatting | [docs](docs/features/biome.md) |
| `claude-code` | Installs the [Claude Code](https://code.claude.com) CLI agent | [docs](docs/features/claude-code.md) |
| `homebrew` | Installs [Homebrew](https://brew.sh) (macOS/Linux) | [docs](docs/features/homebrew.md) |
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
    test.yml              # CI — runs all feature tests on PRs
    test-feature.yml      # CI — run one feature (used by act)
    publish.yml           # publishes new/changed features to ghcr.io
```

## Local Feature Testing

Use [act](https://nektosact.com) to run a feature's install and test
scripts locally without pushing to CI.

**Prerequisites:** Docker running, `act` installed (or add the `act`
feature to your own devcontainer).

```bash
pnpm run feature:test biome
pnpm run feature:test rust
pnpm run feature:test package-manager

# No argument prints available features
pnpm run feature:test
```

`lib/scripts/test-feature.sh` calls `act workflow_dispatch` against
`.github/workflows/test-feature.yml`, which installs the feature and
runs its `test.sh` inside a fresh Ubuntu container. The `.actrc` at the
repo root configures act to use a slim ubuntu image and bind-mount the
local workspace.

## Contributing

See **[CONTRIBUTING.md](CONTRIBUTING.md)** for development setup,
feature authoring conventions, and how to submit changes.

## License

[MIT](./LICENSE)
