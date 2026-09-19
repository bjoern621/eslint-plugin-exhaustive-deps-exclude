import { createRequire } from "node:module";

import { ESLint as CurrentESLint, RuleTester as CurrentRuleTester } from "eslint";

// ESLint 8 ships the flat-config implementations under a separate entry point,
// and its default exports still read an eslintrc config.
const isEightMajor = CurrentESLint.version.startsWith("8.");
const unstable = isEightMajor
    ? createRequire(import.meta.url)("eslint/use-at-your-own-risk")
    : null;

export const RuleTester = isEightMajor ? unstable.FlatRuleTester : CurrentRuleTester;
export const ESLint = isEightMajor ? unstable.FlatESLint : CurrentESLint;
