# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.1.0]

### Added

- A suggestion that writes the exclusion comment, offered beside the one that adds the name to the dependency array.
- `npm test` compiles the sources and runs the case suite.

### Changed

- The rule's documentation link points at this README.
  It carried the React issue the upstream rule links to.

### Removed

- The page describing what an exclusion reaches.
  A name is spelled the way the rule reports it, and the README states that in a line.

### Fixed

- The README configures the plugin under flat config.
  It carried an eslintrc block, which leaves the rule undefined because eslintrc cannot load an ESM-only plugin.

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
