#!/usr/bin/env node
import { execSync } from "node:child_process";
import { readFileSync } from "node:fs";

const org = process.env.GITHUB_REPOSITORY_OWNER || "savvy-web";
const features = JSON.parse(readFileSync(process.argv[2], "utf8"));
const filtered = [];

for (const feature of features) {
	const image = `ghcr.io/${org}/${feature.id}:${feature.version}`;
	try {
		execSync(`docker manifest inspect ${image}`, { stdio: "ignore" });
		// Exists, skip
	} catch {
		// Not found, needs publish
		filtered.push(feature);
	}
}

fs.writeFileSync(process.argv[3], JSON.stringify(filtered));
