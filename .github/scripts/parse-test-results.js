#!/usr/bin/env node
// Parses the TEST REPORT section emitted by `devcontainer features test` and
// writes a structured JSON results file.
//
// Usage:
//   node parse-test-results.js [logPath] [outPath]
//
// Defaults:
//   logPath  /tmp/test.log
//   outPath  /tmp/test-results.json
//
// Output shape:
//   { passed: string[], failed: string[], total: number, allPassed: boolean }
import { readFileSync, writeFileSync } from "node:fs";

const logPath = process.argv[2] ?? "/tmp/test.log";
const outPath = process.argv[3] ?? "/tmp/test-results.json";

let log = "";
try {
	log = readFileSync(logPath, "utf8");
} catch {
	// log file not yet written; treat as empty
}

const idx = log.indexOf("TEST REPORT");
// If the CLI crashed or changed output format, treat as a parse failure
// rather than silently succeeding with an empty result set.
const reportFound = idx >= 0;
const section = reportFound ? log.slice(idx) : "";
const passed = [...section.matchAll(/Passed:\s+'([^']+)'/g)].map((m) => m[1]);
const failed = [...section.matchAll(/Failed:\s+'([^']+)'/g)].map((m) => m[1]);

const result = {
	passed,
	failed,
	total: passed.length + failed.length,
	allPassed: reportFound && failed.length === 0,
};

writeFileSync(outPath, JSON.stringify(result, null, 2));
