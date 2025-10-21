import ExhaustiveDeps from "./rules/ExhaustiveDeps.js";

const plugin = {
    rules: {
        "exhaustive-deps": ExhaustiveDeps,
    },
    configs: {
        recommended: {
            plugins: ["exhaustive-deps-exclude"],
            rules: {
                "react-hooks/exhaustive-deps": "off",
                "exhaustive-deps-exclude/exhaustive-deps": "error",
            },
        },
    },
};

export default plugin;
