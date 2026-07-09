// import { VitestConfig, VitestProject } from "@savvy-web/vitest";

// const project = VitestProject.unit({
// 	name: "features",
// 	include: ["__test__/**/*.test.ts"],
// });

// export default VitestConfig.create({
// 	coverage: VitestConfig.COVERAGE_LEVELS.none,
// 	coverageTargets: VitestConfig.COVERAGE_LEVELS.none,
// 	unit: project,
// });
import { AgentPlugin } from "@vitest-agent/plugin";
import { defineConfig } from "vitest/config";

export default async () => {
	const { projects, tags } = await AgentPlugin.discover();
	return defineConfig({
		plugins: [
			AgentPlugin({
				console: {
					human: "stream",
					agent: "agent",
				},
				coverageTargets: AgentPlugin.COVERAGE_LEVELS.basic.coverageTargets,
			}),
		],
		test: {
			...(projects ? { projects } : {}),
			tags,
			pool: "forks",
			globalSetup: ["vitest.setup.ts"],
			coverage: {
				enabled: true,
				provider: "v8",
				thresholds: AgentPlugin.COVERAGE_LEVELS.basic.thresholds,
				exclude: [],
			},
		},
	});
};
