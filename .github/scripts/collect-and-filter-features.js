#!/usr/bin/env node
import { execSync } from "node:child_process";
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { join, resolve } from "node:path";

const org = process.env.GITHUB_REPOSITORY_OWNER || "savvy-web";
const featuresRoot = resolve(import.meta.dirname, "../../features");
const results = [];

for (const feature of readdirSync(featuresRoot)) {
	const featureDir = join(featuresRoot, feature);
	if (!statSync(featureDir).isDirectory()) continue;
	const jsonPath = join(featureDir, "devcontainer-feature.json");
	if (!existsSync(jsonPath)) continue;

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
	results.push({ id, version, path: featureDir, publish, reason });
}

// Output filtered matrix for GitHub Actions
const filtered = results.filter((r) => r.publish);
process.stdout.write(JSON.stringify(filtered));

// Write markdown summary for GitHub Actions
if (process.env.GITHUB_STEP_SUMMARY) {
	const lines = [
		`| Feature | Version | Publish? | Reason |`,
		`|---------|---------|----------|--------|`,
		...results.map((r) => `| ${r.id} | ${r.version} | ${r.publish ? "✅" : "❌"} | ${r.reason} |`),
	];
	import("node:fs").then((fs) => {
		fs.writeFileSync(process.env.GITHUB_STEP_SUMMARY, lines.join("\n"));
	});
}
