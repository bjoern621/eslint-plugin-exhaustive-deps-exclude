import { describe, it } from "node:test";
import { RuleTester } from "eslint";

import plugin from "../lib/index.js";

// RuleTester calls these when present, so failures land as named node:test cases.
RuleTester.describe = describe;
RuleTester.it = it;

const ruleTester = new RuleTester({
    languageOptions: {
        ecmaVersion: 2022,
        sourceType: "module",
    },
});

const rule = plugin.rules["exhaustive-deps"];

// Long enough to carry the exclusion comment well clear of the dependency array.
const filler = `
        const padding = "${"x".repeat(90)}";
        console.log(padding);`;

// Reported code is held in bindings, so each expected suggestion output is derived rather than retyped.
const oneNameNotExcluded = `
                function A({ a, b, c }) {
                    useEffect(() => {
                        doSomething(a, b, c);
                        // exhaustive-deps-exclude [c]
                    }, [a]);
                }`;

const noComment = `
                function A({ a, b }) {
                    useEffect(() => {
                        doSomething(a, b);
                    }, []);
                }`;

const useCallbackWithExclusion = `
                function A({ a, b }) {
                    return useCallback(() => {
                        doSomething(a, b);
                        // exhaustive-deps-exclude [b]
                    }, []);
                }`;

const exclusionInNestedFunction = `
                function A({ a }) {
                    useEffect(() => {
                        register(() => {
                            // exhaustive-deps-exclude [a]
                        });
                        doSomething(a);
                    }, []);
                }`;

const replaceDeps = (code, from, to) => code.replace(`}, ${from});`, `}, ${to});`);

// The exclusion fix writes a block comment in front of the array, which it leaves as it stands.
const withExclusionComment = (code, deps, depsArray) =>
    replaceDeps(code, depsArray, `/* exhaustive-deps-exclude [${deps.join(", ")}] */ ${depsArray}`);

// Every case here excludes one or two names, which the rule joins without a serial comma.
const excludeSuggestion = (code, deps, depsArray) => ({
    desc: `Exclude ${deps.map((dep) => `'${dep}'`).join(" and ")} with an exhaustive-deps-exclude comment`,
    output: withExclusionComment(code, deps, depsArray),
});

ruleTester.run("exhaustive-deps", rule, {
    valid: [
        {
            name: "excluded dependency is not demanded",
            code: `
                function ChatRoom({ roomId, isMuted }) {
                    useEffect(() => {
                        connect(roomId);
                        if (!isMuted) play();
                        // exhaustive-deps-exclude [isMuted]
                    }, [roomId]);
                }`,
        },
        {
            name: "block comment carries an exclusion",
            code: `
                function A({ a, b }) {
                    useEffect(() => {
                        doSomething(a, b);
                        /* exhaustive-deps-exclude [b] */
                    }, [a]);
                }`,
        },
        {
            name: "several names on one comment",
            code: `
                function A({ a, b, c }) {
                    useEffect(() => {
                        doSomething(a, b, c);
                        // exhaustive-deps-exclude [b, c]
                    }, [a]);
                }`,
        },
        {
            name: "property chain matches the key the rule reports",
            code: `
                function A({ config }) {
                    useEffect(() => {
                        doSomething(config.url);
                        // exhaustive-deps-exclude [config.url]
                    }, []);
                }`,
        },
        {
            name: "exclusion applies to useCallback",
            code: `
                function A({ a }) {
                    return useCallback(() => {
                        doSomething(a);
                        // exhaustive-deps-exclude [a]
                    }, []);
                }`,
        },
        {
            name: "exclusion applies to useMemo",
            code: `
                function A({ a }) {
                    return useMemo(() => {
                        return compute(a);
                        // exhaustive-deps-exclude [a]
                    }, []);
                }`,
        },
        {
            name: "state setters and refs are stable upstream, so no exclusion is needed",
            code: `
                function A() {
                    const [count, setCount] = useState(0);
                    const elementRef = useRef(null);
                    useEffect(() => {
                        setCount((c) => c + 1);
                        elementRef.current.focus();
                    }, []);
                }`,
        },
        {
            name: "an exclusion far from the dependency array is found",
            code: `
                function A({ a, b }) {
                    useEffect(() => {
                        // exhaustive-deps-exclude [b]
                        doSomething(a, b);${filler}
                    }, [a]);
                }`,
        },
        {
            name: "an exclusion applies to a hook named by the additionalHooks option",
            options: [{ additionalHooks: "useMyEffect" }],
            code: `
                function A({ a, b }) {
                    useMyEffect(() => {
                        doSomething(a, b);
                        // exhaustive-deps-exclude [b]
                    }, [a]);
                }`,
        },
        {
            name: "an exclusion between the callback and the array is found",
            code: `
                function A({ a, b }) {
                    useEffect(() => {
                        doSomething(a, b);
                    }, /* exhaustive-deps-exclude [b] */ [a]);
                }`,
        },
    ],
    invalid: [
        {
            name: "a dependency the comment does not name is still reported",
            code: oneNameNotExcluded,
            errors: [
                {
                    message:
                        "React Hook useEffect has a missing dependency: 'b'. Either include it or remove the dependency array.",
                    suggestions: [
                        {
                            desc: "Update the dependencies array to be: [a, b]",
                            output: replaceDeps(oneNameNotExcluded, "[a]", "[a, b]"),
                        },
                        excludeSuggestion(oneNameNotExcluded, ["b"], "[a]"),
                    ],
                },
            ],
        },
        {
            name: "every dependency is reported when no exclusion comment is present",
            code: noComment,
            errors: [
                {
                    message:
                        "React Hook useEffect has missing dependencies: 'a' and 'b'. Either include them or remove the dependency array.",
                    suggestions: [
                        {
                            desc: "Update the dependencies array to be: [a, b]",
                            output: replaceDeps(noComment, "[]", "[a, b]"),
                        },
                        excludeSuggestion(noComment, ["a", "b"], "[]"),
                    ],
                },
            ],
        },
        {
            name: "an exclusion the callback never uses is reported",
            code: `
                function A({ a }) {
                    useEffect(() => {
                        doSomething(a);
                        // exhaustive-deps-exclude [neverUsed]
                    }, [a]);
                }`,
            errors: [
                {
                    message:
                        "React Hook useEffect excludes 'neverUsed', which it does not use. Remove it from the exhaustive-deps-exclude comment.",
                },
            ],
        },
        {
            name: "two unused exclusions are reported together",
            code: `
                function A({ a }) {
                    useEffect(() => {
                        doSomething(a);
                        // exhaustive-deps-exclude [zz, yy]
                    }, [a]);
                }`,
            errors: [
                {
                    message:
                        "React Hook useEffect excludes 'yy' and 'zz', which it does not use. Remove them from the exhaustive-deps-exclude comment.",
                },
            ],
        },
        {
            name: "a name both declared and excluded is reported",
            code: `
                function A({ a, b }) {
                    useEffect(() => {
                        doSomething(a, b);
                        // exhaustive-deps-exclude [b]
                    }, [a, b]);
                }`,
            errors: [
                {
                    message:
                        "React Hook useEffect excludes 'b', which the dependency array also lists. Remove it from the array or from the exhaustive-deps-exclude comment.",
                },
            ],
        },
        {
            name: "useCallback keeps an excluded name out of the suggestion",
            code: useCallbackWithExclusion,
            errors: [
                {
                    message:
                        "React Hook useCallback has a missing dependency: 'a'. Either include it or remove the dependency array.",
                    suggestions: [
                        {
                            desc: "Update the dependencies array to be: [a]",
                            output: replaceDeps(useCallbackWithExclusion, "[]", "[a]"),
                        },
                        excludeSuggestion(useCallbackWithExclusion, ["a"], "[]"),
                    ],
                },
            ],
        },
        {
            name: "an exclusion inside a nested function does not reach the enclosing hook",
            code: exclusionInNestedFunction,
            errors: [
                {
                    message:
                        "React Hook useEffect has a missing dependency: 'a'. Either include it or remove the dependency array.",
                    suggestions: [
                        {
                            desc: "Update the dependencies array to be: [a]",
                            output: replaceDeps(exclusionInNestedFunction, "[]", "[a]"),
                        },
                        excludeSuggestion(exclusionInNestedFunction, ["a"], "[]"),
                    ],
                },
            ],
        },
    ],
});
