#!/usr/bin/env node
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { join, resolve } from "node:path";

const featuresRoot = resolve(import.meta.dirname, "../../features");
const scopes = readdirSync(featuresRoot);
const features = [];

for (const scope of scopes) {
	const scopeDir = join(featuresRoot, scope);
	if (!statSync(scopeDir).isDirectory()) continue;
	for (const feature of readdirSync(scopeDir)) {
		const featureDir = join(scopeDir, feature);
		const jsonPath = join(featureDir, "devcontainer-feature.json");
		if (existsSync(jsonPath)) {
			const data = JSON.parse(readFileSync(jsonPath, "utf8"));
			features.push({
				id: data.id,
				version: data.version,
				path: featureDir,
				scope,
				jsonPath,
			});
		}
	}
}

// Output as JSON array for GitHub Actions matrix
process.stdout.write(JSON.stringify(features));
