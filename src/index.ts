import ExhaustiveDeps from "./rules/ExhaustiveDeps.js";

const plugin = {
    rules: {
        "exhaustive-deps": ExhaustiveDeps,
    },
    // Assigned below, because flat config registers the plugin object itself.
    configs: {} as Record<string, unknown>,
};

plugin.configs["recommended"] = {
    plugins: { "exhaustive-deps-exclude": plugin },
    rules: {
        // Both rules report the same missing dependencies, so the upstream one goes quiet.
        // A rule set to "off" needs no plugin behind it, so this holds without react-hooks installed.
        "react-hooks/exhaustive-deps": "off",
        "exhaustive-deps-exclude/exhaustive-deps": "error",
    },
};

export default plugin;
