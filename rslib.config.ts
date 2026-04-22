// Rslib build configuration via @savvy-web/rslib-builder.
//
// Produces dual output: dist/dev/ (development) and dist/npm/ (production).
// The transform hook strips fields from package.json that should not
// appear in the published artifact — the builder handles converting
// "private: true" to a publishable package based on publishConfig.
import { NodeLibraryBuilder } from "@savvy-web/rslib-builder";

export default NodeLibraryBuilder.create({
	transform({ pkg }) {
		delete pkg.devDependencies;
		delete pkg.bundleDependencies;
		delete pkg.scripts;
		delete pkg.publishConfig;
		delete pkg.packageManager;
		delete pkg.devEngines;
		return pkg;
	},
});
