import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { ESLint } from "eslint";

import plugin from "../lib/index.js";

// The ESLint class validates a config the way a real run does, which Linter does not.
const lint = (code) =>
    new ESLint({
        overrideConfigFile: true,
        overrideConfig: [
            {
                files: ["**/*.js"],
                languageOptions: { ecmaVersion: 2022, sourceType: "module" },
            },
            plugin.configs.recommended,
        ],
    }).lintText(code, { filePath: "sample.js" });

describe("configs.recommended", () => {
    it("registers the plugin so the rule resolves", async () => {
        const [result] = await lint(`
            function A({ a, b }) {
                useEffect(() => {
                    doSomething(a, b);
                    // exhaustive-deps-exclude [b]
                }, []);
            }`);

        assert.equal(result.messages.length, 1);
        assert.equal(
            result.messages[0].ruleId,
            "exhaustive-deps-exclude/exhaustive-deps"
        );
        // The config sets the rule to "error".
        assert.equal(result.messages[0].severity, 2);
        assert.match(result.messages[0].message, /missing dependency: 'a'/);
    });

    it("silences the upstream rule without react-hooks installed", async () => {
        // A rule at severity "off" needs no plugin behind it, so naming it here stays safe.
        assert.equal(
            plugin.configs.recommended.rules["react-hooks/exhaustive-deps"],
            "off"
        );

        const [result] = await lint(`
            function A({ a }) {
                useEffect(() => {
                    doSomething(a);
                }, [a]);
            }`);

        assert.deepEqual(result.messages, []);
    });
});
