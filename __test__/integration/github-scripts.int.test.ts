import { join } from "node:path";
import { describe, expect, it } from "vitest";
import type { CollectedFeature } from "./utils/collect-runner.js";
import { FIXTURES_ROOT, runCollectAndFilter } from "./utils/collect-runner.js";

// Skip the entire suite on Windows — the fake docker shim is a bash script.
const skipOnWindows = process.platform === "win32";

const fixture = (name: string) => join(FIXTURES_ROOT, name);

const byId = (a: CollectedFeature, b: CollectedFeature) => a.id.localeCompare(b.id);

describe.skipIf(skipOnWindows)("topo-order script", () => {
	describe("publish flagging", () => {
		it("flags every feature publish=true when none exist in the registry", () => {
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

		it("flags every feature publish=false when all already exist in the registry", () => {
			const result = runCollectAndFilter({
				fixturePath: fixture("all-cached"),
				fakeDocker: {
					existing: ["ghcr.io/savvy-web/features/foo:0.1.0", "ghcr.io/savvy-web/features/bar:0.2.0"],
				},
			});

			expect(result.status, result.stderr).toBe(0);
			expect(result.stdoutJson).toHaveLength(2);
			for (const entry of result.stdoutJson) {
				expect(entry.publish).toBe(false);
				expect(entry.reason).toMatch(/already.*registry|exists in registry/i);
			}
		});

		it("flags only features whose version is not yet in the registry", () => {
			const result = runCollectAndFilter({
				fixturePath: fixture("mixed"),
				fakeDocker: {
					existing: ["ghcr.io/savvy-web/features/foo:0.1.0"],
				},
			});

			expect(result.status, result.stderr).toBe(0);
			const byPublishFlag = Object.fromEntries(result.stdoutJson.map((e) => [e.id, e.publish] as const));
			expect(byPublishFlag).toEqual({ foo: false, bar: true, baz: true });
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
			expect(result.dockerCalls).toHaveLength(1);
			expect(result.dockerCalls[0]).toContain("real-feature:0.1.0");
		});
	});

	describe("docker invocation", () => {
		it("queries ghcr.io/<owner>/features/<id>:<version> for each feature", () => {
			const result = runCollectAndFilter({
				fixturePath: fixture("all-new"),
				fakeDocker: { existing: [] },
			});

			expect(result.dockerCalls.sort()).toEqual([
				"manifest inspect ghcr.io/savvy-web/features/bar:0.2.0",
				"manifest inspect ghcr.io/savvy-web/features/foo:0.1.0",
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
				"manifest inspect ghcr.io/another-org/features/bar:0.2.0",
				"manifest inspect ghcr.io/another-org/features/foo:0.1.0",
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

		it("does not query docker when SKIP_REGISTRY_CHECK=true", () => {
			const result = runCollectAndFilter({
				fixturePath: fixture("all-new"),
				env: { SKIP_REGISTRY_CHECK: "true" },
				fakeDocker: { existing: [] },
			});

			expect(result.status, result.stderr).toBe(0);
			expect(result.dockerCalls).toEqual([]);
			for (const entry of result.stdoutJson) {
				expect(entry.publish).toBe(true);
				expect(entry.reason).toMatch(/skip/i);
			}
		});
	});

	describe("output format", () => {
		it("writes a single JSON array to stdout", () => {
			const result = runCollectAndFilter({
				fixturePath: fixture("mixed"),
				fakeDocker: { existing: ["ghcr.io/savvy-web/features/foo:0.1.0"] },
			});
			expect(result.status, result.stderr).toBe(0);
			expect(() => JSON.parse(result.stdout)).not.toThrow();
		});

		it("each entry exposes id, version, path, deps, skipAutogenerated, publish, and reason", () => {
			const result = runCollectAndFilter({
				fixturePath: fixture("mixed"),
				fakeDocker: { existing: ["ghcr.io/savvy-web/features/foo:0.1.0"] },
			});
			for (const entry of result.stdoutJson) {
				expect(entry).toEqual({
					id: expect.any(String),
					version: expect.any(String),
					path: expect.any(String),
					deps: expect.any(Array),
					skipAutogenerated: expect.any(Boolean),
					publish: expect.any(Boolean),
					reason: expect.any(String),
				});
			}
		});

		it("emits absolute feature paths pointing at the fixture's src directory", () => {
			const result = runCollectAndFilter({
				fixturePath: fixture("mixed"),
				fakeDocker: { existing: ["ghcr.io/savvy-web/features/foo:0.1.0"] },
			});
			const srcPath = join(fixture("mixed"), "src");
			for (const entry of result.stdoutJson) {
				expect(entry.path.startsWith(srcPath)).toBe(true);
				expect(entry.path).toContain(`/src/${entry.id}`);
			}
		});

		it("includes every feature in the output, even ones that are not being published", () => {
			const result = runCollectAndFilter({
				fixturePath: fixture("mixed"),
				fakeDocker: { existing: ["ghcr.io/savvy-web/features/foo:0.1.0"] },
			});
			const ids = result.stdoutJson.map((e) => e.id).sort();
			expect(ids).toEqual(["bar", "baz", "foo"]);
		});
	});
});
