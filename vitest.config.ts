// Vitest configuration — zero-config via @savvy-web/vitest.
//
// VitestConfig.create() auto-discovers workspace packages, scans src/ and
// __test__/ for test files, classifies them by suffix (.test.ts,
// .e2e.test.ts, .int.test.ts), and enables v8 coverage with "strict"
// thresholds. It also injects vitest-agent-reporter when available.
//
// Shared helpers in __test__/utils/ and __test__/fixtures/ are
// automatically excluded from test discovery.
//
// See: https://github.com/savvy-web/vitest
import { VitestConfig } from "@savvy-web/vitest";

export default VitestConfig.create();
