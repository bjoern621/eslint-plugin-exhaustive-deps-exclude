# Changelog

What changed in each release, for the person upgrading.
The release pipeline takes a release body from the section matching the tag, so a version without entries here cannot be released.
Headings follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), numbering follows [semantic versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0]

### Added

- An exclusion naming something the callback never reads is reported against the dependency array.
- An exclusion that the dependency array also lists is reported, the array winning over the comment.

### Changed

- Node 22 or newer is required.

### Fixed

- `configs.recommended` loads under flat config.
  It declared `plugins` as an array of strings, which threw before any file was read.
- Suggestions on `useCallback` and `useMemo` keep excluded names out of the array they propose.
- An exclusion comment is found from the callback body and from the gap before the dependency array, whatever the length of the statement ahead of it.
  The search covered 100 characters before the array.
- An exclusion written inside a nested function stays with that function and no longer reaches the enclosing hook.

## [1.0.0]

### Added

- The `exhaustive-deps` rule, React's rule reading `// exhaustive-deps-exclude [a, b]` comments as exemptions.
- `configs.recommended`, switching the upstream rule off and this one on.
