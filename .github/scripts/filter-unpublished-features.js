#!/usr/bin/env node
import { execSync } from "node:child_process";

const org = process.env.GITHUB_REPOSITORY_OWNER || "savvy-web";

// Read features JSON from stdin
let input = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => {
	input += chunk;
});
process.stdin.on("end", () => {
	const features = JSON.parse(input);
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
	process.stdout.write(JSON.stringify(filtered));
});
if (process.stdin.isTTY) {
	// If no stdin, exit with error
	console.error("No input provided on stdin");
	process.exit(1);
}
