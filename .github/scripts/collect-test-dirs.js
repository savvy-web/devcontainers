#!/usr/bin/env node
// Discovers all devcontainer test directories under test/ and outputs them
// as a JSON array for use as a GitHub Actions matrix.
//
// Usage: node .github/scripts/collect-test-dirs.js
// Output: JSON array of { scope, id, testdir } objects

import { existsSync, readdirSync, statSync } from "node:fs";
import { join, resolve } from "node:path";

const testRoot = resolve(import.meta.dirname, "../../test");

if (!existsSync(testRoot)) {
	process.stdout.write("[]");
	process.exit(0);
}

const entries = [];

for (const scope of readdirSync(testRoot)) {
	const scopeDir = join(testRoot, scope);
	if (!statSync(scopeDir).isDirectory()) continue;

	for (const id of readdirSync(scopeDir)) {
		const idDir = join(scopeDir, id);
		if (!statSync(idDir).isDirectory()) continue;

		const testSh = join(idDir, "test.sh");
		if (existsSync(testSh)) {
			entries.push({
				scope,
				id,
				testdir: `test/${scope}/${id}`,
			});
		}
	}
}

process.stdout.write(JSON.stringify(entries));
