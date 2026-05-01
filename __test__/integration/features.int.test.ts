import { existsSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

function getFeatureSubdirs(dir: string): string[] {
	return readdirSync(dir)
		.filter((f) => {
			const p = join(dir, f);
			if (!statSync(p).isDirectory()) return false;
			return existsSync(join(p, "devcontainer-feature.json"));
		})
		.sort();
}

function getTestSubdirs(dir: string): string[] {
	return readdirSync(dir)
		.filter((f) => {
			const p = join(dir, f);
			if (!statSync(p).isDirectory()) return false;
			return existsSync(join(p, "test.sh"));
		})
		.sort();
}

describe("feature folder structure", () => {
	it("every test directory has a matching feature", () => {
		const featuresRoot = join(__dirname, "../../features");
		const testRoot = join(__dirname, "../../test");
		const features = new Set(getFeatureSubdirs(featuresRoot));
		const tests = getTestSubdirs(testRoot);
		for (const id of tests) {
			expect(features.has(id), `test/${id}/ has no matching features/${id}/devcontainer-feature.json`).toBe(true);
		}
	});
});
