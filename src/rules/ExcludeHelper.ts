import type { Rule } from "eslint";
import type { Node } from "estree";

/**
 * Extracts dependency names from a comment string.
 * Only matches the syntax: // exhaustive-deps-exclude [dep1, dep2]
 *
 * @param comment The comment text (without // or /*)
 * @returns Array of dependency names found in the comment
 *
 * @example
 * extractDepsFromComment("exhaustive-deps-exclude [foo, bar]") // returns ["foo", "bar"]
 */
function extractDepsFromComment(comment: string): string[] {
    const match = comment.match(/exhaustive-deps-exclude\s*\[([^\]]+)\]/);

    if (!match || !match[1]) {
        return [];
    }

    return match[1]
        .split(",")
        .map((dep) => dep.trim())
        .filter((dep) => dep.length > 0);
}

/**
 * Extracts dependency names from exhaustive-deps-exclude comment.
 * Looks for comments like: // exhaustive-deps-exclude [dep1, dep2]
 *
 * Searches in two places:
 * 1. Comments directly before the dependency array
 * 2. All comments within 100 chars before the dependency array
 *
 * @param declaredDependenciesNode The AST node representing the declared dependencies array
 * @param context The ESLint rule context
 * @returns Set of excluded dependency names
 */
export function parseExcludedDependencies(
    declaredDependenciesNode: Node,
    context: Rule.RuleContext
): Set<string> {
    const excludedDeps = new Set<string>();
    const sourceCode =
        typeof context.getSourceCode === "function"
            ? context.getSourceCode()
            : context.sourceCode;

    let comments = sourceCode.getCommentsBefore(declaredDependenciesNode);

    if (comments.length === 0) {
        const allComments = sourceCode.getAllComments();
        comments = allComments.filter((comment) => {
            if (!comment.range || !declaredDependenciesNode.range) return false;
            return (
                comment.range[1] < declaredDependenciesNode.range[0] &&
                comment.range[1] > declaredDependenciesNode.range[0] - 100
            );
        });
    }

    for (const comment of comments) {
        const deps = extractDepsFromComment(comment.value);
        deps.forEach((dep) => excludedDeps.add(dep));
    }

    return excludedDeps;
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

/**
 * Removes excluded dependencies from the suggested dependencies array.
 * This prevents autofix from adding back excluded deps.
 */
export function filterSuggestedDependencies(
    suggestedDependencies: Array<string>,
    excludedDeps: Set<string>
): Array<string> {
    return suggestedDependencies.filter((dep) => !excludedDeps.has(dep));
}
