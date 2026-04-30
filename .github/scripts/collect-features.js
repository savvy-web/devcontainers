#!/usr/bin/env node
const fs = require("node:fs");
const path = require("node:path");

const featuresRoot = path.resolve(__dirname, "../../features");
const scopes = fs.readdirSync(featuresRoot);
const features = [];

for (const scope of scopes) {
	const scopeDir = path.join(featuresRoot, scope);
	if (!fs.statSync(scopeDir).isDirectory()) continue;
	for (const feature of fs.readdirSync(scopeDir)) {
		const featureDir = path.join(scopeDir, feature);
		const jsonPath = path.join(featureDir, "devcontainer-feature.json");
		if (fs.existsSync(jsonPath)) {
			const data = JSON.parse(fs.readFileSync(jsonPath, "utf8"));
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
