import { describe, expect, it } from "vitest";
import type { GreeterOptions, Greeting } from "../src/index.js";
import { Greeter } from "../src/index.js";

describe("Greeter", () => {
	it("produces a greeting with default options", () => {
		const greeter = new Greeter();
		const result: Greeting = greeter.greet("World");
		expect(result.message).toBe("Hello, World!");
		expect(result.timestamp).toBeTruthy();
	});

	it("applies prefix and suffix from options", () => {
		const options: GreeterOptions = { prefix: ">>", suffix: "<<" };
		const greeter = new Greeter(options);
		const result: Greeting = greeter.greet("Ada");
		expect(result.message).toBe(">> Hello, Ada! <<");
	});

	it("handles prefix-only option", () => {
		const greeter = new Greeter({ prefix: ">>" });
		expect(greeter.greet("Bob").message).toBe(">> Hello, Bob!");
	});

	it("handles suffix-only option", () => {
		const greeter = new Greeter({ suffix: "<<" });
		expect(greeter.greet("Carol").message).toBe("Hello, Carol! <<");
	});

	it("returns an ISO-8601 timestamp", () => {
		const greeter = new Greeter();
		const result: Greeting = greeter.greet("Test");
		expect(() => new Date(result.timestamp).toISOString()).not.toThrow();
	});
});
