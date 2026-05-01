import type { SpawnSyncReturns } from "node:child_process";
import { spawnSync } from "node:child_process";
import {
	chmodSync,
	copyFileSync,
	existsSync,
	mkdirSync,
	mkdtempSync,
	readFileSync,
	rmSync,
	writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(HERE, "../../..");
const REAL_SCRIPT = join(REPO_ROOT, ".github/scripts/collect-and-filter-features.js");

export interface FakeDockerOptions {
	/** List of "<id>:<version>" image refs (sans registry/owner) that should report as existing. */
	existing?: string[];
}

export interface RunOptions {
	fixturePath: string;
	env?: Record<string, string | undefined>;
	fakeDocker?: FakeDockerOptions;
	githubStepSummary?: string;
}

export interface CollectedFeature {
	id: string;
	version: string;
	path: string;
	publish: boolean;
	reason: string;
}

export interface RunResult {
	stdout: string;
	stderr: string;
	status: number;
	stdoutJson: CollectedFeature[];
	dockerCalls: string[];
}

/**
 * Copy the real collect-and-filter-features.js into the fixture's
 * .github/scripts/ directory. The script uses import.meta.dirname to
 * locate features, so the copy must live at the same relative depth as
 * the real one for `../../features` to resolve to the fixture's tree.
 */
function installScriptInFixture(fixturePath: string): string {
	const dir = join(fixturePath, ".github/scripts");
	mkdirSync(dir, { recursive: true });
	const dest = join(dir, "collect-and-filter-features.js");
	copyFileSync(REAL_SCRIPT, dest);
	return dest;
}

/**
 * Generate a temporary `docker` shim that simulates `docker manifest inspect`.
 *  - Logs every invocation's argv (joined by spaces) to FAKE_DOCKER_LOG
 *  - Exits 0 when the requested image is listed in FAKE_DOCKER_EXISTING
 *  - Exits 1 otherwise (mirrors a real registry "not found" response)
 *
 * The shim is a bash script and assumes a POSIX shell. The repo CI runs
 * on ubuntu-latest and contributors develop on macOS/Linux, so this is
 * fine; tests will skip on Windows.
 */
function createFakeDockerShim(): { binDir: string; logFile: string; cleanup: () => void } {
	const binDir = mkdtempSync(join(tmpdir(), "fake-docker-"));
	const dockerPath = join(binDir, "docker");
	const logFile = join(binDir, "calls.log");
	writeFileSync(logFile, "");

	// Bash shim: every $-substitution below is shell syntax, escaped in the
	// JS template literal so it survives to the written file unchanged.
	const shim = `#!/usr/bin/env bash
set -u
if [[ -n "\${FAKE_DOCKER_LOG:-}" ]]; then
  printf '%s\\n' "$*" >> "$FAKE_DOCKER_LOG"
fi
if [[ "$1" != "manifest" || "$2" != "inspect" ]]; then
  echo "fake-docker: unexpected args: $*" >&2
  exit 99
fi
IMAGE="$3"
IFS="," read -ra EXISTING <<< "\${FAKE_DOCKER_EXISTING:-}"
for img in "\${EXISTING[@]}"; do
  if [[ "$IMAGE" == "$img" ]]; then
    exit 0
  fi
done
exit 1
`;

	writeFileSync(dockerPath, shim);
	chmodSync(dockerPath, 0o755);

	return {
		binDir,
		logFile,
		cleanup: () => rmSync(binDir, { recursive: true, force: true }),
	};
}

function readLog(p: string): string[] {
	if (!existsSync(p)) return [];
	return readFileSync(p, "utf8").split("\n").filter(Boolean);
}

/**
 * Run the collect-and-filter-features.js script against a fixture
 * repo. The fake docker shim and a copy of the script are installed
 * before the run and cleaned up afterwards.
 */
export function runCollectAndFilter(opts: RunOptions): RunResult {
	const scriptPath = installScriptInFixture(opts.fixturePath);
	const shim = createFakeDockerShim();
	try {
		const env: NodeJS.ProcessEnv = {
			...process.env,
			...opts.env,
			PATH: `${shim.binDir}:${process.env.PATH ?? ""}`,
			FAKE_DOCKER_LOG: shim.logFile,
			FAKE_DOCKER_EXISTING: (opts.fakeDocker?.existing ?? []).join(","),
		};
		if (opts.githubStepSummary !== undefined) {
			env.GITHUB_STEP_SUMMARY = opts.githubStepSummary;
		} else {
			delete env.GITHUB_STEP_SUMMARY;
		}

		const result: SpawnSyncReturns<string> = spawnSync(process.execPath, [scriptPath], {
			env,
			encoding: "utf8",
			cwd: opts.fixturePath,
		});

		const stdout = result.stdout ?? "";
		let stdoutJson: CollectedFeature[] = [];
		try {
			stdoutJson = JSON.parse(stdout);
		} catch {
			// Leave empty; the test asserting on stdoutJson will fail loudly.
		}

		return {
			stdout,
			stderr: result.stderr ?? "",
			status: result.status ?? -1,
			stdoutJson,
			dockerCalls: readLog(shim.logFile),
		};
	} finally {
		shim.cleanup();
		if (existsSync(scriptPath)) rmSync(scriptPath);
		// Best-effort cleanup of the .github/scripts dir we created so
		// fixtures stay pristine between runs.
		const scriptsDir = join(opts.fixturePath, ".github/scripts");
		const githubDir = join(opts.fixturePath, ".github");
		try {
			rmSync(scriptsDir, { recursive: true, force: true });
			rmSync(githubDir, { recursive: true, force: true });
		} catch {
			/* ignore */
		}
	}
}

export const FIXTURES_ROOT = resolve(HERE, "../fixtures");
