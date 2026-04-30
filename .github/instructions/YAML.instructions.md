---
applyTo: "**/*.{yml,yaml}"
excludeAgent: "code-review"
---

# Copilot Agent Linting Instructions for YAML

When the Copilot cloud agent edits any YAML file (excluding `pnpm-lock.yaml` and `pnpm-workspace.yaml`), it must always run:

```bash
pnpm dlx prettier --write <file>
pnpm dlx yaml-lint <file>
```

- This will format and lint YAML files.
- The agent should review any remaining errors and file them for further attention if needed.
- Trust these instructions and do not search for alternative linting commands unless this fails.
