import type { Rule } from "eslint";
import type { Comment, Node } from "estree";

const EXCLUDE_PATTERN = /exhaustive-deps-exclude\s*\[([^\]]+)\]/;

const FUNCTION_TYPES = new Set([
    "ArrowFunctionExpression",
    "FunctionDeclaration",
    "FunctionExpression",
]);

/**
 * Extracts dependency names from a comment string.
 * Only matches the syntax: // exhaustive-deps-exclude [dep1, dep2]
 *
 * @param comment The comment text (without // or the block delimiters)
 * @returns Array of dependency names found in the comment
 *
 * @example
 * extractDepsFromComment("exhaustive-deps-exclude [foo, bar]") // returns ["foo", "bar"]
 */
function extractDepsFromComment(comment: string): string[] {
    const match = comment.match(EXCLUDE_PATTERN);

    if (!match || !match[1]) {
        return [];
    }

    return match[1]
        .split(",")
        .map((dep) => dep.trim())
        .filter((dep) => dep.length > 0);
}

/**
 * Ranges of the functions nested inside root, root itself excluded.
 *
 * A comment inside one of these belongs to that function,
 * so an exclusion written for a nested hook call stays out of the enclosing hook's set.
 */
function nestedFunctionRanges(root: Node): Array<[number, number]> {
    const ranges: Array<[number, number]> = [];

    const visit = (value: unknown, isRoot: boolean): void => {
        if (Array.isArray(value)) {
            for (const item of value) {
                visit(item, false);
            }
            return;
        }
        if (value === null || typeof value !== "object") {
            return;
        }

        const node = value as { type?: unknown; range?: unknown };
        if (typeof node.type !== "string") {
            return;
        }

        if (!isRoot && FUNCTION_TYPES.has(node.type)) {
            const range = node.range;
            if (
                Array.isArray(range) &&
                typeof range[0] === "number" &&
                typeof range[1] === "number"
            ) {
                ranges.push([range[0], range[1]]);
            }
            // Functions deeper in are already inside this range.
            return;
        }

        for (const [key, child] of Object.entries(value)) {
            // ESLint back-references the parent, so walking it would cycle.
            if (key === "parent" || key === "loc" || key === "range") {
                continue;
            }
            visit(child, false);
        }
    };

    visit(root, true);
    return ranges;
}

/**
 * Extracts dependency names from exhaustive-deps-exclude comments belonging to one hook call.
 *
 * Searches two places:
 * 1. Between the callback and the dependency array, so `}, /* ... *​/ [a])` is covered
 * 2. Anywhere in the callback outside a nested function
 *
 * @param declaredDependenciesNode The AST node representing the declared dependencies array
 * @param callback The hook callback the dependencies belong to
 * @param context The ESLint rule context
 * @returns Set of excluded dependency names
 */
export function parseExcludedDependencies(
    declaredDependenciesNode: Node,
    callback: Node,
    context: Rule.RuleContext
): Set<string> {
    const sourceCode =
        typeof context.getSourceCode === "function"
            ? context.getSourceCode()
            : context.sourceCode;

    const nested = nestedFunctionRanges(callback);
    const insideNestedFunction = (comment: Comment): boolean => {
        const range = comment.range;
        if (!range) {
            return false;
        }
        return nested.some(([start, end]) => range[0] >= start && range[1] <= end);
    };

    const comments: Comment[] = [
        ...sourceCode.getCommentsBefore(declaredDependenciesNode),
        ...sourceCode.getCommentsInside(callback).filter((comment) => !insideNestedFunction(comment)),
    ];

    const excludedDeps = new Set<string>();
    for (const comment of comments) {
        for (const dep of extractDepsFromComment(comment.value)) {
            excludedDeps.add(dep);
        }
    }

    return excludedDeps;
}

/**
 * Splits the excluded names the hook cannot act on.
 *
 * declared: the dependency array lists it too, so the array wins and the exclusion contradicts it.
 * unused: the callback never reads it, so the exclusion covers nothing and usually marks a typo.
 */
export function findStaleExclusions(
    excludedDeps: Set<string>,
    dependencyKeys: Iterable<string>,
    declaredKeys: Iterable<string>
): { declared: Array<string>; unused: Array<string> } {
    const used = new Set(dependencyKeys);
    const declared = new Set(declaredKeys);
    const stale: { declared: Array<string>; unused: Array<string> } = {
        declared: [],
        unused: [],
    };

    for (const dep of excludedDeps) {
        if (declared.has(dep)) {
            stale.declared.push(dep);
        } else if (!used.has(dep)) {
            stale.unused.push(dep);
        }
    }

    return stale;
}

/**
 * Removes excluded dependencies from the missing dependencies set.
 * This prevents the linter from complaining about intentionally excluded deps.
 */
export function filterMissingDependencies(
    missingDependencies: Set<string>,
    excludedDeps: Set<string>
): Set<string> {
    return new Set(
        Array.from(missingDependencies).filter((key) => !excludedDeps.has(key))
    );
}
