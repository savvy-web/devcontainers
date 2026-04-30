#!/usr/bin/env node
import { execSync } from "node:child_process";
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { join, resolve } from "node:path";

const org = process.env.GITHUB_REPOSITORY_OWNER || "savvy-web";
const featuresRoot = resolve(import.meta.dirname, "../../features");
const scopes = readdirSync(featuresRoot);
const features = [];
const results = [];

for (const scope of scopes) {
	const scopeDir = join(featuresRoot, scope);
	if (!statSync(scopeDir).isDirectory()) continue;
	for (const feature of readdirSync(scopeDir)) {
		const featureDir = join(scopeDir, feature);
		const jsonPath = join(featureDir, "devcontainer-feature.json");
		if (existsSync(jsonPath)) {
			const data = JSON.parse(readFileSync(jsonPath, "utf8"));
			const id = data.id;
			const version = data.version;
			const image = `ghcr.io/${org}/${id}:${version}`;
			let publish = false;
			let reason = "Image does not exist in registry";
			try {
				execSync(`docker manifest inspect ${image}`, { stdio: "ignore" });
				publish = false;
				reason = "Image exists in registry (version unchanged)";
			} catch {
				publish = true;
				reason = "Image does not exist in registry";
			}
			features.push({ id, version, path: featureDir, scope, jsonPath });
			results.push({ id, version, path: featureDir, scope, publish, reason });
		}
	}
}

// Output filtered matrix for GitHub Actions
const filtered = results.filter((r) => r.publish);
process.stdout.write(JSON.stringify(filtered));

// Write markdown summary for GitHub Actions
if (process.env.GITHUB_STEP_SUMMARY) {
	const lines = [
		`| Scope | Feature | Version | Publish? | Reason |`,
		`|-------|---------|---------|----------|--------|`,
		...results.map((r) => `| ${r.scope} | ${r.id} | ${r.version} | ${r.publish ? "✅" : "❌"} | ${r.reason} |`),
	];
	import("node:fs").then((fs) => {
		fs.writeFileSync(process.env.GITHUB_STEP_SUMMARY, lines.join("\n"));
	});
}
