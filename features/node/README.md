# Node Features

Node.js ecosystem devcontainer features. These features install tools specific
to the Node.js runtime, package management, or JavaScript/TypeScript toolchains.

| Feature | Description | Published |
| :------ | :---------- | :-------- |
| [`node-pnpm`](../../docs/features/node-pnpm.md) | Installs Node.js and pnpm with strict, reproducible versions for CI and Codespaces. | `ghcr.io/savvy-web/node-pnpm` |

## Adding a New Node Feature

Place new Node.js ecosystem tool features in this directory:

```text
features/node/<id>/
  devcontainer-feature.json
  install.sh
```

Use the `new-feature` Copilot skill to scaffold all five required files at
once: `devcontainer-feature.json`, `install.sh`, `test.sh`, `scenarios.json`,
and `docs/features/<id>.md`.

## Scope Rule

A feature belongs in `features/node/` when it:

- Requires Node.js to already be installed (use `installsAfter` to declare
  this dependency)
- Installs a Node.js-specific package manager, runtime wrapper, or toolchain
  component
- Is meaningless outside of a Node.js development environment

If the tool is useful in non-Node.js projects, place it in `features/global/`
instead.
