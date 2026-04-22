/**
 * Options for configuring a {@link Greeter} instance.
 *
 * @remarks
 * The `prefix` and `suffix` fields wrap the greeting message. When omitted,
 * the greeter produces a bare greeting with no decoration.
 *
 * @see {@link Greeter} for the main class that consumes these options.
 *
 * @public
 */
export interface GreeterOptions {
	/** Optional prefix prepended to every greeting. */
	prefix?: string;

	/** Optional suffix appended to every greeting. */
	suffix?: string;
}

/**
 * The shape returned by {@link Greeter.greet}.
 *
 * @public
 */
export interface Greeting {
	/** The formatted greeting message. */
	message: string;

	/** ISO-8601 timestamp of when the greeting was created. */
	timestamp: string;
}

/**
 * Formats the raw parts of a greeting into a single string.
 *
 * @privateRemarks
 * This is intentionally kept as a pure function so it can be unit-tested
 * independently of the `Greeter` class. If the formatting logic grows,
 * consider extracting it into its own module.
 *
 * @param name - The name to greet.
 * @param prefix - Optional prefix string.
 * @param suffix - Optional suffix string.
 * @returns The formatted greeting string.
 *
 * @internal
 */
export function formatGreeting(name: string, prefix?: string, suffix?: string): string {
	const parts: string[] = [];
	if (prefix) parts.push(prefix);
	parts.push(`Hello, ${name}!`);
	if (suffix) parts.push(suffix);
	return parts.join(" ");
}

/**
 * A configurable greeter that produces timestamped greeting messages.
 *
 * @remarks
 * `Greeter` is the primary entry point for this module. It accepts
 * {@link GreeterOptions} at construction time and produces {@link Greeting}
 * objects via the {@link Greeter.greet} method.
 *
 * @example Minimal usage
 * ```typescript
 * import type { Greeting } from "@savvy-web/pnpm-module-template";
 * import { Greeter } from "@savvy-web/pnpm-module-template";
 *
 * const greeter = new Greeter();
 * const result: Greeting = greeter.greet("World");
 * console.log(result.message); // "Hello, World!"
 * ```
 *
 * @example With prefix and suffix
 * ```typescript
 * import type { Greeting, GreeterOptions } from "@savvy-web/pnpm-module-template";
 * import { Greeter } from "@savvy-web/pnpm-module-template";
 *
 * const options: GreeterOptions = { prefix: ">>", suffix: "<<" };
 * const greeter = new Greeter(options);
 * const result: Greeting = greeter.greet("Ada");
 * console.log(result.message); // ">> Hello, Ada! <<"
 * ```
 *
 * @public
 */
export class Greeter {
	private readonly prefix: string | undefined;
	private readonly suffix: string | undefined;

	/**
	 * Creates a new `Greeter` instance.
	 *
	 * @param options - Configuration for greeting format. See {@link GreeterOptions}.
	 */
	constructor(options: GreeterOptions = {}) {
		this.prefix = options.prefix;
		this.suffix = options.suffix;
	}

	/**
	 * Produces a timestamped {@link Greeting} for the given name.
	 *
	 * @param name - The name to greet.
	 * @returns A {@link Greeting} with the formatted message and current timestamp.
	 */
	greet(name: string): Greeting {
		return {
			message: formatGreeting(name, this.prefix, this.suffix),
			timestamp: new Date().toISOString(),
		};
	}
}
