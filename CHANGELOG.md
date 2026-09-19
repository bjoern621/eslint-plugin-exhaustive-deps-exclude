# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.2.0] - 2026-09-19

### Added

- A README badge naming the upstream commit the last sync run compared against and the day it ran.
  It reads `vendor/upstream-checked.json`, which the schedule commits, so a published page shows the last check rather than the state at publishing time.

### Changed

- The peer range accepts ESLint 8.57 and ESLint 10 beside ESLint 9.
- The engine range reaches down to Node 20.19 and stays open above Node 24.
  Both ranges are covered by the case suite, every ESLint major against every Node line.
- The README names every hook the rule reads, and the package description says what the rule does, where both spoke of `useEffect` alone.

## [2.1.0] - 2026-09-12

### Added

- A suggestion that writes the exclusion comment, offered beside the one that adds the name to the dependency array.

### Changed

- The documentation link an editor opens from a report points at this README.
  It carried the React issue the upstream rule links to.

### Fixed

- The README configures the plugin under flat config.
  It carried an eslintrc block, which leaves the rule undefined because eslintrc cannot load an ESM-only plugin.

## [2.0.0] - 2026-09-12

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

## [1.0.0] - 2025-10-22

### Added

- The `exhaustive-deps` rule, React's rule reading `// exhaustive-deps-exclude [a, b]` comments as exemptions.
- `configs.recommended`, switching the upstream rule off and this one on.

[unreleased]: https://github.com/bjoern621/eslint-plugin-exhaustive-deps-exclude/compare/v2.2.0...HEAD
[2.2.0]: https://github.com/bjoern621/eslint-plugin-exhaustive-deps-exclude/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/bjoern621/eslint-plugin-exhaustive-deps-exclude/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/bjoern621/eslint-plugin-exhaustive-deps-exclude/releases/tag/v2.0.0
[1.0.0]: https://www.npmjs.com/package/eslint-plugin-exhaustive-deps-exclude/v/1.0.0
