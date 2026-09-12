# Cutting a release

A release is a tag.
Pushing a tag matching `v*` runs the suite, publishes to npm, and opens the GitHub release with the changelog entries as its body.
Nothing is published from a workstation.

## The three things a version touches

`CHANGELOG.md` holds a section per version, and the release body is that section verbatim.
A tag whose version has no entries fails the run before anything reaches the registry.

`package.json` holds the number the tag has to match.
`npm version <major|minor|patch>` writes it, commits, and tags in one step.

The tag is the trigger, so it is pushed last.

Everything a person runs lives in `Taskfile.yml`.
The one script left in `package.json` is `prepack`, which npm fires while packing the tarball, and which builds the `lib/` the tree does not carry.

## The steps

1. Move the entries under `## [Unreleased]` in `CHANGELOG.md` to a section for the new version, and commit that.
2. `npm version major`, or `minor`, or `patch`. It writes `package.json`, commits, and tags `v<version>`.
3. `git push --follow-tags`.

The run then tests on every supported Node version, refuses a tag disagreeing with `package.json`, reads the release body out of the changelog, publishes, and creates the release.

## What decides the number

The number is this package's own, and it tracks no upstream version.
A change to `engines.node`, to `configs.recommended`, or to what the rule reports is a major.
The vendored React revision moves on its own schedule, and the README banner names it.

## Credentials

The registry credential is minted per run through npm trusted publishing.
It is bound on npmjs.com to this repository and to `.github/workflows/release.yml`, so renaming that file breaks publishing until the binding follows.
No npm token lives in repository secrets.
