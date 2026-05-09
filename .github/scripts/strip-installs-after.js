#!/usr/bin/env node
// In-place removes any `installsAfter` entries pointing at the savvy-web
// features namespace from a devcontainer-feature.json. The field is deleted
// entirely if the resulting array is empty.
//
// `installsAfter` is purely an ordering hint — it only matters when both
// features are installed together by an end user. The CLI's local test runner
// rejects 3-segment OCI references it cannot resolve, even though our scenario
// definitions install the feature in isolation, so we strip these entries from
// a scratch copy of the manifest before running tests. Other (non-savvy-web)
// `installsAfter` entries are preserved.
//
// Usage:
//   node strip-installs-after.js <path-to-devcontainer-feature.json>
//
// Env:
//   FEATURES_NAMESPACE  Namespace path to strip (default "savvy-web/features").

import { readFileSync, writeFileSync } from "node:fs";

const target = process.argv[2];
if (!target) {
	console.error("Usage: strip-installs-after.js <path-to-devcontainer-feature.json>");
	process.exit(2);
}

const namespace = process.env.FEATURES_NAMESPACE || "savvy-web/features";
const prefix = `ghcr.io/${namespace}/`;

const data = JSON.parse(readFileSync(target, "utf8"));
if (Array.isArray(data.installsAfter)) {
	const kept = data.installsAfter.filter((d) => typeof d !== "string" || !d.startsWith(prefix));
	if (kept.length === 0) {
		delete data.installsAfter;
	} else {
		data.installsAfter = kept;
	}
}
writeFileSync(target, `${JSON.stringify(data, null, "\t")}\n`);
