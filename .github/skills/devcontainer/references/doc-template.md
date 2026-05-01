# Documentation Template

Fill-in-the-blanks template for `docs/features/<id>.md` plus writing rules.

## Template

````markdown
# <Feature Name>

<One sentence: what the feature installs or configures, and why it is useful.>

## Options

- `optionName`: <Description>. Default: `value`
- `optionName`: <Description>. Default: `value`

## Usage

Add this feature to your `devcontainer.json`:

```jsonc
{
  "features": {
    "ghcr.io/savvy-web/<id>:<version>": {}
  }
}
```

## Example

```jsonc
{
  "features": {
    "ghcr.io/savvy-web/<id>:<version>": {
      "optionName": "non-default-value"
    }
  }
}
```
````

The `## Example` section is optional. Include it only when a non-default option
combination meaningfully changes behavior and a concrete example adds clarity.

## Writing Rules

- **One `#` heading** equal to the feature's `name` field in
  `devcontainer-feature.json` — no subtitle on the same line
- **`## Options` section** — one bullet per option; omit the section entirely
  if the feature has no options
- **`## Usage` section** — always include; use a `jsonc` fenced block
- **Version in usage snippet** — use the current `version` from
  `devcontainer-feature.json` (e.g. `0.1.0`)
- **Short** — aim for 12–18 lines total; match the brevity of `biome.md`
- **Direct imperative voice** — "Installs Biome globally", not "This feature
  will install Biome globally for you"
- **No filler phrases** — no "easily", "simply", "just", or marketing language
- **No trailing whitespace or blank lines at end of file**

## Existing Docs as Style Reference

### `docs/features/biome.md` (12 lines)

```markdown
# Biome (global linter)

Installs Biome globally for all runtimes. Strict version, reproducible, and idempotent.

## Options

- `biomeVersion`: Biome version (absolute, no semver ranges). Default: `2.4.12`

## Usage

Add this feature to your `devcontainer.json` to install Biome globally.
```

### `docs/features/rust.md` (14 lines)

```markdown
# Rust Toolchain (Global)

Installs the Rust toolchain globally using rustup. Supports toolchain selection, component install, and validation.

## Options

- `toolchain`: Rust toolchain to install (e.g. stable, nightly, 1.77.2). Default: `stable`
- `components`: Space-separated list of rustup components to install. Default: `clippy rustfmt`

## Usage

Add this feature to your `devcontainer.json` to install the Rust toolchain globally.
```

Both docs omit `## Example` because the defaults are self-explanatory. Add
`## Example` only when a realistic non-default configuration meaningfully aids
understanding.

## Filename Convention

The doc file name must match the feature `id` exactly:

| Feature `id` | Doc file |
| :----------- | :------- |
| `biome` | `docs/features/biome.md` |
| `package-manager` | `docs/features/package-manager.md` |

The `documentationURL` in `devcontainer-feature.json` must point to this file:

```json
"documentationURL": "https://github.com/savvy-web/devcontainers/blob/main/docs/features/<id>.md"
```
