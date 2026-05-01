import { existsSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterEach, describe, expect, it } from "vitest";
import type { CollectedFeature, RunResult } from "./utils/collect-runner.js";
import { FIXTURES_ROOT, runCollectAndFilter } from "./utils/collect-runner.js";

// Skip the entire suite on Windows — the fake docker shim is a bash script.
const skipOnWindows = process.platform === "win32";

const fixture = (name: string) => join(FIXTURES_ROOT, name);

const byId = (a: CollectedFeature, b: CollectedFeature) => a.id.localeCompare(b.id);

const summaryFiles: string[] = [];

afterEach(() => {
	for (const f of summaryFiles.splice(0)) {
		if (existsSync(f)) rmSync(f, { force: true });
	}
});

const newSummaryPath = () => {
	const path = join(tmpdir(), `summary-${process.pid}-${Math.random().toString(36).slice(2)}.md`);
	summaryFiles.push(path);
	return path;
};

describe.skipIf(skipOnWindows)("collect-and-filter-features script", () => {
	describe("filtering", () => {
		it("publishes every feature when none exist in the registry", () => {
			const result = runCollectAndFilter({
				fixturePath: fixture("all-new"),
				fakeDocker: { existing: [] },
			});

			expect(result.status, result.stderr).toBe(0);
			expect(result.stdoutJson.sort(byId)).toEqual([
				expect.objectContaining({ id: "bar", version: "0.2.0", publish: true }),
				expect.objectContaining({ id: "foo", version: "0.1.0", publish: true }),
			]);
		});

		it("publishes nothing when every feature already exists in the registry", () => {
			const result = runCollectAndFilter({
				fixturePath: fixture("all-cached"),
				fakeDocker: {
					existing: ["ghcr.io/savvy-web/foo:0.1.0", "ghcr.io/savvy-web/bar:0.2.0"],
				},
			});

			expect(result.status, result.stderr).toBe(0);
			expect(result.stdoutJson).toEqual([]);
		});

		it("publishes only features whose version is not yet in the registry", () => {
			const result = runCollectAndFilter({
				fixturePath: fixture("mixed"),
				fakeDocker: {
					existing: ["ghcr.io/savvy-web/foo:0.1.0"],
				},
			});

			expect(result.status, result.stderr).toBe(0);
			const ids = result.stdoutJson.map((r) => r.id).sort();
			expect(ids).toEqual(["bar", "baz"]);
			for (const entry of result.stdoutJson) {
				expect(entry.publish).toBe(true);
			}
		});

		it("emits an empty array when the features tree is empty", () => {
			const result = runCollectAndFilter({
				fixturePath: fixture("empty"),
			});

			expect(result.status, result.stderr).toBe(0);
			expect(result.stdoutJson).toEqual([]);
			expect(result.dockerCalls).toEqual([]);
		});
	});

	describe("non-feature entries", () => {
		it("skips directories without devcontainer-feature.json and stray top-level files", () => {
			const result = runCollectAndFilter({
				fixturePath: fixture("non-feature-entries"),
				fakeDocker: { existing: [] },
			});

			expect(result.status, result.stderr).toBe(0);
			expect(result.stdoutJson.map((r) => r.id)).toEqual(["real-feature"]);
			// docker should only have been queried for the one valid feature
			expect(result.dockerCalls).toHaveLength(1);
			expect(result.dockerCalls[0]).toContain("real-feature:0.1.0");
		});
	});

	describe("docker invocation", () => {
		it("queries ghcr.io/<owner>/<id>:<version> for each feature", () => {
			const result = runCollectAndFilter({
				fixturePath: fixture("all-new"),
				fakeDocker: { existing: [] },
			});

			expect(result.dockerCalls.sort()).toEqual([
				"manifest inspect ghcr.io/savvy-web/bar:0.2.0",
				"manifest inspect ghcr.io/savvy-web/foo:0.1.0",
			]);
		});

		it("uses GITHUB_REPOSITORY_OWNER when set", () => {
			const result = runCollectAndFilter({
				fixturePath: fixture("all-new"),
				env: { GITHUB_REPOSITORY_OWNER: "another-org" },
				fakeDocker: { existing: [] },
			});

			expect(result.status, result.stderr).toBe(0);
			expect(result.dockerCalls.sort()).toEqual([
				"manifest inspect ghcr.io/another-org/bar:0.2.0",
				"manifest inspect ghcr.io/another-org/foo:0.1.0",
			]);
		});

		it("falls back to 'savvy-web' when GITHUB_REPOSITORY_OWNER is empty", () => {
			const result = runCollectAndFilter({
				fixturePath: fixture("all-new"),
				env: { GITHUB_REPOSITORY_OWNER: "" },
				fakeDocker: { existing: [] },
			});

			expect(result.status, result.stderr).toBe(0);
			for (const call of result.dockerCalls) {
				expect(call).toMatch(/ghcr\.io\/savvy-web\//);
			}
		});
	});

	describe("output format", () => {
		let result: RunResult;

		it("writes a single JSON array to stdout", () => {
			result = runCollectAndFilter({
				fixturePath: fixture("mixed"),
				fakeDocker: { existing: ["ghcr.io/savvy-web/foo:0.1.0"] },
			});
			expect(result.status, result.stderr).toBe(0);
			expect(() => JSON.parse(result.stdout)).not.toThrow();
		});

		it("each entry exposes id, version, path, publish, and reason", () => {
			result = runCollectAndFilter({
				fixturePath: fixture("mixed"),
				fakeDocker: { existing: ["ghcr.io/savvy-web/foo:0.1.0"] },
			});
			for (const entry of result.stdoutJson) {
				expect(entry).toEqual({
					id: expect.any(String),
					version: expect.any(String),
					path: expect.any(String),
					publish: expect.any(Boolean),
					reason: expect.any(String),
				});
			}
		});

		it("emits absolute feature paths pointing at the fixture's features directory", () => {
			result = runCollectAndFilter({
				fixturePath: fixture("mixed"),
				fakeDocker: { existing: ["ghcr.io/savvy-web/foo:0.1.0"] },
			});
			const fooPath = join(fixture("mixed"), "features");
			for (const entry of result.stdoutJson) {
				expect(entry.path.startsWith(fooPath)).toBe(true);
				expect(entry.path).toContain(`/features/${entry.id}`);
			}
		});
	});

	describe("GITHUB_STEP_SUMMARY", () => {
		it("does not emit a summary file when the env var is unset", () => {
			const summaryPath = newSummaryPath();
			runCollectAndFilter({
				fixturePath: fixture("all-new"),
				fakeDocker: { existing: [] },
			});
			expect(existsSync(summaryPath)).toBe(false);
		});

		it("writes a markdown table to GITHUB_STEP_SUMMARY when set", () => {
			const summaryPath = newSummaryPath();
			const result = runCollectAndFilter({
				fixturePath: fixture("mixed"),
				fakeDocker: { existing: ["ghcr.io/savvy-web/foo:0.1.0"] },
				githubStepSummary: summaryPath,
			});

			expect(result.status, result.stderr).toBe(0);
			expect(existsSync(summaryPath)).toBe(true);

			const summary = readFileSync(summaryPath, "utf8");
			expect(summary).toContain("| Feature | Version | Publish? | Reason |");
			expect(summary).toContain("|---------|---------|----------|--------|");
		});

		it("includes every feature in the summary, even ones that are not being published", () => {
			const summaryPath = newSummaryPath();
			runCollectAndFilter({
				fixturePath: fixture("mixed"),
				fakeDocker: { existing: ["ghcr.io/savvy-web/foo:0.1.0"] },
				githubStepSummary: summaryPath,
			});

			const summary = readFileSync(summaryPath, "utf8");
			// foo is cached, bar/baz are new — all three should appear in the table
			expect(summary).toMatch(/\|\s*foo\s*\|\s*0\.1\.0\s*\|\s*❌\s*\|\s*Image exists in registry/);
			expect(summary).toMatch(/\|\s*bar\s*\|\s*0\.2\.0\s*\|\s*✅\s*\|\s*Image does not exist/);
			expect(summary).toMatch(/\|\s*baz\s*\|\s*0\.3\.0\s*\|\s*✅\s*\|\s*Image does not exist/);
		});
	});
});
