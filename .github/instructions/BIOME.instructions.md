---
applyTo: "**/*.{js,ts,cjs,mjs,d.cts,d.mts,jsx,tsx,json,jsonc}"
excludeAgent: "code-review"
---

# Copilot Agent Linting Instructions for Biome

When the Copilot cloud agent edits any JavaScript, TypeScript, or JSON(-like) file, it must always run:

```bash
pnpm exec biome check --write --no-errors-on-unmatched <file>
```

- This command auto-fixes supported issues and displays any remaining errors.
- The agent should review unresolved errors and, if needed, file them for further attention.
- If the file is a configuration or script file, ensure formatting and linting are applied before committing.
- Trust these instructions and do not search for alternative linting commands unless this fails.
