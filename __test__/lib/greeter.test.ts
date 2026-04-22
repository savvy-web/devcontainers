import { describe, expect, it } from "vitest";
import { formatGreeting } from "../../src/lib/greeter.js";

describe("formatGreeting (internal)", () => {
	it("formats a bare greeting with no prefix or suffix", () => {
		expect(formatGreeting("World")).toBe("Hello, World!");
	});

	it("prepends a prefix when provided", () => {
		expect(formatGreeting("Ada", ">>")).toBe(">> Hello, Ada!");
	});

	it("appends a suffix when provided", () => {
		expect(formatGreeting("Bob", undefined, "<<")).toBe("Hello, Bob! <<");
	});

	it("includes both prefix and suffix when provided", () => {
		expect(formatGreeting("Carol", ">>", "<<")).toBe(">> Hello, Carol! <<");
	});

	it("ignores empty-string prefix and suffix", () => {
		expect(formatGreeting("Dave", "", "")).toBe("Hello, Dave!");
	});
});
