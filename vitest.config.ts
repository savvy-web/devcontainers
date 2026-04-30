import { VitestConfig, VitestProject } from "@savvy-web/vitest";

const project = VitestProject.unit({
	name: "features",
	include: ["__test__/**/*.test.ts"],
});

export default VitestConfig.create({
	coverage: VitestConfig.COVERAGE_LEVELS.none,
	coverageTargets: VitestConfig.COVERAGE_LEVELS.none,
	unit: project,
});
