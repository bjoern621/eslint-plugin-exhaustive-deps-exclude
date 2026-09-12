# Keeping the vendored rule current

The plugin's rule is React's `exhaustive-deps` rule with a small local delta.
This page covers how that delta survives a new React release, and what a person does when it stops merging on its own.

## What is vendored

Two files come from `eslint-plugin-react-hooks` rather than being written here.
`vendor/UPSTREAM_REF` holds the React commit they were taken from, and `vendor/` holds a pristine copy of each at that commit.

The live files under `src/` are the editable ones.
The pristine copies exist to be a merge base, so they are never edited by hand.
That pairing is what makes the local delta computable at any time: `npm run patch` prints it as a unified diff, and `npm run patch -- --stat` counts it.

## Two pipelines

The sync pipeline answers whether upstream moved and merges it when it did.
It reads the pin, fetches the same two paths at a chosen React ref, and stops when the content is unchanged.
On a change it runs a three-way merge per file, taking the pristine copy as the base, the local file as one side and the new upstream as the other.
Upstream hunks land wherever no local edit sits, and an overlap is written into `src/` as conflict markers.
The pin and the pristine copies then advance to the fetched commit, which leaves the local delta as the only difference that remains.

The verification pipeline answers whether the result still behaves.
It builds, runs the rule against the case suite in `tests/`, and greps for leftover conflict markers.
The marker grep is load-bearing: the rule file carries `@ts-nocheck`, so the compiler accepts a file a merge has mangled, and the suite plus the grep are the only gates.

A scheduled run joins the two and opens a pull request carrying the merge outcome, the test outcome and the delta.
A run finding no change opens nothing.
A run while a previous pull request is still open updates that one, so the queue holds at most one sync.

Choosing a three-way merge over a patch series keeps `src/` directly editable, which matters while the local delta is still being corrected.

## By hand

`npm run sync:check` reports drift and writes nothing.
`npm run sync` performs the merge, and `--ref` picks a React ref other than `main`.
Exit status is 0 for a clean merge, 1 when markers were written, 2 for drift under `--check` and 3 for a failed fetch.

A merge that reports conflicts leaves a working tree that needs a person.
`git diff` shows what upstream contributed, the markers show where it collided, and `npm test` confirms the resolution.

## The known collision

The local delta changes the import block at the top of the rule, adding a `.js` extension that the ESM build requires and importing the exclusion helpers.
Upstream formats that same line.
A release that reformats it collides every time, and the resolution is to keep the local side, since upstream's change there carries no behavior.

Every other part of the delta sits at a separate location and merges without a person.
