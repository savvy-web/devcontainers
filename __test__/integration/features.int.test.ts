import { readdirSync, statSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

function getSubdirs(dir: string): string[] {
	return readdirSync(dir)
		.filter((f) => statSync(join(dir, f)).isDirectory())
		.sort();
}

function getFeatureTestPairs(featuresRoot: string, testRoot: string) {
	const featureScopes = getSubdirs(featuresRoot);
	const testScopes = getSubdirs(testRoot);
	expect(testScopes).toEqual(featureScopes);
	for (const scope of featureScopes) {
		const features = getSubdirs(join(featuresRoot, scope));
		const tests = getSubdirs(join(testRoot, scope));
		expect(tests).toEqual(features);
		for (const feature of features) {
			const featurePath = join(featuresRoot, scope, feature);
			const testPath = join(testRoot, scope, feature);
			expect(statSync(featurePath).isDirectory()).toBe(true);
			expect(statSync(testPath).isDirectory()).toBe(true);
		}
	}
}

describe("feature folder structure", () => {
	it("matches between features/ and test/", () => {
		const featuresRoot = join(__dirname, "../../features");
		const testRoot = join(__dirname, "../../test");
		getFeatureTestPairs(featuresRoot, testRoot);
	});
});
