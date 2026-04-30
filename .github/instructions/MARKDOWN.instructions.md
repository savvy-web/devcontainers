---
applyTo: "**/*.md"
excludeAgent: "code-review"
---

# Copilot Agent Linting Instructions for Markdown

When the Copilot cloud agent edits any Markdown file (`*.md`), it must always run:

```bash
pnpm exec markdownlint-cli2 <file> --config './lib/configs/.markdownlint-cli2.jsonc' --fix
```

- This command auto-fixes Markdown issues and displays any remaining errors.
- The agent should review unresolved errors and, if needed, file them for further attention.
- Trust these instructions and do not search for alternative linting commands unless this fails.
