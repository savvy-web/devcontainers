# Global Features

Language-agnostic devcontainer features. These features install tools that are
useful across any runtime or stack.

| Feature | Description | Published |
| :------ | :---------- | :-------- |
| [`act`](../../docs/features/act.md) | Installs act by nektos for running GitHub Actions workflows locally with Docker. | `ghcr.io/savvy-web/act` |
| [`biome`](../../docs/features/biome.md) | Installs Biome globally for all runtimes. Strict version, reproducible, and idempotent. | `ghcr.io/savvy-web/biome` |
| [`claude-code`](../../docs/features/claude-code-global.md) | Installs the Claude Code CLI agent globally using the official native installer. | `ghcr.io/savvy-web/claude-code` |
| [`homebrew`](../../docs/features/homebrew.md) | Installs Homebrew (macOS/Linux) globally. Skips if already installed. | `ghcr.io/savvy-web/homebrew` |
| [`outbound-firewall`](../../docs/features/outbound-firewall.md) | Configures outbound firewall rules for Codespaces and devcontainers. Linux only. | `ghcr.io/savvy-web/outbound-firewall` |
| [`rust`](../../docs/features/rust.md) | Installs the Rust toolchain globally using rustup. | `ghcr.io/savvy-web/rust` |
| [`zig`](../../docs/features/zig.md) | Installs the Zig compiler globally from the official release archive. | `ghcr.io/savvy-web/zig` |

## Adding a New Global Feature

Place new language-agnostic tool features in this directory:

```text
features/global/<id>/
  devcontainer-feature.json
  install.sh
```

Use the `new-feature` Copilot skill to scaffold all five required files at
once: `devcontainer-feature.json`, `install.sh`, `test.sh`, `scenarios.json`,
and `docs/features/<id>.md`.
