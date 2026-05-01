# Copilot Instructions

## Commit Conventions

All commits in this repository are validated by `@savvy-web/commitlint` (Silk preset).

### Format

```text
type(scope): subject

Optional body — plain prose only, max 300 chars per line.

Signed-off-by: Name <email@example.com>
```

### Allowed Types

| Type | When to use |
| :--- | :---------- |
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `docs` | Documentation-only change |
| `style` | Formatting, whitespace — no logic change |
| `refactor` | Code restructuring without behaviour change |
| `perf` | Performance improvement |
| `test` | Adding or updating tests |
| `build` | Build system or dependency changes |
| `ci` | CI/CD workflow changes |
| `chore` | Maintenance tasks (version bumps, configs) |
| `revert` | Reverts a previous commit |
| `release` | Release preparation commit |
| `ai` | AI-generated or AI-assisted change |

### Rules

- **Subject line**: imperative mood, no trailing period, max ~72 chars
- **Body**: optional; plain prose only — no Markdown headers (`##`), no fenced
  code blocks (` ``` `), no bare URLs, no numbered lists
- **Body line length**: max 300 characters per line
- **DCO sign-off**: required on every commit — a `Signed-off-by:` trailer must
  be present because this repository has a `DCO` file and enforces the check in
  CI via `dco.yml`

### DCO Sign-Off

The Developer Certificate of Origin (DCO) certifies that you have the right to
submit your contribution. Add the trailer automatically with:

```bash
git commit -s -m "feat(biome): bump default version to 2.5.0"
```

Or configure git to add it by default:

```bash
git config --global trailer.sign.key "Signed-off-by"
git config --global trailer.sign.ifmissing add
git config --global trailer.sign.ifexists doNothing
git config --global trailer.sign.command 'echo "$(git config user.name) <$(git config user.email)>"'
```

### Examples

```text
feat(biome): bump default version to 2.5.0

Signed-off-by: C. Spencer Beggs <spencer@savvyweb.systems>
```

```text
fix(package-manager): handle missing packageManager field in package.json

When no packageManager field is present and the option is set to 'auto',
the install script now exits cleanly instead of forwarding an empty spec
to corepack.

Signed-off-by: C. Spencer Beggs <spencer@savvyweb.systems>
```

```text
ci: switch feature tests to devcontainer features test CLI

Signed-off-by: C. Spencer Beggs <spencer@savvyweb.systems>
```
